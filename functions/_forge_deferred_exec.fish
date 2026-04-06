# Deferred interactive Forge execution.
#
# Key bindings cannot reliably hand off the terminal to a long-running
# interactive program: when a Fish key binding returns, Fish issues cursor-up
# sequences to find the top of the prompt area before redrawing, which lands
# on and overwrites the final line of any output produced during the binding.
#
# The fix: the key binding only queues the Forge arguments in globals, then
# writes "_forge_deferred_exec" to the commandline buffer and calls
# "commandline -f execute". Fish runs _forge_deferred_exec as a real command,
# giving it full TTY access and correct cursor tracking. After the function
# returns, Fish draws the new prompt at the current cursor position — below
# all Forge output — without any cursor-up interference.
#
# Usage: set _FORGE_PENDING_EXEC 1 and _FORGE_PENDING_EXEC_ARGV before
#        putting "_forge_deferred_exec" in the commandline buffer.

function _forge_deferred_exec
    # Erase the "_forge_deferred_exec" line that Fish echoed before running us
    # and restore cursor visibility (cursor was hidden in the key binding to
    # prevent _forge_deferred_exec from briefly flashing on screen).
    # Do this first — before history delete — to minimise the visible window.
    if status is-interactive; and test -t 1
        printf '\033[1A\r\033[2K\033[?25h'
    end

    # Remove this dispatch wrapper from Fish history so the user never sees it.
    builtin history delete -- _forge_deferred_exec 2>/dev/null

    # If the caller saved the original commandline (e.g. ": hello world"),
    # echo it before forge output so the user can see what they sent.
    if test -n "$_FORGE_DEFERRED_EXEC_ECHO"
        printf '%s\n' "$_FORGE_DEFERRED_EXEC_ECHO"
        set --erase _FORGE_DEFERRED_EXEC_ECHO
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
