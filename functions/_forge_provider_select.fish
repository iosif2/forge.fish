function _forge_provider_select_row_id --argument row
    set -l columns (string split '\t' -- (string replace -ra '  +' '\t' -- (string trim -- "$row")))
    if test (count $columns) -ge 2
        printf '%s\n' "$columns[2]"
    end
end

function _forge_provider_select_list --argument filter_type
    set -l command $_FORGE_BIN list provider --porcelain
    if test -n "$filter_type"
        set -a command --type="$filter_type"
    end

    $command 2>/dev/null | string collect
end

function _forge_provider_select_filter_status --argument output filter_status
    if test -z "$filter_status"
        printf '%s\n' "$output"
        return 0
    end

    set -l lines (string split \n -- "$output")
    set -l header "$lines[1]"
    set -l body "$lines[2..]"
    set -l filtered (printf '%s\n' $body | string match -r -- "$filter_status" | string collect)
    if test -z "$filtered"
        return 1
    end

    printf '%s\n%s\n' "$header" "$filtered"
end

function _forge_provider_select
    set -l filter_status "$argv[1]"
    set -l current_provider "$argv[2]"
    set -l filter_type "$argv[3]"
    set -l query "$argv[4]"

    set -l output (_forge_provider_select_list "$filter_type")
    if test -z "$output"
        _forge_report error 'No providers available'
        return 1
    end

    set -l filtered_output (_forge_provider_select_filter_status "$output" "$filter_status")
    if test $status -ne 0
        _forge_report error "No $filter_status providers found"
        return 1
    end
    set output "$filtered_output"

    if test -z "$current_provider"
        set current_provider ($_FORGE_BIN config get provider --porcelain 2>/dev/null | string collect)
    end

    set -l fzf_args \
        --delimiter="$_FORGE_DELIMITER" \
        '--prompt=Provider > ' \
        --with-nth='1,3..'

    if test -n "$query"
        set -a fzf_args --query="$query"
    end

    if test -n "$current_provider"
        set -l index (_forge_porcelain_find_index "$output" "$current_provider" 1)
        set -a fzf_args --bind="start:pos($index)"
    end

    printf '%s\n' "$output" | _forge_fzf --header-lines=1 $fzf_args
end
