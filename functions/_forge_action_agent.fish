function _forge_action_agent
    set -l input_text $argv[1]

    echo

    if test -n "$input_text"
        set -l agent_id "$input_text"

        set -l agent_exists (
            $_FORGE_BIN list agents --porcelain 2>/dev/null \
            | tail -n +2 \
            | string match -rq "^$agent_id\\b" \
            && echo true; or echo false
        )
        if test "$agent_exists" = false
            _forge_log error "Agent '"(set_color --bold)"$agent_id"(set_color normal)"' not found"
            return 0
        end

        set -g _FORGE_ACTIVE_AGENT "$agent_id"

        _forge_log success "Switched to agent "(set_color --bold)"$agent_id"(set_color normal)

        return 0
    end

    set -l agents_output ($_FORGE_BIN list agents --porcelain 2>/dev/null | string collect)

    if test -n "$agents_output"
        set -l current_agent "$_FORGE_ACTIVE_AGENT"

        set -l sorted_agents "$agents_output"

        set -l prompt_text "Agent > "
        set -l fzf_args \
            --prompt="$prompt_text" \
            --delimiter="$_FORGE_DELIMITER" \
            --with-nth="1,2,4,5,6"

        if test -n "$current_agent"
            set -l index (_forge_find_index "$sorted_agents" "$current_agent")
            set fzf_args $fzf_args --bind="start:pos($index)"
        end

        set -l selected_agent (echo "$sorted_agents" | _forge_fzf --header-lines=1 $fzf_args)

        if test -n "$selected_agent"
            set -l agent_id (echo "$selected_agent" | awk '{print $1}')

            set -g _FORGE_ACTIVE_AGENT "$agent_id"

            _forge_log success "Switched to agent "(set_color --bold)"$agent_id"(set_color normal)
        end
    else
        _forge_log error "No agents found"
    end
end
