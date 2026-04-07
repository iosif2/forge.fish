function _forge_command_suggest
    set -l description ""
    if test (count $argv) -ge 1
        set description $argv[1]
    end

    if test -z "$description"
        _forge_report error "Please provide a command description"
        return 0
    end

    echo

    set -lx FORCE_COLOR true
    set -lx CLICOLOR_FORCE 1
    set -l generated_command (_forge_run suggest "$description" | string collect)

    if test -n "$generated_command"
        commandline -r "$generated_command"
        commandline -f repaint
    else
        _forge_report error "Failed to generate command"
    end
end
