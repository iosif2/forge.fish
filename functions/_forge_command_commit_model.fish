function _forge_command_commit_model_config
    set -l output (_forge_run config get commit 2>/dev/null | string collect)
    set -l lines (string split \n -- "$output")
    printf '%s\n%s\n' "$lines[2]" "$lines[1]"
end

function _forge_command_commit_model
    set -l query "$argv[1]"

    echo

    set -l current (_forge_command_commit_model_config)
    set -l current_model "$current[1]"
    set -l current_provider "$current[2]"
    set -l selected_row (_forge_model_pick 'Commit Model > ' "$current_model" "$query" "$current_provider" 4)
    if test -z "$selected_row"
        return 0
    end

    _forge_run config set commit \
        (_forge_porcelain_find_index_field "$selected_row" 4) \
        (_forge_porcelain_find_index_field "$selected_row" 1)
end
