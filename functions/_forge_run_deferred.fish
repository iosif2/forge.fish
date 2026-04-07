function _forge_run_deferred
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
        set -l _history_wrapper _forge_run_deferred
        if test -n "$_wrapper_command"
            set _history_wrapper "$_wrapper_command"
        end
        builtin history delete --exact --case-sensitive -- "$_history_wrapper" 2>/dev/null
        if test -n "$_history_line"
            builtin history append -- "$_history_line" 2>/dev/null
            builtin history save 2>/dev/null
        end
    end

    if test -n "$_history_line"
        printf '%s\n' "$_history_line"
    end

    if test "$_FORGE_PENDING_EXEC" != 1
        return 0
    end

    set -g _FORGE_PENDING_EXEC 0
    set -l _pending_argv $_FORGE_PENDING_EXEC_ARGV
    set --erase _FORGE_PENDING_EXEC_ARGV

    set -l _agent "$_FORGE_ACTIVE_AGENT"
    if test -z "$_agent"
        set _agent forge
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

    $_FORGE_BIN --agent $_agent $_pending_argv

    if test -t 1
        printf '\r\n'
    end

    set -g _FORGE_OUTPUT_MODE visible
    set -g _FORGE_RPROMPT_DIRTY 1
    _forge_sync_start
    _forge_update_start
end
