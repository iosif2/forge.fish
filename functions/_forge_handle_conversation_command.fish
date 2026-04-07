function _forge_handle_conversation_command
    set -l subcommand $argv[1]
    set -l extra_args $argv[2..]

    echo

    if test -z "$_FORGE_CONVERSATION_ID"
        _forge_log error "No active conversation. Start a conversation first or use :conversation to see existing ones"
        return 0
    end

    _forge_exec conversation "$subcommand" "$_FORGE_CONVERSATION_ID" $extra_args
end
