import * as vscode from "vscode";
import { execSync } from "child_process";

interface KohSession {
  name: string;
  attached: boolean;
  created: string;
}

function listKohSessions(): KohSession[] {
  try {
    const output = execSync(
      'tmux list-sessions -F "#{session_name}|#{session_attached}|#{session_created}" 2>/dev/null',
      { encoding: "utf-8" }
    );

    return output
      .trim()
      .split("\n")
      .filter((line) => line.startsWith("koh-"))
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
  const terminal = vscode.window.createTerminal({
    name: sessionName,
    shellPath: process.env.SHELL,
    shellArgs: ["-c", `tmux attach-session -t "${sessionName}"`],
    location: { viewColumn: vscode.ViewColumn.Active },
  });
  terminal.show();
}

export function activate(context: vscode.ExtensionContext) {
  // Track known sessions to detect new ones
  let knownSessions = new Set(listKohSessions().map((s) => s.name));

  // Poll for new koh tmux sessions every 2 seconds
  const watcher = setInterval(() => {
    const current = listKohSessions();
    for (const session of current) {
      if (!knownSessions.has(session.name) && !session.attached) {
        knownSessions.add(session.name);
        attachToSession(session.name);
      }
    }
    // Update known set (remove gone sessions)
    knownSessions = new Set(current.map((s) => s.name));
  }, 2000);

  context.subscriptions.push({ dispose: () => clearInterval(watcher) });

  // Manual attach command
  const attach = vscode.commands.registerCommand("koh.attach", async () => {
    const sessions = listKohSessions();

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
