function _forge_commands_get
    if test -z "$_FORGE_COMMANDS"
        set -g _FORGE_COMMANDS (CLICOLOR_FORCE=0 $_FORGE_BIN list commands --porcelain 2>/dev/null | string collect)
    end
    echo "$_FORGE_COMMANDS"
end
