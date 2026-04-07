function _forge_command_session_model_selected_field --argument row field_number
    _forge_porcelain_find_index_field "$row" "$field_number"
end

function _forge_command_session_model_current
    set -l current_model "$_FORGE_SESSION_MODEL"
    set -l current_provider "$_FORGE_SESSION_PROVIDER"
    set -l provider_field 4

    if test -z "$current_model"
        set current_model ($_FORGE_BIN config get model 2>/dev/null | string collect)
        set provider_field 3
    end

    if test -z "$current_provider"
        set current_provider ($_FORGE_BIN config get provider 2>/dev/null | string collect)
        set provider_field 3
    end

    printf '%s\n%s\n%s\n' "$current_model" "$current_provider" "$provider_field"
end

function _forge_command_session_model
    set -l query "$argv[1]"

    echo

    set -l current (_forge_command_session_model_current)
    set -l current_model "$current[1]"
    set -l current_provider "$current[2]"
    set -l provider_field "$current[3]"

    set -l selected_row (_forge_model_pick 'Session Model > ' "$current_model" "$query" "$current_provider" "$provider_field")
    if test -z "$selected_row"
        return 0
    end

    set -g _FORGE_SESSION_MODEL (_forge_command_session_model_selected_field "$selected_row" 1)
    set -g _FORGE_SESSION_PROVIDER (_forge_command_session_model_selected_field "$selected_row" 4)

    _forge_report success "Session model set to "(set_color --bold)"$_FORGE_SESSION_MODEL"(set_color normal)" (provider: "(set_color --bold)"$_FORGE_SESSION_PROVIDER"(set_color normal)")"
end
