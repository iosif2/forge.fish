function _forge_is_workspace_indexed
    set -l workspace_path $argv[1]
    $_FORGE_BIN workspace info "$workspace_path" >/dev/null 2>&1
    return $status
end
