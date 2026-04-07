function _forge_dispatch_default_command_name --argument command_row
    set -l match (string match -r '^([^[:space:]]+)' -- (string trim -- "$command_row"))
    if test (count $match) -ge 2
        printf '%s\n' "$match[2]"
    end
end

function _forge_dispatch_default_command_row --argument user_action commands_output
    if test -z "$user_action"; or test -z "$commands_output"
        return 1
    end

    for row in (string split \n -- "$commands_output")
        if test (_forge_dispatch_default_command_name "$row") = "$user_action"
            printf '%s\n' "$row"
            return 0
        end
    end

    return 1
end

function _forge_dispatch_default_command_type --argument command_row
    set -l match (string match -r '^[^[:space:]]+[[:space:]]+([^[:space:]]+)' -- (string trim -- "$command_row"))
    if test (count $match) -ge 2
        printf '%s\n' "$match[2]"
    end
end

function _forge_dispatch_default_fail_unknown --argument user_action
    echo
    _forge_report error "Command '"(set_color --bold)"$user_action"(set_color normal)"' not found"
end

function _forge_dispatch_default_is_custom --argument command_type
    test (string lower -- "$command_type") = custom
end

function _forge_dispatch_default_is_agent --argument command_type
    test (string lower -- "$command_type") = agent
end

function _forge_dispatch_default_ensure_conversation
    if test -n "$_FORGE_CONVERSATION_ID"
        return 0
    end

    set -l new_id ($_FORGE_BIN conversation new)
    set -g _FORGE_CONVERSATION_ID "$new_id"
end

function _forge_dispatch_default_run_custom --argument user_action input_text
    _forge_dispatch_default_ensure_conversation

    echo
    if test -n "$input_text"
        _forge_run cmd execute --cid "$_FORGE_CONVERSATION_ID" "$user_action" "$input_text"
    else
        _forge_run cmd execute --cid "$_FORGE_CONVERSATION_ID" "$user_action"
    end
end

function _forge_dispatch_default_activate_agent --argument user_action
    echo
    set -g _FORGE_ACTIVE_AGENT "$user_action"
    _forge_report info (set_color --bold white)(string upper -- "$_FORGE_ACTIVE_AGENT")(set_color normal)" "(set_color 888888)"is now the active agent"(set_color normal)
end

function _forge_dispatch_default_queue_prompt --argument user_action input_text
    _forge_dispatch_default_ensure_conversation

    if test -n "$user_action"
        set -g _FORGE_ACTIVE_AGENT "$user_action"
    end

    set -g _FORGE_PENDING_EXEC 1
    set -g -- _FORGE_PENDING_EXEC_ARGV -p $input_text --cid $_FORGE_CONVERSATION_ID
end

function _forge_dispatch_default
    set -l user_action "$argv[1]"
    set -l input_text "$argv[2]"
    set -l commands_output ''
    set -l command_row ''
    set -l command_type ''

    if test -n "$user_action"
        set commands_output (_forge_commands_get | string collect)
        set command_row (_forge_dispatch_default_command_row "$user_action" "$commands_output")
        if test -z "$command_row"
            _forge_dispatch_default_fail_unknown "$user_action"
            return 0
        end

        set command_type (_forge_dispatch_default_command_type "$command_row")
        if _forge_dispatch_default_is_custom "$command_type"
            _forge_dispatch_default_run_custom "$user_action" "$input_text"
            return 0
        end
    end

    if test -z "$input_text"
        if test -n "$user_action"
            if not _forge_dispatch_default_is_agent "$command_type"
                _forge_dispatch_default_fail_unknown "$user_action"
                return 0
            end

            _forge_dispatch_default_activate_agent "$user_action"
        end
        return 0
    end

    _forge_dispatch_default_queue_prompt "$user_action" "$input_text"
end
