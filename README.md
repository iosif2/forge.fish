<div align="center">

# forge.fish

**Turn Forge into a shell-native workflow for Fish.**

Use prompt-native `:` commands, fuzzy `@` file picking, and direct keyboard-driven execution without falling back to a separate TUI or memorizing a pile of subcommands.

[![forge.fish demo GIF](./assets/forge-fish-demo.gif)](./assets/forge-fish-demo.cast)

[Install in 30 seconds](#30-second-install) • [Supported versions](#supported-versions) • [Known limitations](#known-limitations)

</div>

> [!WARNING]
> This project is under active development. The Fish integration tracks Forge's shell workflow closely, but commands and UX details can continue to evolve.

## The problem this plugin solves

The `forge` CLI is powerful, but plain Fish still leaves a lot of shell friction in the loop:

- you have to remember or rediscover Forge subcommands
- switching between agents and workflows is not built into your prompt
- attaching files from the current workspace is slower than it should be
- Fish users do not get the same shell-native workflow that the upstream Zsh integration already has

**forge.fish** fixes that by bringing the Forge workflow directly into Fish:

- press <kbd>Tab</kbd> after `:` to browse Forge commands in `fzf`
- press <kbd>Tab</kbd> after `@` to fuzzy-pick files and directories into the prompt
- press <kbd>Enter</kbd> on a Forge `:` command to run it from the command line
- keep working in the same shell session instead of bouncing between tools

## 30-second install

Prerequisites:

- required: `fish`, `forge`, `fzf`
- recommended: `fd` or `fdfind`
- optional: `bat`

If you already use Fisher:

```fish
fisher install iosif2/forge.fish
exec fish
```

If you do not have Fisher yet:

```fish
curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
fisher install iosif2/forge.fish
exec fish
```

## Supported versions

This repository currently documents a **verified baseline** plus the **minimum tool versions enforced by `:doctor`**:

| Component | Verified in this repo | Minimum / note |
| --- | --- | --- |
| Fish | `4.5.0` | Verified baseline for this README/demo |
| Forge CLI | `2.6.0` | Verified baseline for this README/demo |
| `fzf` | `0.70.0` | `0.36.0+` required for interactive features |
| `fd` / `fdfind` | `10.4.2` | `10.0.0+` recommended for file discovery |
| `bat` | `0.26.1` | Optional, but `0.20.0+` expected for rich previews |

If you are outside this baseline, the plugin may still work, but this repo does not maintain a broader compatibility matrix yet.

## Known limitations

- Key bindings are installed only in **interactive Fish sessions**. Scripted runs like `fish -c ...` will not get the `Tab` and `Enter` integration.
- Interactive Forge execution depends on a writable **TTY**. In headless or non-TTY environments, non-interactive flows work better than full prompt-driven sessions.
- The `@` picker is best with `fzf` plus `fd`/`fdfind`. Without those tools, file-picking is limited or unavailable.
- `bat` is optional. If it is missing, previews fall back to plain `cat` output.

## What you get

| Capability | What it does |
| --- | --- |
| `:command` picker | Browse Forge commands with `fzf` directly from Fish |
| `@` file picker | Insert `@[path]` references from the current workspace |
| Inline prompt workflows | Run `:new`, `:suggest`, `:doctor`, `:conversation`, and more from the prompt |
| Agent switching | Move between agent flows without leaving the shell |
| Prompt integration | Keep Forge-aware state in your active Fish session |

## Quick start

After installation, open a new interactive Fish session and try:

| Command | Purpose |
| --- | --- |
| `:new` | Start a new conversation |
| `:conversation` | Switch conversations |
| `:commit` | Generate a commit message workflow |
| `:commit-preview` | Preview commit message output |
| `:suggest` | Turn natural language into a shell command |
| `:doctor` | Inspect your shell setup |
| `: <prompt>` | Send a prompt to the active agent |

## Key interactions

| Shortcut | Behavior |
| --- | --- |
| <kbd>Tab</kbd> after `:` | Opens the Forge command picker |
| <kbd>Tab</kbd> after `@` | Opens the file picker |
| <kbd>Enter</kbd> on a Forge `:` command | Runs it directly from the command line |

## Test

```bash
just test
```
