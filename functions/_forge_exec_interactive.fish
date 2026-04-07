function _forge_exec_interactive
    # Reader widgets do not own the tty, so interactive Forge subcommands must be rebound to /dev/tty here.
    set -l agent_id "forge"
    if test -n "$_FORGE_ACTIVE_AGENT"
        set agent_id "$_FORGE_ACTIVE_AGENT"
    end

    set -l cmd $_FORGE_BIN --agent "$agent_id"

    if test -n "$_FORGE_SESSION_MODEL"
        set -lx FORGE_SESSION__MODEL_ID "$_FORGE_SESSION_MODEL"
    end
    if test -n "$_FORGE_SESSION_PROVIDER"
        set -lx FORGE_SESSION__PROVIDER_ID "$_FORGE_SESSION_PROVIDER"
    end
    if test -n "$_FORGE_SESSION_REASONING_EFFORT"
        set -lx FORGE_REASONING__EFFORT "$_FORGE_SESSION_REASONING_EFFORT"
    end

    $cmd $argv </dev/tty >/dev/tty 2>/dev/tty
    set -l cmd_status $status

    set -g _FORGE_OUTPUT_MODE visible
    set -g _FORGE_RPROMPT_DIRTY 1
    return $cmd_status
end
