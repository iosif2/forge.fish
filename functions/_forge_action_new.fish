# Action handler: Start a new conversation
# Port of _forge_action_new from shell-plugin/lib/actions/core.zsh
#
# Clears the current conversation, resets the active agent, and optionally
# starts a new conversation with the given input text.
#
# Usage: _forge_action_new [input_text]

function _forge_action_new
    set -l input_text ""
    if test (count $argv) -ge 1
        set input_text $argv[1]
    end

    # Clear conversation and save as previous (like cd -)
    _forge_clear_conversation
    set -g _FORGE_ACTIVE_AGENT forge

    # If input_text is provided, queue it for deferred execution
    if test -n "$input_text"
        # Generate new conversation ID and switch to it
        set -l new_id ($_FORGE_BIN conversation new)
        _forge_switch_conversation "$new_id"

        # Queue for _forge_deferred_exec (same mechanism as _forge_action_default)
        set -g _FORGE_PENDING_EXEC 1
        set -g -- _FORGE_PENDING_EXEC_ARGV -p $input_text --cid $_FORGE_CONVERSATION_ID
    else
        echo
        # Only show banner if no input text (starting fresh conversation)
        _forge_exec banner
    end
end
