function _forge_action_new
    set -l input_text ""
    if test (count $argv) -ge 1
        set input_text $argv[1]
    end

    # Preserve the old conversation as "previous" before starting fresh.
    _forge_clear_conversation
    set -g _FORGE_ACTIVE_AGENT forge

    if test -n "$input_text"
        # `:new some text` creates the new conversation now, then lets deferred exec send the prompt.
        set -l new_id ($_FORGE_BIN conversation new)
        _forge_switch_conversation "$new_id"

        set -g _FORGE_PENDING_EXEC 1
        set -g -- _FORGE_PENDING_EXEC_ARGV -p $input_text --cid $_FORGE_CONVERSATION_ID
    else
        echo
        _forge_exec banner
    end
end
