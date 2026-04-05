# Action handler: Select reasoning effort for the current session only.
# Port of _forge_action_reasoning_effort from zsh.
# Sets _FORGE_SESSION_REASONING_EFFORT for the current shell session without
# modifying global config.
# Usage: _forge_action_reasoning_effort [input_text]

function _forge_action_reasoning_effort
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

    set -l current_effort
    if test -n "$_FORGE_SESSION_REASONING_EFFORT"
        set current_effort "$_FORGE_SESSION_REASONING_EFFORT"
    else
        set current_effort ($_FORGE_BIN config get reasoning-effort 2>/dev/null | string collect)
    end

    set -l fzf_args --prompt="Reasoning Effort > "

    if test -n "$input_text"
        set -a fzf_args --query="$input_text"
    end

    if test -n "$current_effort"
        set -l index (_forge_find_index "$efforts" "$current_effort" 1)
        set -a fzf_args --bind="start:pos($index)"
    end

    set -l selected (printf '%s\n' "$efforts" | _forge_fzf --header-lines=1 $fzf_args | string collect)

    if test -n "$selected"
        set -g _FORGE_SESSION_REASONING_EFFORT "$selected"
        _forge_log success "Session reasoning effort set to "(set_color --bold)"$selected"(set_color normal)
    end
end
