function _forge_action_commit_model
    set -l input_text $argv[1]

    echo
    set -l commit_output (_forge_exec config get commit 2>/dev/null | string collect)
    set -l current_commit_provider (echo "$commit_output" | head -n 1)
    set -l current_commit_model (echo "$commit_output" | tail -n 1)

    set -l selected (_forge_pick_model "Commit Model > " "$current_commit_model" "$input_text" "$current_commit_provider" 4)

    if test -n "$selected"
        set -l model_id (echo "$selected" | awk -F '  +' '{print $1}' | string trim)
        set -l provider_id (echo "$selected" | awk -F '  +' '{print $4}' | string trim)

        _forge_exec config set commit "$provider_id" "$model_id"
    end
end
