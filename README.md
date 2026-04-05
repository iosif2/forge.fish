<div align="center">

# forge.fish

Fish shell integration for the [`forgecode`](https://github.com/antinomyhq/forgecode) project's `forge` CLI.

> [!WARNING]
> This project is currently under active development. Commands, key bindings, and workflows may evolve.

A modern Fish plugin for running `forge` workflows directly from your command line with completions, inline `:` commands, and fast `@`-based file picking.

The completion support in this project is based on the `forgecode` project's Zsh completion and adapted for Fish.

</div>

## Highlights

| Capability | What it does |
| --- | --- |
| Command completions | Adds completions for the `forge` command inside Fish |
| Inline `:` workflows | Dispatches Forge actions directly from the Fish command line |
| `@` file picker | Opens a fuzzy file picker powered by `fzf` |
| Shell-friendly flows | Includes helpers for conversations, agents, commit/suggest flows, and workspace actions |
| Keyboard integration | Supports direct execution and picker-driven workflows with familiar keys |

## Requirements

For the full experience, have these tools available in your shell:

| Tool | Notes |
| --- | --- |
| `fish` | Required |
| `forge` | Required |
| `fzf` | Required for fuzzy picking |
| `fd` or `fdfind` | Recommended for `@` file picking |
| `bat` | Optional, for nicer previews |

## Install

Install with Fisher:

```fish
fisher install iosif2/forge.fish
```

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
