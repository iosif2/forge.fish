# Autoloadable conversation switch helper.
# Updates the previous conversation when switching to a new one.

function _forge_switch_conversation
    set -l new_conversation_id $argv[1]

    if test -n "$_FORGE_CONVERSATION_ID"; and test "$_FORGE_CONVERSATION_ID" != "$new_conversation_id"
        set -g _FORGE_PREVIOUS_CONVERSATION_ID "$_FORGE_CONVERSATION_ID"
    end

    set -g _FORGE_CONVERSATION_ID "$new_conversation_id"
end
