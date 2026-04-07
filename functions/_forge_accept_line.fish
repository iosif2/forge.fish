# Core dispatcher for forge :commands
# Port of forge-accept-line ZLE widget from shell-plugin/lib/dispatcher.zsh
#
# Patterns:
#   :command [args]  - dispatch to the appropriate action handler
#   : <text>         - default action (send text to active agent)
#   anything else    - normal shell command execution

function _forge_commandline_supports_search_field
    if set -q _FORGE_HAS_COMMANDLINE_SEARCH_FIELD
        test "$_FORGE_HAS_COMMANDLINE_SEARCH_FIELD" = 1
        return
    end

    if commandline --help 2>/dev/null | string match -q '*--search-field*'
        set -g _FORGE_HAS_COMMANDLINE_SEARCH_FIELD 1
        return 0
    end

    set -g _FORGE_HAS_COMMANDLINE_SEARCH_FIELD 0
    return 1
end

function _forge_prepare_dispatch_lite --argument buffer
    # Lightweight version of _forge_prepare_dispatch.
    # Does NOT queue clear-commandline (would wipe deferred-exec buffer before
    # execute fires) and does NOT queue repaint (repaint fires after the binding
    # returns, AFTER stdout output has been printed — queuing repaint here causes
    # Fish to scroll back to the original prompt position and overwrite that
    # output). Each code path in _forge_accept_line handles its own repaint or
    # clear-commandline at the appropriate time.
    set -l _forge_cancel_modes 0
    if commandline --paging-mode >/dev/null; or commandline --search-mode >/dev/null
        set _forge_cancel_modes 1
    else if _forge_commandline_supports_search_field; and commandline --search-field >/dev/null
        set _forge_cancel_modes 1
    end

    if test "$_forge_cancel_modes" = 1
        commandline -f cancel
    end

    commandline -f suppress-autosuggestion
    commandline -C (string length -- "$buffer")
end

function _forge_accept_line
    set -l buf (commandline)

    # --- Pattern 1: :command [args] ---
    set -l captures (string match --regex '^:([a-zA-Z][a-zA-Z0-9_-]*)( (.*))?$' -- "$buf")
    if test (count $captures) -ge 2
        set -l user_action $captures[2]
        set -l input_text ''
        if test (count $captures) -ge 4
            set input_text $captures[4]
        end

        # Use lite prep (no clear-commandline) so that if the action sets
        # _FORGE_PENDING_EXEC we can still write _forge_deferred_exec into the
        # buffer before queueing execute.
        _forge_prepare_dispatch_lite "$buf"

        switch $user_action
            case ask
                set user_action sage
            case plan
                set user_action muse
        end

        switch $user_action
            case new n
                _forge_action_new "$input_text"
            case info i
                _forge_action_info
            case env e
                _forge_action_env
            case dump d
                _forge_action_dump "$input_text"
            case compact
                _forge_action_compact
            case retry r
                _forge_action_retry
            case agent a
                _forge_action_agent "$input_text"
            case conversation c
                _forge_action_conversation "$input_text"
            case config-provider provider p
                _forge_action_provider "$input_text"
            case config-model cm
                _forge_action_model "$input_text"
            case model m
                _forge_action_session_model "$input_text"
            case config-reload cr model-reset mr
                _forge_action_config_reload
            case reasoning-effort re
                _forge_action_reasoning_effort "$input_text"
            case config-reasoning-effort cre
                _forge_action_config_reasoning_effort "$input_text"
            case config-commit-model ccm
                _forge_action_commit_model "$input_text"
            case config-suggest-model csm
                _forge_action_suggest_model "$input_text"
            case tools t
                _forge_action_tools
            case config
                _forge_action_config
            case config-edit ce
                _forge_action_config_edit
            case skill
                _forge_action_skill
            case edit ed
                _forge_action_editor "$input_text"
                return
            case commit
                _forge_action_commit "$input_text"
            case commit-preview
                _forge_action_commit_preview "$input_text"
                return
            case suggest s
                _forge_action_suggest "$input_text"
                return
            case clone
                _forge_action_clone "$input_text"
            case rename rn
                _forge_action_rename "$input_text"
            case conversation-rename
                _forge_action_conversation_rename "$input_text"
            case copy
                _forge_action_copy
            case workspace-sync sync
                _forge_action_sync
            case workspace-init sync-init
                _forge_action_sync_init
            case workspace-status sync-status
                _forge_action_sync_status
            case workspace-info sync-info
                _forge_action_sync_info
            case provider-login login
                _forge_action_login "$input_text"
            case logout
                _forge_action_logout "$input_text"
            case doctor
                _forge_action_doctor
            case keyboard-shortcuts kb
                _forge_action_keyboard
            case '*'
                _forge_action_default "$user_action" "$input_text"
        end

        if test "$_FORGE_PENDING_EXEC" = 1
            # Hand off to _forge_deferred_exec via Fish's normal command
            # execution path so the new prompt is drawn correctly below
            # Forge output without cursor-up interference.
            # NOTE: do NOT queue clear-commandline before this — it would wipe
            # the buffer we set here before execute fires.
            # Hide cursor so the _forge_deferred_exec text Fish echoes before
            # running the command is not perceived as a flash.
            printf '\033[?25l'
            commandline -r _forge_deferred_exec
            commandline -f execute
            return
        end

        if test "$_FORGE_SKIP_RESET" = 1
            set --erase _FORGE_SKIP_RESET
            set --erase _FORGE_POST_INTERACTIVE_NEWLINE
            set --erase _FORGE_POST_OUTPUT_PADDING
            commandline -r ""
            return
        end

        # Non-pending path.
        # When visible output was produced, use commandline -f execute with an
        # empty buffer. execute causes Fish to draw a new prompt from the
        # CURRENT cursor position (below the output) rather than scrolling back
        # to the original prompt position the way repaint/clear-commandline do.
        # When no output was produced, _forge_reset handles the repaint.
        set -l _forge_had_output 0
        if test "$_FORGE_POST_OUTPUT_PADDING" = 1; or test "$_FORGE_POST_INTERACTIVE_NEWLINE" = 1
            set _forge_had_output 1
        end
        if test "$_forge_had_output" = 1
            set --erase _FORGE_POST_OUTPUT_PADDING
            set --erase _FORGE_POST_INTERACTIVE_NEWLINE
            # Clear rprompt cache so any intermediate render (from
            # suppress-autosuggestion or execute processing) shows nothing
            # rather than a floating rprompt at the wrong position.
            set -g _FORGE_RPROMPT_ZSH_CACHE ""
            set -g _FORGE_RPROMPT_DIRTY 1
            # execute adds a blank newline before drawing the new prompt.
            # Signal _forge_skip_blank_line so the fish_prompt event handler
            # can erase it before the prompt renders.
            set -g _FORGE_SKIP_BLANK_LINE 1
            commandline -r ""
            commandline -f execute
            return
        end
        _forge_reset
        return
    end

    # --- Pattern 2: ": text" (default action with args) ---
    set -l prompt_capture (string match --regex '^: (.*)$' -- "$buf")
    if test (count $prompt_capture) -ge 2
        set -l input_text $prompt_capture[2]

        # Use lite prep (no clear-commandline) for the same reason as Pattern 1.
        _forge_prepare_dispatch_lite "$buf"
        _forge_action_default '' "$input_text"
        if test "$_FORGE_PENDING_EXEC" = 1
            # Hand off to _forge_deferred_exec via Fish's normal command
            # execution path so the new prompt is drawn correctly below
            # Forge output without cursor-up interference.
            # Save the original buffer so _forge_deferred_exec can echo it
            # before forge output — without this the user's ": text" input
            # is silently erased and replaced by forge output.
            set -g _FORGE_DEFERRED_EXEC_ECHO "$buf"
            printf '\033[?25l'
            commandline -r _forge_deferred_exec
            commandline -f execute
            return
        end

        if test "$_FORGE_SKIP_RESET" = 1
            set --erase _FORGE_SKIP_RESET
            set --erase _FORGE_POST_INTERACTIVE_NEWLINE
            set --erase _FORGE_POST_OUTPUT_PADDING
            commandline -r ""
            return
        end

        # Non-pending path: same logic as Pattern 1.
        set -l _forge_had_output 0
        if test "$_FORGE_POST_OUTPUT_PADDING" = 1; or test "$_FORGE_POST_INTERACTIVE_NEWLINE" = 1
            set _forge_had_output 1
        end
        _forge_reset
        if test "$_forge_had_output" = 0
            commandline -f clear-commandline
        end
        return
    end

    commandline -f execute
end
