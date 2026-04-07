function _forge_conversation_set_previous --argument conversation_id
    if test -n "$conversation_id"
        set -g _FORGE_PREVIOUS_CONVERSATION_ID "$conversation_id"
    end
end

function _forge_conversation_switch
    set -l next_id "$argv[1]"

    if test -n "$_FORGE_CONVERSATION_ID"; and test "$_FORGE_CONVERSATION_ID" != "$next_id"
        _forge_conversation_set_previous "$_FORGE_CONVERSATION_ID"
    end

    set -g _FORGE_CONVERSATION_ID "$next_id"
end

function _forge_conversation_clear
    _forge_conversation_set_previous "$_FORGE_CONVERSATION_ID"
    set -g _FORGE_CONVERSATION_ID ""
end

function _forge_conversation_clone_id_from_output --argument clone_output
    set -l matches (string match -ra '[a-f0-9-]{36}' -- "$clone_output")
    if test (count $matches) -ge 1
        printf '%s\n' "$matches[-1]"
        return 0
    end

    return 1
end

function _forge_conversation_show_clone_details --argument clone_target original_id new_id
    if test "$clone_target" = "$original_id"
        return 0
    end

    echo
    _forge_run conversation show "$new_id"

    echo
    _forge_run conversation info "$new_id"
end

function _forge_conversation_clone_and_switch
    set -l clone_target "$argv[1]"
    set -l original_id "$_FORGE_CONVERSATION_ID"

    _forge_report info "Cloning conversation "(set_color --bold)"$clone_target"(set_color normal)

    set -l clone_output ($_FORGE_BIN conversation clone "$clone_target" 2>&1 | string collect)
    set -l clone_status $status
    if test $clone_status -ne 0
        _forge_report error "Failed to clone conversation: $clone_output"
        return 0
    end

    set -l new_id (_forge_conversation_clone_id_from_output "$clone_output")
    if test -z "$new_id"
        _forge_report error 'Failed to extract new conversation ID from clone output'
        return 0
    end

    _forge_conversation_switch "$new_id"
    _forge_report success "Switched to conversation "(set_color --bold)"$new_id"(set_color normal)
    _forge_conversation_show_clone_details "$clone_target" "$original_id" "$new_id"
end
