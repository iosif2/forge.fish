function _forge_command_clone_list
    $_FORGE_BIN conversation list --porcelain 2>/dev/null | string collect
end

function _forge_command_clone_row_id --argument row
    printf '%s\n' (string split -m 1 ' ' -- (string trim -- "$row"))[1]
end

function _forge_command_clone_pick_row --argument conversations_output current_id
    set -l fzf_args \
        '--prompt=Clone Conversation ❯ ' \
        --delimiter="$_FORGE_DELIMITER" \
        --with-nth='2,3' \
        --preview="CLICOLOR_FORCE=1 $_FORGE_BIN conversation info {1}; echo; CLICOLOR_FORCE=1 $_FORGE_BIN conversation show {1}" \
        $_FORGE_PREVIEW_WINDOW

    if test -n "$current_id"
        set -l index (_forge_porcelain_find_index "$conversations_output" "$current_id")
        set -a fzf_args --bind="start:pos($index)"
    end

    printf '%s\n' "$conversations_output" | _forge_fzf --header-lines=1 $fzf_args
end

function _forge_command_clone
    set -l clone_target "$argv[1]"

    echo

    if test -n "$clone_target"
        _forge_conversation_clone_and_switch "$clone_target"
        return 0
    end

    set -l conversations_output (_forge_command_clone_list)
    if test -z "$conversations_output"
        _forge_report error 'No conversations found'
        return 0
    end

    set -l selected_row (_forge_command_clone_pick_row "$conversations_output" "$_FORGE_CONVERSATION_ID")
    if test -z "$selected_row"
        return 0
    end

    _forge_conversation_clone_and_switch (_forge_command_clone_row_id "$selected_row")
end
