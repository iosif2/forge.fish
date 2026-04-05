# Execute forge commands interactively with TTY redirection
# Same as _forge_exec but connects stdin/stdout/stderr to /dev/tty so that
# interactive prompts (rustyline, fzf, etc.) work correctly when forge
# is launched from a key binding context. Fish key binding functions
# do not have direct terminal access, so without this redirect any
# readline library would see a non-tty stdin and return EOF immediately.
# Do NOT use inside (command) substitutions - use _forge_exec instead.
# Usage: _forge_exec_interactive <args...>

function _forge_exec_interactive
    # Determine active agent, default to "forge"
    set -l agent_id "forge"
    if test -n "$_FORGE_ACTIVE_AGENT"
        set agent_id "$_FORGE_ACTIVE_AGENT"
    end

    # Build command array
    set -l cmd $_FORGE_BIN --agent "$agent_id"

    # Export session model/provider if set
    if test -n "$_FORGE_SESSION_MODEL"
        set -lx FORGE_SESSION__MODEL_ID "$_FORGE_SESSION_MODEL"
    end
    if test -n "$_FORGE_SESSION_PROVIDER"
        set -lx FORGE_SESSION__PROVIDER_ID "$_FORGE_SESSION_PROVIDER"
    end
    if test -n "$_FORGE_SESSION_REASONING_EFFORT"
        set -lx FORGE_REASONING__EFFORT "$_FORGE_SESSION_REASONING_EFFORT"
    end

    # Execute with full TTY redirection for interactive use
    $cmd $argv </dev/tty >/dev/tty 2>/dev/tty
    set -l cmd_status $status

    # Forge may leave the cursor at the end of its final status line without a
    # trailing newline. Move to the next line so the Fish prompt does not
    # overwrite Forge's final output.
    if status is-interactive; and test -w /dev/tty
        command printf '\r\n' >/dev/tty 2>/dev/null
    end

    # Fish already redraws the prompt when the keybinding handler returns. For
    # interactive Forge sessions, forcing an extra _forge_reset pass can erase
    # the final "Finished ..." line.
    set -g _FORGE_SKIP_RESET 1
    set -g _FORGE_RPROMPT_DIRTY 1
    return $cmd_status
end

