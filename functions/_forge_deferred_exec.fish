# Deferred interactive Forge execution.
#
# Key bindings cannot reliably hand off the terminal to a long-running
# interactive program: when a Fish key binding returns, Fish issues cursor-up
# sequences to find the top of the prompt area before redrawing, which lands
# on and overwrites the final line of any output produced during the binding.
#
# The fix: the key binding only queues the Forge arguments in globals, then
# writes ":" to the commandline buffer and calls
# "commandline -f execute". The : function sees the pending flag and forwards
# to _forge_deferred_exec as a real command,
# giving it full TTY access and correct cursor tracking. After the function
# returns, Fish draws the new prompt at the current cursor position — below
# all Forge output — without any cursor-up interference.
#
# Usage: set _FORGE_PENDING_EXEC 1 and _FORGE_PENDING_EXEC_ARGV before
#        putting ":" in the commandline buffer.

function _forge_deferred_exec
    set -l _erase_wrapper 0
    if test "$_FORGE_DEFERRED_EXEC_ERASE_WRAPPER" = 1
        set _erase_wrapper 1
    end
    set --erase _FORGE_DEFERRED_EXEC_ERASE_WRAPPER

    set -l _wrapper_command ""
    if set -q _FORGE_DEFERRED_EXEC_WRAPPER_COMMAND
        set _wrapper_command "$_FORGE_DEFERRED_EXEC_WRAPPER_COMMAND"
        set --erase _FORGE_DEFERRED_EXEC_WRAPPER_COMMAND
    end

    # Erase the wrapper line that Fish echoed before running us and restore
    # cursor visibility (cursor was hidden in the key binding to prevent the
    # wrapper command from briefly flashing on screen).
    # Do this first — before history delete — to minimise the visible window.
    if test "$_erase_wrapper" = 1
        if status is-interactive; and test -t 1
            printf '\033[1A\r\033[2K\033[?25h'
        end
    end

    set -l _history_line ""
    if set -q _FORGE_DEFERRED_EXEC_HISTORY
        set _history_line "$_FORGE_DEFERRED_EXEC_HISTORY"
        set --erase _FORGE_DEFERRED_EXEC_HISTORY
    end

    if test "$_erase_wrapper" = 1; or test -n "$_history_line"
        # Remove this dispatch wrapper from Fish history so the user never sees it.
        set -l _history_wrapper _forge_deferred_exec
        if test -n "$_wrapper_command"
            set _history_wrapper "$_wrapper_command"
        end
        builtin history delete --exact --case-sensitive -- "$_history_wrapper" 2>/dev/null
        if test -n "$_history_line"
            builtin history append -- "$_history_line" 2>/dev/null
            builtin history save 2>/dev/null
        end
    end

    # Reprint the original :prompt line after erasing the wrapper so the user
    # sees what they sent instead of perceiving Forge output as overwriting the
    # prompt line. This mirrors the old deferred-echo behavior while keeping the
    # stronger history repair above.
    if test -n "$_history_line"
        printf '%s\n' "$_history_line"
    end

    if test "$_FORGE_PENDING_EXEC" != 1
        return 0
    end

    set -g _FORGE_PENDING_EXEC 0
    set -l _pending_argv $_FORGE_PENDING_EXEC_ARGV
    set --erase _FORGE_PENDING_EXEC_ARGV

    # Resolve active agent
    set -l _agent forge
    if test -n "$_FORGE_ACTIVE_AGENT"
        set _agent "$_FORGE_ACTIVE_AGENT"
    end

    # Apply session overrides as local exports
    if test -n "$_FORGE_SESSION_MODEL"
        set -lx FORGE_SESSION__MODEL_ID "$_FORGE_SESSION_MODEL"
    end
    if test -n "$_FORGE_SESSION_PROVIDER"
        set -lx FORGE_SESSION__PROVIDER_ID "$_FORGE_SESSION_PROVIDER"
    end
    if test -n "$_FORGE_SESSION_REASONING_EFFORT"
        set -lx FORGE_REASONING__EFFORT "$_FORGE_SESSION_REASONING_EFFORT"
    end

    # Run forge as a real command — no /dev/tty redirect needed here because
    # Fish has already handed us a proper interactive terminal context.
    $_FORGE_BIN --agent $_agent $_pending_argv

    # Cursor handoff: forge may not end with a trailing newline. A single \r\n
    # is sufficient because Fish's post-command prompt draw places the next
    # prompt at the current cursor position without cursor-up sequences.
    if test -t 1
        printf '\r\n'
    end

    set -g _FORGE_POST_OUTPUT_PADDING 1
    set -g _FORGE_RPROMPT_DIRTY 1
    _forge_start_background_sync
    _forge_start_background_update
end
