# Clear the command line buffer and reset the reader after Forge actions.
# For actions that produced visible output, only emit a single CRLF separator
# and let Fish draw the next prompt naturally. This avoids both overwriting the
# final Forge line and inserting extra blank prompt-height padding rows.
# Usage: _forge_reset

function _forge_reset
    if test "$_FORGE_POST_INTERACTIVE_NEWLINE" = 1; or test "$_FORGE_POST_OUTPUT_PADDING" = 1
        if status --is-interactive; and test -w /dev/tty
            command printf '\r\n' >/dev/tty 2>/dev/null
        else
            command printf '\r\n'
        end

        set --erase _FORGE_POST_INTERACTIVE_NEWLINE
        set --erase _FORGE_POST_OUTPUT_PADDING
        commandline -r ""
        return 0
    end

    commandline -r ""
    commandline -f repaint
end

