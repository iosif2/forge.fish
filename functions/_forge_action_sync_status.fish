# Action handler: Show sync status of workspace files
# Usage: _forge_action_sync_status [workspace_path]

function _forge_action_sync_status
    set -l workspace_path "."
    if test (count $argv) -ge 1; and test -n "$argv[1]"
        set workspace_path "$argv[1]"
    end

    echo
    _forge_exec workspace status "$workspace_path"
end
