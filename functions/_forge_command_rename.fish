function _forge_command_rename
    set -l input_text "$argv[1]"

    echo

    if test -z "$_FORGE_CONVERSATION_ID"
        _forge_report error 'No active conversation. Start a conversation first or use :conversation to select one'
        return 0
    end

    if test -z "$input_text"
        _forge_report error 'Usage: :rename <name>'
        return 0
    end

    _forge_run conversation rename "$_FORGE_CONVERSATION_ID" "$input_text"
end
