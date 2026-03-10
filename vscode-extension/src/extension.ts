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

export function activate(context: vscode.ExtensionContext) {
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

    const terminal = vscode.window.createTerminal({
      name: pick.label,
      shellPath: "/bin/bash",
      shellArgs: ["-c", `tmux attach-session -t "${pick.label}"`],
    });

    terminal.show();
  });

  context.subscriptions.push(attach);
}

export function deactivate() {}
