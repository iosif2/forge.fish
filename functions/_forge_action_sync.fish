# Action handler: Sync workspace for codebase search
# --init initializes the workspace first if it has not been set up yet
# Usage: _forge_action_sync [workspace_path]

function _forge_action_sync
    set -l workspace_path "."
    if test (count $argv) -ge 1; and test -n "$argv[1]"
        set workspace_path "$argv[1]"
    end

    echo
    _forge_exec_interactive workspace sync --init "$workspace_path"
end
