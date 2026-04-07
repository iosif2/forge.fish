function _forge_reader_reset
    switch "$_FORGE_OUTPUT_MODE"
        case visible
            if status --is-interactive; and test -w /dev/tty
                command printf '\r\n' >/dev/tty 2>/dev/null
            else
                command printf '\r\n'
            end

            set --erase _FORGE_OUTPUT_MODE
            commandline -r ''
            return 0
    end

    commandline -r ''
    commandline -f repaint
end
