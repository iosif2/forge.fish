function _forge_action_default
    set -l user_action $argv[1]
    set -l input_text ""
    if test (count $argv) -ge 2
        set input_text $argv[2]
    end
    set -l command_type ""

    # Named custom commands bypass agent switching and run through `forge cmd execute`.
    if test -n "$user_action"
        set -l commands_list (_forge_get_commands | string collect)
        if test -n "$commands_list"
            set -l command_row (echo "$commands_list" | grep "^$user_action\b")
            if test -z "$command_row"
                echo
                _forge_log error "Command '"(set_color --bold)"$user_action"(set_color normal)"' not found"
                return 0
            end

            set command_type (echo "$command_row" | awk '{print $2}')
            if test (string lower -- "$command_type") = custom
                if test -z "$_FORGE_CONVERSATION_ID"
                    set -l new_id ($_FORGE_BIN conversation new)
                    set -g _FORGE_CONVERSATION_ID "$new_id"
                end

                echo
                if test -n "$input_text"
                    _forge_exec cmd execute --cid "$_FORGE_CONVERSATION_ID" "$user_action" "$input_text"
                else
                    _forge_exec cmd execute --cid "$_FORGE_CONVERSATION_ID" "$user_action"
                end
                return 0
            end
        end
    end

    # With no prompt text, a valid AGENT command only changes shell-local active agent state.
    if test -z "$input_text"
        if test -n "$user_action"
            if test (string lower -- "$command_type") != agent
                echo
                _forge_log error "Command '"(set_color --bold)"$user_action"(set_color normal)"' not found"
                return 0
            end
            echo
            set -g _FORGE_ACTIVE_AGENT "$user_action"
            _forge_log info (set_color --bold white)(string upper -- "$_FORGE_ACTIVE_AGENT")(set_color normal)" "(set_color 888888)"is now the active agent"(set_color normal)
        end
        return 0
    end

    # Prompt text always goes through deferred execution so Fish redraws after Forge finishes.
    if test -z "$_FORGE_CONVERSATION_ID"
        set -l new_id ($_FORGE_BIN conversation new)
        set -g _FORGE_CONVERSATION_ID "$new_id"
    end

    if test -n "$user_action"
        set -g _FORGE_ACTIVE_AGENT "$user_action"
    end

    set -g _FORGE_PENDING_EXEC 1
    set -g -- _FORGE_PENDING_EXEC_ARGV -p $input_text --cid $_FORGE_CONVERSATION_ID
end
