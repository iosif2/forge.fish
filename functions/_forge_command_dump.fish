function _forge_command_dump
    set -l input_text ""
    if test (count $argv) -ge 1
        set input_text $argv[1]
    end

    if test "$input_text" = html
        _forge_conversation_run_subcommand dump --html
    else
        _forge_conversation_run_subcommand dump
    end
end
