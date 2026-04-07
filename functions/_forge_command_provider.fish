function _forge_command_provider
    set -l input_text $argv[1]
    echo
    set -l selected (_forge_provider_select "" "" "llm" "$input_text")

    if test -n "$selected"
        set -l provider_id (echo "$selected" | awk '{print $2}')
        _forge_run_interactive config set provider "$provider_id"
    end
end
