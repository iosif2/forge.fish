function _forge_command_info
    echo
    if test -n "$_FORGE_CONVERSATION_ID"
        _forge_run info --cid "$_FORGE_CONVERSATION_ID"
    else
        _forge_run info
    end
end
