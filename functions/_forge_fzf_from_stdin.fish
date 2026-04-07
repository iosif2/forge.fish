function _forge_fzf_from_stdin_cleanup --argument input_file output_file cleanup_input_file
    if test "$cleanup_input_file" = 1
        rm -f "$input_file"
    end
    rm -f "$output_file"
end

function _forge_fzf_from_stdin_resolve_input --argument maybe_flag maybe_file
    if test "$maybe_flag" = --input-file; and test -n "$maybe_file"
        printf '%s\n%s\n' 0 "$maybe_file"
        return 0
    end

    set -l input_file (mktemp)
    or return 1

    string collect > "$input_file"
    or begin
        rm -f "$input_file"
        return 1
    end

    printf '%s\n%s\n' 1 "$input_file"
end

function _forge_fzf_from_stdin
    set -g _FORGE_FZF_SELECTION ''

    set -l input_info (_forge_fzf_from_stdin_resolve_input "$argv[1]" "$argv[2]")
    or return 1

    set -l cleanup_input_file "$input_info[1]"
    set -l input_file "$input_info[2]"
    set -l fzf_args $argv
    if test "$cleanup_input_file" = 0
        set fzf_args $argv[3..-1]
    end

    set -l output_file (mktemp)
    or begin
        _forge_fzf_from_stdin_cleanup "$input_file" '' "$cleanup_input_file"
        return 1
    end

    if not test -s "$input_file"
        _forge_fzf_from_stdin_cleanup "$input_file" "$output_file" "$cleanup_input_file"
        return 0
    end

    if test -r /dev/tty; and test -w /dev/tty
        set -l default_command (string join ' ' cat (string escape --style=script -- "$input_file"))
        set -l escaped_args
        for arg in $fzf_args
            set -a escaped_args (string escape --style=script -- "$arg")
        end

        set -l shell_command_parts \
            SHELL=/bin/sh \
            FZF_DEFAULT_COMMAND=(string escape --style=script -- "$default_command") \
            fzf \
            --reverse \
            --exact \
            --cycle \
            --select-1 \
            --height 80% \
            --no-scrollbar \
            --ansi \
            '--color=header:bold' \
            $escaped_args \
            '< /dev/tty' \
            "> "(string escape --style=script -- "$output_file") \
            '2> /dev/tty'

        sh -lc (string join ' ' -- $shell_command_parts)
    else
        _forge_fzf $fzf_args < "$input_file" > "$output_file"
    end
    set -l fzf_status $status

    if test -f "$output_file"
        set -g _FORGE_FZF_SELECTION (string collect < "$output_file")
    end

    _forge_fzf_from_stdin_cleanup "$input_file" "$output_file" "$cleanup_input_file"

    if test -n "$_FORGE_FZF_SELECTION"
        return 0
    end

    return $fzf_status
end
