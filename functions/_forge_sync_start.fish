function _forge_sync_start
    set -l sync_enabled "true"
    if set -q FORGE_SYNC_ENABLED; and test -n "$FORGE_SYNC_ENABLED"
        set sync_enabled "$FORGE_SYNC_ENABLED"
    end

    if test "$sync_enabled" != "true"
        return 0
    end

    set -l workspace_path (pwd -P)

    if not _forge_workspace_is_indexed "$workspace_path"
        return 0
    end

    $_FORGE_BIN workspace sync "$workspace_path" >/dev/null 2>&1 </dev/null &
    disown
end
