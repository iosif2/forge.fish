function _forge_command_sync_init
    set -l workspace_path "$argv[1]"
    if test -z "$workspace_path"
        set workspace_path .
    end

    echo
    _forge_run_interactive workspace init "$workspace_path"
end
