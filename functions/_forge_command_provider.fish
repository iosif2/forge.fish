function _forge_command_provider
    set -l query "$argv[1]"

    echo

    set -l provider_row (_forge_provider_select '' '' llm "$query")
    if test -z "$provider_row"
        return 0
    end

    _forge_run_interactive config set provider (_forge_provider_select_row_id "$provider_row")
end
