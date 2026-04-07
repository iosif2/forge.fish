function _forge_command_sync_info
    set -l workspace_path "$argv[1]"
    if test -z "$workspace_path"
        set workspace_path .
    end

    echo
    _forge_run workspace info "$workspace_path"
end
