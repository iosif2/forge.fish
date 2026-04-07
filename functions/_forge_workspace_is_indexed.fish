function _forge_workspace_is_indexed
    set -l workspace_path "$argv[1]"
    if test -z "$workspace_path"
        set workspace_path .
    end

    $_FORGE_BIN workspace info "$workspace_path" >/dev/null 2>&1
end
