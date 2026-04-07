function _forge_command_login
    set -l input_text $argv[1]
    echo
    set -l selected (_forge_provider_select "" "" "" "$input_text")
    if test -n "$selected"
        set -l provider (echo "$selected" | awk '{print $2}')
        _forge_run_interactive provider login "$provider"
    end
end
