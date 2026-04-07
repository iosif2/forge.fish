function _forge_command_model_selected_field --argument row field_number
    _forge_porcelain_find_index_field "$row" "$field_number"
end

function _forge_command_model
    set -l query "$argv[1]"

    echo

    set -l current_model ($_FORGE_BIN config get model 2>/dev/null | string collect)
    set -l current_provider ($_FORGE_BIN config get provider 2>/dev/null | string collect)
    set -l selected_row (_forge_model_pick 'Model > ' "$current_model" "$query" "$current_provider" 3)
    if test -z "$selected_row"
        return 0
    end

    set -l model_id (_forge_command_model_selected_field "$selected_row" 1)
    set -l provider_display (_forge_command_model_selected_field "$selected_row" 3)
    set -l provider_id (_forge_command_model_selected_field "$selected_row" 4)

    if test -n "$provider_display"; and test "$provider_display" != "$current_provider"
        _forge_run_interactive config set provider "$provider_id" --model "$model_id"
        return 0
    end

    _forge_run config set model "$model_id"
end
