import * as vscode from "vscode";
import { exec } from "child_process";
import { promisify } from "util";

const execAsync = promisify(exec);

const SESSION_NAME_RE = /^koh-(think|explode)-[0-9]+-[a-z0-9-]+$/;

interface KohSession {
  name: string;
  attached: boolean;
  created: string;
}

async function listKohSessions(): Promise<KohSession[]> {
  try {
    const { stdout } = await execAsync(
      'tmux list-sessions -F "#{session_name}|#{session_attached}|#{session_created}" 2>/dev/null'
    );

    return stdout
      .trim()
      .split("\n")
      .filter((line) => SESSION_NAME_RE.test(line.split("|")[0]))
      .map((line) => {
        const [name, attached, created] = line.split("|");
        return {
          name,
          attached: attached === "1",
          created: new Date(parseInt(created) * 1000).toLocaleString(),
        };
      });
  } catch {
    return [];
  }
}

function attachToSession(sessionName: string) {
  if (!SESSION_NAME_RE.test(sessionName)) {
    vscode.window.showErrorMessage(
      `Invalid koh session name: ${sessionName}`
    );
    return;
  }

  const terminal = vscode.window.createTerminal({
    name: sessionName,
    shellPath: process.env.SHELL,
    shellArgs: ["-c", `tmux attach-session -t "${sessionName}"`],
    location: vscode.TerminalLocation.Editor,
  });
  terminal.show();
}

export function activate(context: vscode.ExtensionContext) {
  // Track known sessions to detect new ones
  let knownSessions = new Set<string>();

  // Initialize known sessions
  listKohSessions().then((sessions) => {
    knownSessions = new Set(sessions.map((s) => s.name));
  });

  // Poll for new koh tmux sessions every 2 seconds
  const watcher = setInterval(async () => {
    const current = await listKohSessions();
    for (const session of current) {
      if (!knownSessions.has(session.name) && !session.attached) {
        knownSessions.add(session.name);
        const action = await vscode.window.showInformationMessage(
          `koh session detected: ${session.name}`,
          "Attach",
          "Ignore"
        );
        if (action === "Attach") {
          attachToSession(session.name);
        }
      }
    }
    // Update known set (remove gone sessions)
    knownSessions = new Set(current.map((s) => s.name));
  }, 2000);

  context.subscriptions.push({ dispose: () => clearInterval(watcher) });

  // Manual attach command
  const attach = vscode.commands.registerCommand("koh.attach", async () => {
    const sessions = await listKohSessions();

    if (sessions.length === 0) {
      vscode.window.showInformationMessage("No koh sessions running.");
      return;
    }

    const items = sessions.map((s) => ({
      label: s.name,
      description: s.attached ? "attached" : "",
      detail: `Created: ${s.created}`,
    }));

    const pick = await vscode.window.showQuickPick(items, {
      placeHolder: "Select a koh session to attach",
    });

    if (!pick) {
      return;
    }

    attachToSession(pick.label);
  });

  context.subscriptions.push(attach);
}

export function deactivate() {}
