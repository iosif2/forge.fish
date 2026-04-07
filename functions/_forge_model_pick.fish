function _forge_model_pick_pick_args --argument prompt_text input_text current_model current_provider provider_field output
    set -l fzf_args \
        --delimiter="$_FORGE_DELIMITER" \
        --prompt="$prompt_text" \
        --with-nth='2,3,5..'

    if test -n "$input_text"
        set -a fzf_args --query="$input_text"
    end

    if test -n "$current_model"
        if test -n "$current_provider"; and test -n "$provider_field"
            set -l index (_forge_porcelain_find_index "$output" "$current_model" 1 "$provider_field" "$current_provider")
        else
            set -l index (_forge_porcelain_find_index "$output" "$current_model" 1)
        end
        set -a fzf_args --bind="start:pos($index)"
    end

    printf '%s\n' $fzf_args
end

function _forge_model_pick
    set -l prompt_text "$argv[1]"
    set -l current_model "$argv[2]"
    set -l input_text "$argv[3]"
    set -l current_provider "$argv[4]"
    set -l provider_field "$argv[5]"

    set -l output ($_FORGE_BIN list models --porcelain 2>/dev/null | string collect)
    if test -z "$output"
        return 1
    end

    set -l fzf_args (_forge_model_pick_pick_args "$prompt_text" "$input_text" "$current_model" "$current_provider" "$provider_field" "$output")
    printf '%s\n' "$output" | _forge_fzf --header-lines=1 $fzf_args
end
