#!/usr/bin/env -S deno run --allow-read --allow-write --allow-run --allow-env

/**
 * Syncs Claude Code's color theme with the GNOME color scheme preference.
 * Reads the current scheme on startup, then monitors for changes via the
 * freedesktop portal D-Bus interface.
 *
 * GNOME color-scheme values (org.freedesktop.appearance):
 *   0 = no preference (treat as light)
 *   1 = prefer-dark
 *   2 = prefer-light
 */

import { TextLineStream } from "jsr:@std/streams@^1/text-line-stream";

const SETTINGS_PATH = `${Deno.env.get("HOME")}/.claude/settings.json`;

function schemeToTheme(scheme: number): "dark" | "light" {
  return scheme === 1 ? "dark" : "light";
}

async function setClaudeTheme(theme: "dark" | "light"): Promise<void> {
  let settings: Record<string, unknown> = {};
  try {
    const content = await Deno.readTextFile(SETTINGS_PATH);
    settings = JSON.parse(content);
  } catch {
    // File missing or unreadable — start fresh
  }
  if (settings.theme === theme) return;
  settings.theme = theme;
  await Deno.writeTextFile(
    SETTINGS_PATH,
    JSON.stringify(settings, null, 2) + "\n",
  );
  console.log(`[claude-theme-sync] theme → ${theme}`);
}

async function readCurrentScheme(): Promise<number> {
  const { stdout } = await new Deno.Command("gdbus", {
    args: [
      "call",
      "--session",
      "--dest",
      "org.freedesktop.portal.Desktop",
      "--object-path",
      "/org/freedesktop/portal/desktop",
      "--method",
      "org.freedesktop.portal.Settings.Read",
      "org.freedesktop.appearance",
      "color-scheme",
    ],
    stdout: "piped",
    stderr: "null",
  }).output();
  const text = new TextDecoder().decode(stdout).trim();
  const m = text.match(/uint32 (\d+)/);
  return m ? Number(m[1]) : 0;
}

async function runMonitorCycle(): Promise<void> {
  // Sync current theme at the start of every cycle. This catches any change
  // that occurred while the monitor was down (e.g. during sleep/wake).
  await setClaudeTheme(schemeToTheme(await readCurrentScheme()));

  const proc = new Deno.Command("gdbus", {
    args: [
      "monitor",
      "--session",
      "--dest",
      "org.freedesktop.portal.Desktop",
      "--object-path",
      "/org/freedesktop/portal/desktop",
    ],
    stdout: "piped",
    stderr: "null",
  }).spawn();

  const lines = proc.stdout
    .pipeThrough(new TextDecoderStream())
    .pipeThrough(new TextLineStream());

  for await (const line of lines) {
    // Signal format:
    // /org/freedesktop/portal/desktop: org.freedesktop.portal.Settings.SettingChanged
    //   ('org.freedesktop.appearance', 'color-scheme', <uint32 1>)
    if (
      line.includes("SettingChanged") &&
      line.includes("org.freedesktop.appearance") &&
      line.includes("color-scheme")
    ) {
      const m = line.match(/uint32 (\d+)/);
      if (m) await setClaudeTheme(schemeToTheme(Number(m[1])));
    }
  }

  // gdbus monitor exited — D-Bus likely disconnected (sleep/wake transition).
  console.log("[claude-theme-sync] monitor exited, restarting");
}

// Retry loop: restart the full cycle whenever the monitor exits.
// On wake from sleep, gdbus monitor loses its connection and exits, which
// causes a restart here — re-reading the current scheme before re-subscribing.
while (true) {
  try {
    await runMonitorCycle();
  } catch (err) {
    console.error("[claude-theme-sync] error:", err);
  }
  // Brief pause to avoid a tight loop if D-Bus is temporarily unavailable.
  await new Promise((resolve) => setTimeout(resolve, 2000));
}
