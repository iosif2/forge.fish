function _forge_command_sync_status
    set -l workspace_path "$argv[1]"
    if test -z "$workspace_path"
        set workspace_path .
    end

    echo
    _forge_run workspace status "$workspace_path"
end
