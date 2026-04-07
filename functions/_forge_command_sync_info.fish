function _forge_command_sync_info
    set -l workspace_path "."
    if test (count $argv) -ge 1; and test -n "$argv[1]"
        set workspace_path "$argv[1]"
    end

    echo
    _forge_run workspace info "$workspace_path"
end
