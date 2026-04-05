function _forge_refresh_colon_command_functions --description 'Create synthetic :command functions so Fish native completion can complete :new syntax'
    if set -q _FORGE_COLON_COMMAND_NAMES
        for command_name in $_FORGE_COLON_COMMAND_NAMES
            complete -c ":$command_name" -e 2>/dev/null
            functions --erase ":$command_name" 2>/dev/null
        end
    end

    set -l registered_names
    set -l command_lines (_forge_complete_colon_commands)

    for line in $command_lines
        if test -z "$line"
            continue
        end

        set -l match (string match --regex '^([^\t]+)(\t(.*))?$' -- "$line")
        if test (count $match) -lt 2
            continue
        end

        set -l command_name "$match[2]"
        set -l description ''
        if test (count $match) -ge 4
            set description "$match[4]"
        end

        if test -z "$command_name"
            continue
        end

        if contains -- "$command_name" $registered_names
            continue
        end
        set -a registered_names "$command_name"

        set -l function_name ":$command_name"
        set -l escaped_name (string escape --style=script -- "$function_name")

        if test -n "$description"
            set -l escaped_description (string escape --style=script -- "$description")
            eval "function $escaped_name --description $escaped_description; return 0; end"
            complete -c "$function_name" -f -d "$description"
        else
            eval "function $escaped_name; return 0; end"
            complete -c "$function_name" -f
        end
    end

    set -g _FORGE_COLON_COMMAND_NAMES $registered_names
end
