# Action handler: Initialize workspace for codebase search
# Usage: _forge_action_sync_init [workspace_path]

function _forge_action_sync_init
    set -l workspace_path "."
    if test (count $argv) -ge 1; and test -n "$argv[1]"
        set workspace_path "$argv[1]"
    end

    echo
    _forge_exec_interactive workspace init "$workspace_path"
end
