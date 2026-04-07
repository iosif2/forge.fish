function _forge_porcelain_find_index_field --argument row field_number
    set -l columns (string split '\t' -- (string replace -ra '  +' '\t' -- (string trim -- "$row")))
    if test (count $columns) -ge $field_number
        printf '%s\n' "$columns[$field_number]"
    end
end

function _forge_porcelain_find_index
    set -l output "$argv[1]"
    set -l value_to_find "$argv[2]"
    set -l field_number "$argv[3]"
    set -l field_number2 "$argv[4]"
    set -l value_to_find2 "$argv[5]"

    if test -z "$field_number"
        set field_number 1
    end

    set -l index 1
    set -l line_number 0

    for row in (string split \n -- "$output")
        set line_number (math "$line_number + 1")
        if test $line_number -eq 1
            continue
        end

        if test (_forge_porcelain_find_index_field "$row" "$field_number") = "$value_to_find"
            if test -n "$field_number2"; and test -n "$value_to_find2"
                if test (_forge_porcelain_find_index_field "$row" "$field_number2") = "$value_to_find2"
                    printf '%s\n' "$index"
                    return 0
                end
            else
                printf '%s\n' "$index"
                return 0
            end
        end

        set index (math "$index + 1")
    end

    printf '%s\n' 1
end
