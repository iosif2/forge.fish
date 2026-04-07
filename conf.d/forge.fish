# This file owns session-scoped shell wiring: prompt wrappers, key bindings, and shared Forge globals.
set -l __forge_plugin_root (path dirname (path dirname (status filename)))
if test -f "$__forge_plugin_root/functions/_forge_conversation_helpers.fish"
    source "$__forge_plugin_root/functions/_forge_conversation_helpers.fish"
end
set --erase __forge_plugin_root

# Re-sourcing during install/update should replace the old in-memory plugin state first.
if set -q _FORGE_PLUGIN_LOADED
    if functions -q _forge_uninstall
        _forge_uninstall
    else
        for var in (set --names | string match --entire --regex '^_FORGE_.*$')
            set --erase $var
        end
    end
end

function __forge_map_zsh_color --argument color_code --description 'Map zsh 256-color prompt codes to fish colors'
    switch "$color_code"
        case 15
            printf 'white'
        case 134
            printf 'cyan'
        case 2
            printf 'green'
        case 240
            printf 'brblack'
        case '*'
            printf 'normal'
    end
end

function __forge_emit_prompt_segment --argument text is_bold color_code --description 'Print one parsed prompt segment with fish styling'
    if test -z "$text"
        return 0
    end

    set -l color_name (__forge_map_zsh_color "$color_code")
    set -l set_color_args

    if test "$is_bold" = 1
        set -a set_color_args --bold
    end

    if test -n "$color_name"; and test "$color_name" != normal
        set -a set_color_args "$color_name"
    end

    if test (count $set_color_args) -gt 0
        set_color $set_color_args
    else
        set_color normal
    end

    printf '%s' "$text"
end

function __forge_render_zsh_rprompt --argument raw_prompt --description 'Convert cached zsh rprompt escapes into fish prompt colors'
    if test -z "$raw_prompt"
        return 0
    end

    set -l index 1
    set -l prompt_length (string length -- "$raw_prompt")
    set -l segment ''
    set -l is_bold 0
    set -l color_code ''

    while test $index -le $prompt_length
        set -l char (string sub -s $index -l 1 -- "$raw_prompt")
        if test "$char" != '%'
            set segment "$segment$char"
            set index (math "$index + 1")
            continue
        end

        __forge_emit_prompt_segment "$segment" "$is_bold" "$color_code"
        set segment ''

        set -l next_char (string sub -s (math "$index + 1") -l 1 -- "$raw_prompt")
        switch "$next_char"
            case B
                set is_bold 1
                set index (math "$index + 2")
            case b
                set is_bold 0
                set index (math "$index + 2")
            case f
                set color_code ''
                set index (math "$index + 2")
            case F
                if test (string sub -s (math "$index + 2") -l 1 -- "$raw_prompt") = '{'
                    set -l color_capture (string match --regex '^([0-9]+)\}' -- (string sub -s (math "$index + 3") -- "$raw_prompt"))
                    if test (count $color_capture) -ge 2
                        set color_code "$color_capture[2]"
                        set -l color_length (string length -- "$color_capture[2]")
                        set index (math "$index + 3 + $color_length + 1")
                        continue
                    end
                end

                set segment '%F'
                set index (math "$index + 2")
            case '%'
                set segment '%'
                set index (math "$index + 2")
            case '*'
                set segment "%$next_char"
                set index (math "$index + 2")
        end
    end

    __forge_emit_prompt_segment "$segment" "$is_bold" "$color_code"
    set_color normal
end

function __forge_prompt_cache_signature --description 'Build a stable cache key for the Forge right prompt state'
    printf '%s\x1f%s\x1f%s\x1f%s\x1f%s' \
        "$_FORGE_ACTIVE_AGENT" \
        "$_FORGE_CONVERSATION_ID" \
        "$_FORGE_SESSION_MODEL" \
        "$_FORGE_SESSION_PROVIDER" \
        "$_FORGE_BIN"
end

function __forge_refresh_prompt_cache --description 'Refresh the cached zsh rprompt output from the forge binary'
    set -l forge_bin "$_FORGE_BIN"
    if test -z "$forge_bin"; and set -q FORGE_BIN; and test -n "$FORGE_BIN"
        set forge_bin "$FORGE_BIN"
    end
    if test -z "$forge_bin"
        set forge_bin forge
    end

    set -l prompt_env
    if test -n "$_FORGE_SESSION_MODEL"
        set -a prompt_env FORGE_SESSION__MODEL_ID=$_FORGE_SESSION_MODEL
    end
    if test -n "$_FORGE_SESSION_PROVIDER"
        set -a prompt_env FORGE_SESSION__PROVIDER_ID=$_FORGE_SESSION_PROVIDER
    end
    if test -n "$_FORGE_CONVERSATION_ID"
        set -a prompt_env _FORGE_CONVERSATION_ID=$_FORGE_CONVERSATION_ID
    end
    if test -n "$_FORGE_ACTIVE_AGENT"
        set -a prompt_env _FORGE_ACTIVE_AGENT=$_FORGE_ACTIVE_AGENT
    end

    set -l raw_prompt (env $prompt_env $forge_bin zsh rprompt 2>/dev/null | string collect)
    set -l refresh_status $status

    if test $refresh_status -eq 0
        set -g _FORGE_RPROMPT_ZSH_CACHE "$raw_prompt"
    else
        set -g _FORGE_RPROMPT_ZSH_CACHE ''
    end

    set -g _FORGE_RPROMPT_CACHE_READY 1
end

function __forge_erase_execute_blank --on-event fish_prompt --description 'Erase the blank line Fish emits before the prompt when execute fires'
    # execute prints one extra blank line before the prompt; consume it once here.
    if test "$_FORGE_SKIP_BLANK_LINE" = 1
        set --erase _FORGE_SKIP_BLANK_LINE
        printf '\033[1A\033[2K'
    end
end

function __forge_maybe_refresh_prompt_cache --on-event fish_prompt --description 'Refresh the Forge right-prompt cache only when shell state changes'
    set -l signature (__forge_prompt_cache_signature)

    if test "$_FORGE_RPROMPT_SIGNATURE" = "$signature"
        and test "$_FORGE_RPROMPT_DIRTY" != 1
        and test "$_FORGE_RPROMPT_CACHE_READY" = 1
        return 0
    end

    __forge_refresh_prompt_cache
    set -g _FORGE_RPROMPT_SIGNATURE "$signature"
    set -g _FORGE_RPROMPT_DIRTY 0
end

function __forge_status_prompt --description 'Render the cached Forge status for fish_right_prompt'
    __forge_maybe_refresh_prompt_cache
    __forge_render_zsh_rprompt "$_FORGE_RPROMPT_ZSH_CACHE"
end

function __forge_title_command --argument current_command --description 'Return the title command, overriding deferred : prompts with the original buffer'
    if test "$_FORGE_PENDING_EXEC" = 1
        and set -q _FORGE_DEFERRED_EXEC_HISTORY
        and test -n "$_FORGE_DEFERRED_EXEC_HISTORY"
        printf '%s' "$_FORGE_DEFERRED_EXEC_HISTORY"
        return 0
    end

    if test -n "$current_command"
        printf '%s' "$current_command"
        return 0
    end

    return 1
end

function : --description 'Run Forge default : prompt through normal Fish command execution'
    # The keybinding path rewrites ":" into a real command so Fish redraw/history match normal command execution.
    if test "$_FORGE_PENDING_EXEC" = 1
        _forge_run_deferred
        return $status
    end

    if test (count $argv) -eq 0
        return 0
    end

    _forge_dispatch_default '' (string join ' ' -- $argv)
    if test "$_FORGE_PENDING_EXEC" = 1
        _forge_run_deferred
        return $status
    end

    return 0
end

function __forge_is_wrapped_right_prompt --argument function_name --description 'Check whether a prompt function is the Forge wrapper'
    if not functions -q "$function_name"
        return 1
    end

    set -l function_definition (functions "$function_name" | string collect)
    string match -q '*__forge_status_prompt*' -- "$function_definition"
end

function __forge_restore_saved_right_prompt --description 'Restore the saved pre-Forge fish_right_prompt definition when available'
    if test -z "$_FORGE_ORIG_RIGHT_PROMPT_DEF"
        return 1
    end

    functions --erase fish_right_prompt 2>/dev/null
    eval "$_FORGE_ORIG_RIGHT_PROMPT_DEF" 2>/dev/null
end

function __forge_is_wrapped_title --argument function_name --description 'Check whether a title function is the Forge wrapper'
    if not functions -q "$function_name"
        return 1
    end

    set -l function_definition (functions "$function_name" | string collect)
    string match -q '*__forge_title_command*' -- "$function_definition"
end

function __forge_restore_saved_title --description 'Restore the saved pre-Forge fish_title definition when available'
    if test -z "$_FORGE_ORIG_TITLE_DEF"
        return 1
    end

    functions --erase fish_title 2>/dev/null
    eval "$_FORGE_ORIG_TITLE_DEF" 2>/dev/null
end

function _forge_install_right_prompt --description 'Wrap fish_right_prompt and append Forge status'
    if __forge_is_wrapped_right_prompt __orig_fish_right_prompt
        functions --erase __orig_fish_right_prompt 2>/dev/null
    end

    if __forge_is_wrapped_right_prompt fish_right_prompt
        functions --erase fish_right_prompt 2>/dev/null
        __forge_restore_saved_right_prompt >/dev/null
    end

    if not functions -q fish_right_prompt; and test -n "$_FORGE_ORIG_RIGHT_PROMPT_DEF"
        __forge_restore_saved_right_prompt >/dev/null
    end

    if functions -q fish_right_prompt; and not functions -q __orig_fish_right_prompt
        set -g _FORGE_ORIG_RIGHT_PROMPT_DEF (functions fish_right_prompt | string collect)
        functions -c fish_right_prompt __orig_fish_right_prompt
    end

    __forge_maybe_refresh_prompt_cache

    function fish_right_prompt --description 'Wrapped right prompt with Forge status'
        set -l original_prompt ''
        if functions -q __orig_fish_right_prompt
            set original_prompt (__orig_fish_right_prompt | string collect)
        end

        set -l forge_prompt (__forge_status_prompt | string collect)

        if test -n "$original_prompt"
            printf '%s' "$original_prompt"
            if test -n "$forge_prompt"
                printf ' %s' "$forge_prompt"
            end
        else if test -n "$forge_prompt"
            printf '%s' "$forge_prompt"
        end
    end

    set -g _FORGE_THEME_LOADED 1
end

function _forge_install_title --description 'Wrap fish_title so deferred : prompts keep their original title text'
    if __forge_is_wrapped_title __orig_fish_title
        functions --erase __orig_fish_title 2>/dev/null
    end

    if __forge_is_wrapped_title fish_title
        functions --erase fish_title 2>/dev/null
        __forge_restore_saved_title >/dev/null
    end

    if not functions -q fish_title; and test -n "$_FORGE_ORIG_TITLE_DEF"
        __forge_restore_saved_title >/dev/null
    end

    if functions -q fish_title; and not functions -q __orig_fish_title
        set -g _FORGE_ORIG_TITLE_DEF (functions fish_title | string collect)
        functions -c fish_title __orig_fish_title
    end

    function fish_title --argument current_command --description 'Wrapped title with Forge deferred prompt support'
        set -l title_command (__forge_title_command "$current_command" | string collect)
        set -l title_status $status

        if functions -q __orig_fish_title
            if test $title_status -eq 0
                __orig_fish_title "$title_command"
            else
                __orig_fish_title
            end
            return $status
        end

        set -l ssh
        set -q SSH_TTY
        and set ssh "["(prompt_hostname | string sub -l 10 | string collect)"]"

        if test $title_status -eq 0
            echo -- $ssh (string sub -l 20 -- "$title_command") (prompt_pwd -d 1 -D 1)
            return 0
        end

        set -l command (status current-command)
        if test "$command" = fish
            set command
        end
        echo -- $ssh (string sub -l 20 -- "$command") (prompt_pwd -d 1 -D 1)
    end
end

function _forge_uninstall_restore_prompt --description 'Restore the original fish_right_prompt after Forge uninstall'
    functions --erase fish_right_prompt 2>/dev/null

    if functions -q __orig_fish_right_prompt
        functions -c __orig_fish_right_prompt fish_right_prompt
        functions --erase __orig_fish_right_prompt
    else if test -n "$_FORGE_ORIG_RIGHT_PROMPT_DEF"
        __forge_restore_saved_right_prompt >/dev/null
    end

    set --erase _FORGE_THEME_LOADED
end

function _forge_uninstall_restore_title --description 'Restore the original fish_title after Forge uninstall'
    functions --erase fish_title 2>/dev/null

    if functions -q __orig_fish_title
        functions -c __orig_fish_title fish_title
        functions --erase __orig_fish_title
    else if test -n "$_FORGE_ORIG_TITLE_DEF"
        __forge_restore_saved_title >/dev/null
    end
end

function _forge_uninstall_restore_bindings --description 'Restore Fish bindings after Forge uninstall'
    if set -q fish_key_bindings; and test -n "$fish_key_bindings"; and functions -q "$fish_key_bindings"
        $fish_key_bindings
    else if functions -q fish_default_key_bindings
        fish_default_key_bindings
    end

    if functions -q fish_user_key_bindings
        fish_user_key_bindings
    end
end

function _forge_install_colon_completions --description 'Refresh synthetic :command functions used by Fish native completion'
    if functions -q _forge_refresh_colons
        _forge_refresh_colons
    end
end

function _forge_install_bindings --description 'Install Forge key bindings for the active Fish binding mode'
    if not status is-interactive
        return 0
    end

    bind --mode default \r _forge_accept
    bind --mode default \n _forge_accept
    bind --mode default \t _forge_complete

    if contains -- insert (bind --list-modes 2>/dev/null)
        bind --mode insert \r _forge_accept
        bind --mode insert \n _forge_accept
        bind --mode insert \t _forge_complete
    end
end

function _forge_activate_current_session --description 'Activate Forge prompt and bindings in the current interactive Fish session'
    if not status is-interactive
        return 0
    end

    _forge_install_bindings
    _forge_install_colon_completions
    _forge_install_right_prompt
    _forge_install_title

    functions --erase _forge_install_prompt_on_prompt 2>/dev/null
    function _forge_install_prompt_on_prompt --on-event fish_prompt --description 'Reinstall Forge right prompt after prompt initialization settles'
        _forge_install_right_prompt
        _forge_install_title
        functions --erase _forge_install_prompt_on_prompt
    end
end

function _forge_install_current_session --on-event forge_install --description 'Activate Forge immediately after Fisher install'
    _forge_activate_current_session
end

function _forge_update_current_session --on-event forge_update --description 'Refresh Forge immediately after Fisher update'
    _forge_activate_current_session
end

function _forge_uninstall --on-event forge_uninstall --description 'Clean up Forge plugin state from the current Fish session'
    if status is-interactive
        bind --user --erase --mode default \r \n \t 2>/dev/null

        if contains -- insert (bind --list-modes 2>/dev/null)
            bind --user --erase --mode insert \r \n \t 2>/dev/null
        end

        functions --erase _forge_refresh_bindings _forge_install_bindings_on_prompt _forge_install_prompt_on_prompt _forge_install_current_session _forge_update_current_session 2>/dev/null
        _forge_uninstall_restore_bindings
        _forge_uninstall_restore_prompt
        _forge_uninstall_restore_title
    end

    if set -q _FORGE_COLON_COMMAND_NAMES
        for command_name in $_FORGE_COLON_COMMAND_NAMES
            complete -c ":$command_name" -e 2>/dev/null
            functions --erase ":$command_name" 2>/dev/null
        end
    end

    set --erase _FORGE_COLON_COMMAND_NAMES

    for var in (set --names | string match --entire --regex '^_FORGE_.*$')
        set --erase $var
    end

    functions --erase __forge_map_zsh_color __forge_emit_prompt_segment __forge_render_zsh_rprompt __forge_prompt_cache_signature __forge_refresh_prompt_cache __forge_maybe_refresh_prompt_cache __forge_status_prompt __forge_title_command __forge_is_wrapped_right_prompt __forge_restore_saved_right_prompt __forge_is_wrapped_title __forge_restore_saved_title : 2>/dev/null
    functions --erase (functions -a | string match --entire --regex '^_forge_.*$') 2>/dev/null
end

if set -q FORGE_BIN; and test -n "$FORGE_BIN"
    set -g _FORGE_BIN "$FORGE_BIN"
else if command -q forge
    set -g _FORGE_BIN (command -v forge)
else
    set -g _FORGE_BIN forge
end

set -g _FORGE_DELIMITER '\\s\\s+'

if set -q FORGE_MAX_COMMIT_DIFF; and test -n "$FORGE_MAX_COMMIT_DIFF"
    set -g _FORGE_MAX_COMMIT_DIFF "$FORGE_MAX_COMMIT_DIFF"
else
    set -g _FORGE_MAX_COMMIT_DIFF 100000
end

set -g _FORGE_PREVIEW_WINDOW '--preview-window=bottom:75%:wrap:border-sharp'

if command -q fdfind
    set -g _FORGE_FD_CMD (command -v fdfind)
else if command -q fd
    set -g _FORGE_FD_CMD (command -v fd)
else
    set -g _FORGE_FD_CMD fd
end

if command -q bat
    set -g _FORGE_CAT_CMD 'bat --color=always --style=numbers,changes --line-range=:500'
else
    set -g _FORGE_CAT_CMD cat
end

set -g _FORGE_COMMANDS ''
set -g _FORGE_COLON_COMMAND_NAMES
set -g _FORGE_RPROMPT_ZSH_CACHE ''
set -g _FORGE_RPROMPT_SIGNATURE ''
set -g _FORGE_RPROMPT_CACHE_READY 0
set -g _FORGE_RPROMPT_DIRTY 1
set -g _FORGE_OUTPUT_MODE ''
set -g _FORGE_CONVERSATION_ID ''
set -g _FORGE_ACTIVE_AGENT ''
set -g _FORGE_PENDING_EXEC 0
set -g _FORGE_PENDING_EXEC_ARGV
set -g _FORGE_DEFERRED_EXEC_ERASE_WRAPPER 0
set -g _FORGE_SKIP_BLANK_LINE 0
set -g _FORGE_PREVIOUS_CONVERSATION_ID ''
set -g _FORGE_SESSION_MODEL ''
set -g _FORGE_SESSION_PROVIDER ''
set -g _FORGE_SESSION_REASONING_EFFORT ''
set -g _FORGE_ORIG_RIGHT_PROMPT_DEF ''
set -g _FORGE_ORIG_TITLE_DEF ''
set -g _FORGE_DEFERRED_EXEC_HISTORY ''
set -g _FORGE_DEFERRED_EXEC_WRAPPER_COMMAND ''
set -g _FORGE_HAS_COMMANDLINE_SEARCH_FIELD ''

if status is-interactive
    function _forge_refresh_bindings --on-variable fish_key_bindings --description 'Reinstall Forge bindings after Fish key binding changes'
        _forge_install_bindings
        _forge_install_colon_completions
    end

    function _forge_install_bindings_on_prompt --on-event fish_prompt --description 'Install Forge bindings once after interactive startup'
        _forge_install_bindings
        _forge_install_colon_completions
        functions --erase _forge_install_bindings_on_prompt
    end

    _forge_activate_current_session
end

set -g _FORGE_PLUGIN_LOADED 1
