# Action handler: Set reasoning effort in global config.
# Port of _forge_action_config_reasoning_effort from zsh.
# Calls `forge config set reasoning-effort <effort>` on selection.
# Usage: _forge_action_config_reasoning_effort [input_text]

function _forge_action_config_reasoning_effort
    set -l input_text $argv[1]
    echo

    set -l efforts 'EFFORT
none
minimal
low
medium
high
xhigh
max'
    set -l current_effort ($_FORGE_BIN config get reasoning-effort 2>/dev/null | string collect)

    set -l fzf_args --prompt="Config Reasoning Effort > "

    if test -n "$input_text"
        set -a fzf_args --query="$input_text"
    end

    if test -n "$current_effort"
        set -l index (_forge_find_index "$efforts" "$current_effort" 1)
        set -a fzf_args --bind="start:pos($index)"
    end

    set -l selected (printf '%s\n' "$efforts" | _forge_fzf --header-lines=1 $fzf_args | string collect)

    if test -n "$selected"
        _forge_exec config set reasoning-effort "$selected"
    end
end
