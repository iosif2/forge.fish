function _forge_reset
    if test "$_FORGE_OUTPUT_MODE" = visible
        if status --is-interactive; and test -w /dev/tty
            command printf '\r\n' >/dev/tty 2>/dev/null
        else
            command printf '\r\n'
        end

        set --erase _FORGE_OUTPUT_MODE
        commandline -r ""
        return 0
    end

    commandline -r ""
    commandline -f repaint
end
