function _forge_run_interactive
    set -l agent_id "$_FORGE_ACTIVE_AGENT"
    if test -z "$agent_id"
        set agent_id forge
    end

    if test -n "$_FORGE_SESSION_MODEL"
        set -lx FORGE_SESSION__MODEL_ID "$_FORGE_SESSION_MODEL"
    end
    if test -n "$_FORGE_SESSION_PROVIDER"
        set -lx FORGE_SESSION__PROVIDER_ID "$_FORGE_SESSION_PROVIDER"
    end
    if test -n "$_FORGE_SESSION_REASONING_EFFORT"
        set -lx FORGE_REASONING__EFFORT "$_FORGE_SESSION_REASONING_EFFORT"
    end

    $_FORGE_BIN --agent "$agent_id" $argv </dev/tty >/dev/tty 2>/dev/tty
    set -l cmd_status $status

    set -g _FORGE_OUTPUT_MODE visible
    set -g _FORGE_RPROMPT_DIRTY 1
    return $cmd_status
end
