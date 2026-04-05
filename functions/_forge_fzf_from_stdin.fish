# Keybinding-safe fzf helper for Fish reader widgets.
# Usage:
#   printf 'a\nb\n' | _forge_fzf_from_stdin [additional fzf options...]
#   _forge_fzf_from_stdin --input-file /path/to/candidates [additional fzf options...]
#
# The selected value is stored in $_FORGE_FZF_SELECTION so callers do not need
# nested command substitutions while running inside a bind handler.

function _forge_fzf_from_stdin --description 'Run fzf with candidates from stdin or a file while attaching the UI to /dev/tty'
    set -g _FORGE_FZF_SELECTION ""

    set -l cleanup_input_file 1
    set -l input_file
    set -l fzf_args $argv

    if test (count $argv) -ge 2; and test "$argv[1]" = '--input-file'
        set input_file "$argv[2]"
        set cleanup_input_file 0
        if test (count $argv) -ge 3
            set fzf_args $argv[3..-1]
        else
            set fzf_args
        end
    else
        set input_file (mktemp)
        or return 1

        string collect > "$input_file"
        or begin
            rm -f "$input_file"
            return 1
        end
    end

    set -l output_file (mktemp)
    or begin
        if test "$cleanup_input_file" = 1
            rm -f "$input_file"
        end
        return 1
    end

    if not test -s "$input_file"
        if test "$cleanup_input_file" = 1
            rm -f "$input_file"
        end
        rm -f "$output_file"
        return 0
    end

    if test -r /dev/tty; and test -w /dev/tty
        set -l default_command (string join ' ' cat (string escape --style=script -- "$input_file"))
        set -l escaped_default_command (string escape --style=script -- "$default_command")
        set -l escaped_output_file (string escape --style=script -- "$output_file")
        set -l escaped_args
        for arg in $fzf_args
            set -a escaped_args (string escape --style=script -- "$arg")
        end

        set -l shell_command_parts \
            "FZF_DEFAULT_COMMAND=$escaped_default_command" \
            fzf \
            --reverse \
            --exact \
            --cycle \
            --select-1 \
            --height 80% \
            --no-scrollbar \
            --ansi \
            "--color=header:bold" \
            $escaped_args \
            '< /dev/tty' \
            "> $escaped_output_file" \
            '2> /dev/tty'

        sh -lc (string join -- ' ' $shell_command_parts)
    else
        _forge_fzf $fzf_args < "$input_file" > "$output_file"
    end
    set -l fzf_status $status

    if test -f "$output_file"
        set -g _FORGE_FZF_SELECTION (string collect < "$output_file")
    end

    if test "$cleanup_input_file" = 1
        rm -f "$input_file"
    end
    rm -f "$output_file"

    if test -n "$_FORGE_FZF_SELECTION"
        return 0
    end

    return $fzf_status
end

