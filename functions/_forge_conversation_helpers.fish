function _forge_conversation_switch
    set -l new_conversation_id $argv[1]

    # Keep a "previous conversation" pointer so `:conversation -` behaves like `cd -`.
    if test -n "$_FORGE_CONVERSATION_ID"; and test "$_FORGE_CONVERSATION_ID" != "$new_conversation_id"
        set -g _FORGE_PREVIOUS_CONVERSATION_ID "$_FORGE_CONVERSATION_ID"
    end

    set -g _FORGE_CONVERSATION_ID "$new_conversation_id"
end

function _forge_conversation_clear
    if test -n "$_FORGE_CONVERSATION_ID"
        set -g _FORGE_PREVIOUS_CONVERSATION_ID "$_FORGE_CONVERSATION_ID"
    end

    set -g _FORGE_CONVERSATION_ID ""
end

function _forge_conversation_clone_and_switch
    set -l clone_target $argv[1]

    set -l original_conversation_id "$_FORGE_CONVERSATION_ID"

    _forge_report info "Cloning conversation "(set_color --bold)"$clone_target"(set_color normal)
    set -l clone_output ($_FORGE_BIN conversation clone "$clone_target" 2>&1 | string collect)
    set -l clone_exit_code $status

    if test $clone_exit_code -eq 0
        set -l new_id (echo "$clone_output" | grep -oE '[a-f0-9-]{36}' | tail -1)

        if test -n "$new_id"
            _forge_conversation_switch "$new_id"

            _forge_report success "Switched to conversation "(set_color --bold)"$new_id"(set_color normal)

            # Cloning the already-active conversation only changes context; cloning a different one also shows the new content/info.
            if test "$clone_target" != "$original_conversation_id"
                echo
                _forge_run conversation show "$new_id"

                echo
                _forge_run conversation info "$new_id"
            end
        else
            _forge_report error "Failed to extract new conversation ID from clone output"
        end
    else
        _forge_report error "Failed to clone conversation: $clone_output"
    end
end
