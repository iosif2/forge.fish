function _forge_command_login
    set -l query "$argv[1]"

    echo

    set -l provider_row (_forge_provider_select '' '' '' "$query")
    if test -z "$provider_row"
        return 0
    end

    set -l provider_id (string split -f 2 -- (string split -r -m 2 '  +' -- (string trim -- "$provider_row")))
    _forge_run_interactive provider login "$provider_id"
end
