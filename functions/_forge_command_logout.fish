function _forge_command_logout
    set -l input_text $argv[1]
    echo
    set -l selected (_forge_provider_select '\\[yes\\]' "" "" "$input_text")
    if test -n "$selected"
        set -l provider (echo "$selected" | awk '{print $2}')
        _forge_run provider logout "$provider"
    end
end
