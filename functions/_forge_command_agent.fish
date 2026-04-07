function _forge_command_agent_list
    $_FORGE_BIN list agents --porcelain 2>/dev/null | string collect
end

function _forge_command_agent_row_id --argument row
    printf '%s\n' (string split -m 1 ' ' -- (string trim -- "$row"))[1]
end

function _forge_command_agent_activate --argument agent_id
    set -g _FORGE_ACTIVE_AGENT "$agent_id"
    _forge_report success "Switched to agent "(set_color --bold)"$agent_id"(set_color normal)
end

function _forge_command_agent_find_row --argument agents_output expected_id
    set -l line_number 0

    for row in (string split \n -- "$agents_output")
        set line_number (math $line_number + 1)
        if test $line_number -eq 1
            continue
        end

        if test (_forge_command_agent_row_id "$row") = "$expected_id"
            printf '%s\n' "$row"
            return 0
        end
    end

    return 1
end

function _forge_command_agent_pick_row --argument agents_output current_agent
    set -l fzf_args \
        '--prompt=Agent > ' \
        --delimiter="$_FORGE_DELIMITER" \
        --with-nth='1,2,4,5,6'

    if test -n "$current_agent"
        set -l index (_forge_porcelain_find_index "$agents_output" "$current_agent")
        set -a fzf_args --bind="start:pos($index)"
    end

    printf '%s\n' "$agents_output" | _forge_fzf --header-lines=1 $fzf_args
end

function _forge_command_agent
    set -l query "$argv[1]"

    echo

    set -l agents_output (_forge_command_agent_list)
    if test -z "$agents_output"
        _forge_report error 'No agents found'
        return 0
    end

    if test -n "$query"
        if not _forge_command_agent_find_row "$agents_output" "$query" >/dev/null
            _forge_report error "Agent '"(set_color --bold)"$query"(set_color normal)"' not found"
            return 0
        end

        _forge_command_agent_activate "$query"
        return 0
    end

    set -l selected_row (_forge_command_agent_pick_row "$agents_output" "$_FORGE_ACTIVE_AGENT")
    if test -z "$selected_row"
        return 0
    end

    _forge_command_agent_activate (_forge_command_agent_row_id "$selected_row")
end
