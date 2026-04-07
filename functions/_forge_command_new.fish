function _forge_command_new_prepare
    _forge_conversation_clear
    set -g _FORGE_ACTIVE_AGENT forge
end

function _forge_command_new_queue_prompt --argument input_text
    set -l new_id ($_FORGE_BIN conversation new)
    _forge_conversation_switch "$new_id"
    set -g _FORGE_PENDING_EXEC 1
    set -g -- _FORGE_PENDING_EXEC_ARGV -p $input_text --cid $_FORGE_CONVERSATION_ID
end

function _forge_command_new
    set -l input_text "$argv[1]"

    _forge_command_new_prepare

    if test -n "$input_text"
        _forge_command_new_queue_prompt "$input_text"
        return 0
    end

    echo
    _forge_run banner
end
