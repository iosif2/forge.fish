function _forge_command_config_edit_editor
    if test -n "$FORGE_EDITOR"
        printf '%s\n' "$FORGE_EDITOR"
        return 0
    end
    if test -n "$EDITOR"
        printf '%s\n' "$EDITOR"
        return 0
    end
    printf '%s\n' nano
end

function _forge_command_config_edit
    echo

    set -l editor_cmd (_forge_command_config_edit_editor)
    set -l editor_bin (string split ' ' -- "$editor_cmd")[1]
    if not command -q "$editor_bin"
        _forge_report error "Editor not found: $editor_cmd (set FORGE_EDITOR or EDITOR)"
        return 1
    end

    set -l config_dir "$HOME/forge"
    set -l config_file "$config_dir/.forge.toml"

    mkdir -p "$config_dir"
    or begin
        _forge_report error 'Failed to create ~/forge directory'
        return 1
    end

    test -f "$config_file"; or touch "$config_file"
    or begin
        _forge_report error "Failed to create $config_file"
        return 1
    end

    eval "$editor_cmd '$config_file'" </dev/tty >/dev/tty 2>&1
    set -l exit_code $status
    if test $exit_code -ne 0
        _forge_report error "Editor exited with error code $exit_code"
    end

    _forge_reader_reset
end
