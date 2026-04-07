function _forge_command_sync
    set -l workspace_path "$argv[1]"
    if test -z "$workspace_path"
        set workspace_path .
    end

    echo
    _forge_run_interactive workspace sync --init "$workspace_path"
end
