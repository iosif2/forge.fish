function _forge_command_copy_clipboard
    if command -q pbcopy
        cat | pbcopy
        return 0
    end
    if command -q xclip
        cat | xclip -selection clipboard
        return 0
    end
    if command -q xsel
        cat | xsel --clipboard --input
        return 0
    end
    return 1
end

function _forge_command_copy
    echo

    if test -z "$_FORGE_CONVERSATION_ID"
        _forge_report error 'No active conversation. Start a conversation first or use :conversation to see existing ones'
        return 0
    end

    set -l content ($_FORGE_BIN conversation show --md "$_FORGE_CONVERSATION_ID" 2>/dev/null | string collect)
    if test -z "$content"
        _forge_report error 'No assistant message found in the current conversation'
        return 0
    end

    printf '%s' "$content" | _forge_command_copy_clipboard
    or begin
        _forge_report error 'No clipboard utility found (pbcopy, xclip, or xsel required)'
        return 0
    end

    set -l line_count (string split \n -- "$content" | count)
    set -l byte_count (printf '%s' "$content" | wc -c | string trim)
    _forge_report success "Copied to clipboard "(set_color 888888)"[$line_count lines, $byte_count bytes]"(set_color normal)
end
