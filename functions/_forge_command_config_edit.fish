function _forge_command_config_edit
    echo

    set -l editor_cmd
    if test -n "$FORGE_EDITOR"
        set editor_cmd "$FORGE_EDITOR"
    else if test -n "$EDITOR"
        set editor_cmd "$EDITOR"
    else
        set editor_cmd nano
    end

    set -l editor_bin (string split ' ' -- "$editor_cmd")[1]
    if not command -q "$editor_bin"
        _forge_report error "Editor not found: $editor_cmd (set FORGE_EDITOR or EDITOR)"
        return 1
    end

    set -l config_file "$HOME/forge/.forge.toml"

    if not test -d "$HOME/forge"
        mkdir -p "$HOME/forge"; or begin
            _forge_report error "Failed to create ~/forge directory"
            return 1
        end
    end

    if not test -f "$config_file"
        touch "$config_file"; or begin
            _forge_report error "Failed to create $config_file"
            return 1
        end
    end

    eval "$editor_cmd '$config_file'" </dev/tty >/dev/tty 2>&1
    set -l exit_code $status

    if test $exit_code -ne 0
        _forge_report error "Editor exited with error code $exit_code"
    end

    _forge_reader_reset
end
