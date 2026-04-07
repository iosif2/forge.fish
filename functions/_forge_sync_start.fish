function _forge_sync_start
    set -l sync_enabled "$FORGE_SYNC_ENABLED"
    if test -z "$sync_enabled"
        set sync_enabled true
    end

    if test "$sync_enabled" != true
        return 0
    end

    set -l workspace_path (pwd -P)
    _forge_workspace_is_indexed "$workspace_path"
    or return 0

    $_FORGE_BIN workspace sync "$workspace_path" >/dev/null 2>&1 </dev/null &
    disown
end
