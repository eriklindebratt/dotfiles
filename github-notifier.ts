#!/usr/bin/env -S deno run --allow-net=api.github.com --allow-env --allow-run --allow-read --allow-write
// github-notifier.ts

/**
 * Deno GitHub Notifier
 * - Polls GitHub notifications every 5 minutes
 * - Sends macOS notifications (clickable) via terminal-notifier
 * - Tracks seen notifications locally (~/.gh_seen.json)
 *
 * To start in tmux:
 *   tmux new-session -d -s gh-notifier '~/dev/dotfiles/github-notifier.ts'
 */

const TMUX_SESSION_NAME = "gh-notifier";

async function isFocusedTmuxSession() {
  const { stdout } = await new Deno.Command("tmux", {
    args: [
      "list-clients",
      "-F",
      '"#{client_tty}:#{session_name}:#{client_flags}"',
    ],
    stdout: "piped",
  }).output();

  return new TextDecoder().decode(stdout).trim()
    .split(
      "\n",
    ).some((i) =>
      i.includes(TMUX_SESSION_NAME) &&
      (i.includes("focused") || i.includes("active"))
    );
}

async function showError(message: string, isFatalError?: boolean) {
  console.error(message);

  if (isFatalError) {
    // show the error message in the currently focused tmux session
    await showErrorInTmux(
      `\\e[2m${message}\\e[0m${
        !await isFocusedTmuxSession()
          ? `\n\n👉 Press any key to switch to \\"${TMUX_SESSION_NAME}\\" tmux session.`
          : `\n\nPress any key to exit.`
      }`,
      true,
    );

    if (!await isFocusedTmuxSession()) {
      // attempt to switch to this process' tmux sesssion so we can see what's going on
      if (Deno.env.has("TMUX")) {
        await new Deno.Command("tmux", {
          args: [
            "switch-client",
            "-t",
            TMUX_SESSION_NAME,
          ],
        }).output();
      } else {
        await new Deno.Command("tmux", {
          args: [
            "attach-session",
            "-t",
            TMUX_SESSION_NAME,
          ],
        }).output();
      }

      if (message) {
        // show the error in tmux again (preventing the session from exiting until a key is pressed), this time with this process' session focused
        await showErrorInTmux(
          `\\e[2m${message}\\e[0m\n\nPress any key to exit.`,
          true,
        );
      }
    }
  } else {
    await showErrorInTmux(
      `\\e[2m${message}\\e[0m\n\nPress any key to close.`,
      false,
    );
  }
}

function showErrorInTmux(message: string, isFatalError?: boolean) {
  return new Deno.Command("tmux", {
    args: [
      "display-popup",
      "-E",
      `echo "⚠️ \\\`github-notifier\\\` caught ${
        isFatalError ? "a fatal error and will exit." : "an error."
      }\n\n${message.replace(/`/g, "\\`")}" && read`,
    ],
  }).output();
}

function showMessageInTmux(message: string) {
  return new Deno.Command("tmux", {
    args: [
      "display-popup",
      "-E",
      `echo "\\e[2m👋 \\\`github-notifier\\\`\\e[0m\n\n${
        message.replace(/`/g, "\\`")
      }\n\n\\e[2mPress any key to close.\\e[0m" && read`,
    ],
  }).output();
}

async function onFatalError(message?: string) {
  if (message) {
    await showError(message, true);
  }

  Deno.exit(1);
}

async function notify(title: string, message: string, url?: string) {
  const args = ["-title", title, "-message", message];
  if (url) args.push("-open", url);

  try {
    const { success, stderr } = await new Deno.Command("terminal-notifier", {
      args,
    }).output();
    if (!success) {
      const errMsg = new TextDecoder().decode(stderr);
      await onFatalError(`\`terminal-notifier\` failed: ${errMsg}`);
    }
  } catch (err) {
    await onFatalError(`Failed to run \`terminal-notifier\`: ${err}`);
  }
}

const seenFile = `${Deno.env.get("HOME")}/.gh_seen.json`;
let seen: Set<string> = new Set();

try {
  const raw = await Deno.readTextFile(seenFile);
  seen = new Set(JSON.parse(raw));
} catch {
  // file doesn't exist yet
}

async function saveSeen() {
  await Deno.writeTextFile(seenFile, JSON.stringify([...seen], null, 2));

  if (seen.size > 500) {
    await showError(
      `${
        seenFile.replace(Deno.env.get("HOME")!, "~")
      } contains over 500 entries, consider trimming or removing it.`,
    );
  }
}

async function fetchNotifications() {
  try {
    const resp = await fetch("https://api.github.com/notifications", {
      headers: {
        Authorization: `token ${GITHUB_TOKEN}`,
        Accept: "application/vnd.github+json",
      },
    });
    if (!resp.ok) {
      await showError(
        `Failed to fetch notifications: ${resp.status} ${await resp.text()}`,
      );
      return [];
    }
    return await resp.json();
  } catch (err) {
    showError(`Error fetching notifications: ${err}`);

    return [];
  }
}

async function fetchGithubApiUrl(apiUrl: string) {
  const resp = await fetch(
    apiUrl.replace(new URL(apiUrl).origin, "https://api.github.com"),
    {
      headers: {
        Authorization: `token ${GITHUB_TOKEN}`,
        Accept: "application/vnd.github+json",
      },
    },
  );
  return resp.json();
}

async function poll() {
  try {
    console.log(`${new Date().toISOString()} Polling GitHub notifications...`);
    const notifications = await fetchNotifications();
    console.log(" - Got %d notification(s)", notifications.length);

    for (const n of notifications) {
      if (!seen.has(n.id)) {
        const repo: string = n.repository.full_name;
        const reason: NotificationReason = n.reason;
        const reasonFormatted = reason
          .replace(/_/g, " ")
          .replace(
            /\w\S*/g,
            (txt) => txt[0].toUpperCase() + txt.slice(1).toLowerCase(), // title case
          )
          .replace(/ci /gi, "CI ");
        const title = `${reasonFormatted} • ${repo}`;
        const message: string = n.subject.title;
        const type: string = n.subject.type.toLowerCase() === "pullrequest"
          ? "PR"
          : n.subject.type.toLowerCase();

        // Convert API URL to web URL
        let htmlUrl: string | undefined = n.subject.url;
        if (htmlUrl?.startsWith("https://api.github.com/repos/")) {
          htmlUrl = htmlUrl
            .replace("https://api.github.com/repos/", "https://github.com/")
            .replace("/pulls/", "/pull/")
            .replace("/issues/", "/issues/");
        }

        await notify(title, message, htmlUrl);

        let tmuxMessage = "";
        switch (reason) {
          case "author":
            tmuxMessage = `New activity on your authored ${type} on GitHub.`;
            break;
          case "assign":
            tmuxMessage =
              `New activity on a ${type} you're assigned to on GitHub.`;
            break;
          case "comment":
            tmuxMessage =
              `New activity on a ${type} you've commented on on GitHub.`;
            break;
          case "mention":
            tmuxMessage =
              `New activity in a ${type} you were mentioned on on GitHub.`;
            break;
          // case "review_requested":
          //   tmuxMessage =
          //     `New activity in a ${type} you've been requested to review on GitHub.`;
          //   break;
          case "security_alert":
            tmuxMessage = `New security alert in ${repo} on GitHub.`;
            break;
          case "team_mention":
            tmuxMessage =
              `New activity in a ${type} your team was mentioned on on GitHub.`;
            break;
        }
        if (tmuxMessage) {
          await showMessageInTmux(
            `\\e[1m${tmuxMessage}\\e[0m\\e[2m\n\nSee more:\n${
              type === "PR"
                // fetch PR metadata and show parts of it
                ? await fetchGithubApiUrl(n.subject.url).then((i) =>
                  `• ${repo}#${i.number}\n• ${i.title}`
                )
                : ""
            }${htmlUrl ? `\n• ${htmlUrl}` : ""}\\e[0m`,
          );
        }

        seen.add(n.id);
      }
    }

    await saveSeen();
  } catch (err) {
    showError(`Poll loop error: ${err}`);
  }
}

if (!await isFocusedTmuxSession()) {
  console.log("Start in a separate, named, tmux session:");
  console.log(
    `$ tmux new-session -s ${TMUX_SESSION_NAME} '<path-to-script>'`,
  );
  Deno.exit(1);
}

/**
 * NOTE: In order to work with `tmux new-session` this variable needs
 * to be set in one of
 * - `~/.zprofile` (evaluated for zsh login shells) – or –
 * - `~/.zshenv` (evaluated for every zsh shell, even non-interactive)
 *
 * `~/.zshrc` is only evaluated for interactive shells.
 */
const GITHUB_TOKEN = Deno.env.get("GITHUB_NOTIFICATIONS_CHECKER_TOKEN");
if (!GITHUB_TOKEN) {
  await onFatalError(
    "Missing environment variable `GITHUB_NOTIFICATIONS_CHECKER_TOKEN`.",
  );
}

console.log("GitHub notifier started. Logging notifications...");

// Initial poll
await poll();

// Poll every 5 minutes
setInterval(poll, 5 * 60 * 1000);

/*********************************************************/

type NotificationReason =
  | "approval_requested"
  | "assign"
  | "author"
  | "ci_activity"
  | "comment"
  | "invitation"
  | "manual"
  | "member_feature_requested"
  | "mention"
  | "review_requested"
  | "security_advisory_credit"
  | "security_alert"
  | "state_change"
  | "subscribed"
  | "team_mention";
