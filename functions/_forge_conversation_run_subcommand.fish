function _forge_conversation_run_subcommand
    set -l subcommand $argv[1]
    set -l extra_args $argv[2..]

    echo

    if test -z "$_FORGE_CONVERSATION_ID"
        _forge_report error "No active conversation. Start a conversation first or use :conversation to see existing ones"
        return 0
    end

    _forge_run conversation "$subcommand" "$_FORGE_CONVERSATION_ID" $extra_args
end
