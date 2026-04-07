function _forge_command_config_reasoning_effort_options
    printf '%s\n' EFFORT none minimal low medium high xhigh max
end

function _forge_command_config_reasoning_effort
    set -l query "$argv[1]"

    echo

    set -l current_effort ($_FORGE_BIN config get reasoning-effort 2>/dev/null | string collect)
    set -l fzf_args '--prompt=Config Reasoning Effort > '

    if test -n "$query"
        set -a fzf_args --query="$query"
    end

    if test -n "$current_effort"
        set -l index (_forge_porcelain_find_index (_forge_command_config_reasoning_effort_options | string collect) "$current_effort" 1)
        set -a fzf_args --bind="start:pos($index)"
    end

    set -l selected (_forge_command_config_reasoning_effort_options | _forge_fzf --header-lines=1 $fzf_args | string collect)
    if test -n "$selected"
        _forge_run config set reasoning-effort "$selected"
    end
end
