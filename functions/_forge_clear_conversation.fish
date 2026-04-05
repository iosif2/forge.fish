# Autoloadable conversation state helper.
# Tracks the previous conversation and clears the active one.

function _forge_clear_conversation
    if test -n "$_FORGE_CONVERSATION_ID"
        set -g _FORGE_PREVIOUS_CONVERSATION_ID "$_FORGE_CONVERSATION_ID"
    end

    set -g _FORGE_CONVERSATION_ID ""
end
