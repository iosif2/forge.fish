#!/usr/bin/env fish

set -l test_dir (path dirname (status filename))
source "$test_dir/fixtures/extension.fish"

forge_test_bootstrap
forge_test_setup_tmpdir
set -l ok_text (forge_test_fixture_text ok.txt)

function test_doctor_wrapper
    forge_test_reset

    set -l output (_forge_action_doctor | string collect)
    forge_test_assert_contains 'Forge Fish Doctor' "$output" 'doctor should print the shell-native doctor header'
    or return 1
    forge_test_assert_contains 'Summary' "$output" 'doctor should print the final summary section'
    or return 1

    if test -f "$FORGE_STUB_LOG_PATH"
        forge_test_fail 'doctor should not call the forge binary'
        return 1
    end
end

function test_keyboard_wrapper
    forge_test_reset

    set -l output (_forge_action_keyboard | string collect)
    forge_test_assert_contains "$ok_text" "$output" 'keyboard should return the happy-path fixture output'
    or return 1
    forge_test_assert_log_python 'len(entries) == 1 and entries[0]["argv"] == ["fish", "keyboard"]' 'keyboard should call fish keyboard directly'
    or return 1
end

function test_conversation_helpers_are_available_after_bootstrap
    forge_test_reset
    set -g _FORGE_CONVERSATION_ID 'cid-old'

    _forge_clear_conversation
    forge_test_assert_eq 'cid-old' "$_FORGE_PREVIOUS_CONVERSATION_ID" 'clear helper should be available and save the previous conversation'
    or return 1
    forge_test_assert_eq '' "$_FORGE_CONVERSATION_ID" 'clear helper should be available and clear the active conversation'
    or return 1

    _forge_switch_conversation 'cid-new'
    forge_test_assert_eq 'cid-new' "$_FORGE_CONVERSATION_ID" 'switch helper should be available and set the active conversation'
    or return 1
end

function test_conversation_helpers_are_available_when_conf_is_sourced_directly
    set -l probe_output (fish -ic '
        set -l repo_root (path resolve .)
        if not contains -- "$repo_root/functions" $fish_function_path
            set -gx fish_function_path "$repo_root/functions" $fish_function_path
        end
        set -gx FORGE_BIN "$repo_root/tests/bin/forge-stub"
        if set -q _FORGE_PLUGIN_LOADED
            if functions -q _forge_uninstall
                _forge_uninstall
            else
                for var in (set --names | string match --entire --regex "^_FORGE_.*")
                    set --erase $var
                end
            end
        end
        source "$repo_root/conf.d/forge.fish"
        set -g _FORGE_BIN "$FORGE_BIN"
        set -g _FORGE_CONVERSATION_ID cid-old
        _forge_clear_conversation
        _forge_switch_conversation cid-new
        printf "CID:%s PREV:%s\n" "$_FORGE_CONVERSATION_ID" "$_FORGE_PREVIOUS_CONVERSATION_ID"
    ' 2>/dev/null | string collect)

    forge_test_assert_contains 'CID:cid-new' "$probe_output" 'conversation helpers should still be available when conf.d is sourced directly'
    or return 1
    forge_test_assert_contains 'PREV:cid-old' "$probe_output" 'directly sourced conf.d should preserve the previous conversation state via the helper bundle'
    or return 1
end

function test_colon_completion_uses_native_completions
    forge_test_reset
    _forge_refresh_colon_command_functions

    set -l candidates (complete -C ':n' | string collect)
    forge_test_assert_contains ':new' "$candidates" 'colon completion should offer the no-space :new command'
    or return 1
    forge_test_assert_contains 'Start new conversation' "$candidates" 'colon completion should expose command descriptions'
    or return 1
end

function test_accept_line_supports_colon_command_without_space
    forge_test_reset

    set -l probe_output (fish -ic '
        source tests/fixtures/extension.fish
        forge_test_bootstrap
        forge_test_reset
        set -g _FORGE_CONVERSATION_ID cid-old
        commandline -r ":new"
        _forge_accept_line >/dev/null 2>/dev/null
        printf "CID:%s PREV:%s\n" "$_FORGE_CONVERSATION_ID" "$_FORGE_PREVIOUS_CONVERSATION_ID"
    ' 2>/dev/null | string collect)

    forge_test_assert_contains 'CID:' "$probe_output" 'interactive probe should emit conversation state'
    or return 1
    forge_test_assert_contains 'PREV:cid-old' "$probe_output" 'colon command without space should preserve previous conversation'
    or return 1
    if string match -q '*CID:cid-old*' -- "$probe_output"
        forge_test_fail 'colon command without space should not leave the old conversation active'
        return 1
    end
end

function test_accept_line_rejects_unknown_colon_command_without_space
    forge_test_reset

    set -l probe_output (fish -ic '
        source tests/fixtures/extension.fish
        forge_test_bootstrap
        forge_test_reset
        commandline -r ":hi"
        set -l accept_output (_forge_accept_line 2>&1 | string collect)
        set -l normalized_output (string replace -ra "\\e\\[[0-9;?]*[ -/]*[@-~]" "" -- "$accept_output")
        set -l pending ""
        if set -q _FORGE_PENDING_EXEC
            set pending "$_FORGE_PENDING_EXEC"
        end
        printf "PENDING:%s\nOUT-BEGIN\n%s\nOUT-END\nBUFFER:%s\n" "$pending" "$normalized_output" (commandline)
    ' 2>/dev/null | string collect)

    forge_test_assert_contains 'PENDING:' "$probe_output" 'unknown colon commands should report pending state'
    or return 1
    if string match -q '*PENDING:1*' -- "$probe_output"
        forge_test_fail 'unknown colon commands without a space should not queue deferred execution'
        return 1
    end
    forge_test_assert_contains "Command 'hi'" "$probe_output" 'unknown colon commands without a space should stay on the command path'
    or return 1
    forge_test_assert_contains 'not found' "$probe_output" 'unknown colon commands without a space should report a missing command'
    or return 1
end

function test_accept_line_treats_space_prefixed_colon_text_as_prompt_text
    forge_test_reset

    set -l probe_output (fish -ic '
        source tests/fixtures/extension.fish
        forge_test_bootstrap
        forge_test_reset
        set -g _FORGE_CONVERSATION_ID cid-stub-001
        commandline -r ": hi"
        _forge_accept_line >/dev/null 2>/dev/null
        printf "PENDING:%s\nARGV:%s\nHISTORY:%s\nBUFFER:%s\n" "$_FORGE_PENDING_EXEC" (string escape --style=script -- (string join "|" -- $_FORGE_PENDING_EXEC_ARGV)) (string escape --style=script -- "$_FORGE_DEFERRED_EXEC_HISTORY") (string escape --style=script -- (commandline))
    ' 2>/dev/null | string collect)

    forge_test_assert_contains 'PENDING:1' "$probe_output" 'space-prefixed colon text should queue deferred execution'
    or return 1
    forge_test_assert_contains "ARGV:'-p|hi|--cid|cid-stub-001'" "$probe_output" 'space-prefixed colon text should become plain prompt text argv'
    or return 1
    forge_test_assert_contains "HISTORY:': hi'" "$probe_output" 'space-prefixed colon text should preserve the raw colon buffer for history repair'
    or return 1
    forge_test_assert_contains 'BUFFER::' "$probe_output" 'space-prefixed colon text should hand off through the public colon wrapper'
    or return 1
end

function test_accept_line_preserves_punctuation_prompt_text
    forge_test_reset

    set -l probe_output (fish -ic '
        source tests/fixtures/extension.fish
        forge_test_bootstrap
        forge_test_reset
        set -g _FORGE_CONVERSATION_ID cid-stub-001
        commandline -r ": (hello) [world]"
        _forge_accept_line >/dev/null 2>/dev/null
        printf "PENDING:%s\nARGV:%s\nHISTORY:%s\nBUFFER:%s\n" "$_FORGE_PENDING_EXEC" (string join "|" -- $_FORGE_PENDING_EXEC_ARGV | string collect | string escape --style=script --) (string escape --style=script -- "$_FORGE_DEFERRED_EXEC_HISTORY") (commandline | string collect | string escape --style=script --)
    ' 2>/dev/null | string collect)

    forge_test_assert_contains 'PENDING:1' "$probe_output" 'punctuation colon prompts should queue deferred execution'
    or return 1
    forge_test_assert_contains "ARGV:'-p|(hello) [world]|--cid|cid-stub-001'" "$probe_output" 'punctuation colon prompts should preserve punctuation in queued argv'
    or return 1
    forge_test_assert_contains "HISTORY:': (hello) [world]'" "$probe_output" 'punctuation colon prompts should preserve the raw buffer for history repair'
    or return 1
    forge_test_assert_contains 'BUFFER::' "$probe_output" 'punctuation colon prompts should hand off through the public colon wrapper'
    or return 1
end

function test_commit_matches_zsh_and_clears_commandline
    forge_test_reset
    set -gx FORGE_STUB_COMMIT_MESSAGE 'feat: add tests'

    set -l probe_output (fish -ic '
        source tests/fixtures/extension.fish
        forge_test_bootstrap
        forge_test_reset
        set -gx FORGE_STUB_COMMIT_MESSAGE "feat: add tests"
        commandline -r ":commit"
        commandline -C 7
        _forge_accept_line
        printf "BUFFER:%s\n" (commandline)
    ' 2>/dev/null | string collect)

    forge_test_assert_contains 'BUFFER:' "$probe_output" 'commit should leave the prompt available after reset'
    or return 1
    if string match -q '*BUFFER:git commit*' -- "$probe_output"
        forge_test_fail 'commit should match zsh and not populate the prompt with a git commit command'
        return 1
    end
    forge_test_assert_log_python 'len(entries) == 1 and entries[0]["argv"] == ["commit", "--max-diff", "100000"]' 'commit should call the forge binary without preview to match zsh behavior'
    or return 1
end

function test_config_reload_clears_all_session_overrides
    forge_test_reset
    set -g _FORGE_SESSION_MODEL 'gpt-5'
    set -g _FORGE_SESSION_PROVIDER 'openai'
    set -g _FORGE_SESSION_REASONING_EFFORT 'high'

    _forge_action_config_reload >/dev/null

    forge_test_assert_eq '' "$_FORGE_SESSION_MODEL" 'config-reload should clear the session model override'
    or return 1
    forge_test_assert_eq '' "$_FORGE_SESSION_PROVIDER" 'config-reload should clear the session provider override'
    or return 1
    forge_test_assert_eq '' "$_FORGE_SESSION_REASONING_EFFORT" 'config-reload should clear the session reasoning override'
    or return 1
end

function test_model_reset_dispatch_matches_zsh_config_reload_behavior
    set -l probe_output (fish -ic '
        source tests/fixtures/extension.fish
        forge_test_bootstrap
        forge_test_reset
        set -g _FORGE_SESSION_MODEL gpt-5
        set -g _FORGE_SESSION_PROVIDER openai
        set -g _FORGE_SESSION_REASONING_EFFORT medium
        commandline -r ":model-reset"
        _forge_accept_line >/dev/null 2>/dev/null
        printf "MODEL:%s PROVIDER:%s EFFORT:%s\n" "$_FORGE_SESSION_MODEL" "$_FORGE_SESSION_PROVIDER" "$_FORGE_SESSION_REASONING_EFFORT"
    ' 2>/dev/null | string collect)

    forge_test_assert_contains 'MODEL:' "$probe_output" 'model-reset dispatch should report the cleared session state'
    or return 1
    forge_test_assert_contains 'MODEL: PROVIDER: EFFORT:' "$probe_output" 'model-reset should clear all session overrides through the accept-line dispatch path'
    or return 1
end

function test_reasoning_effort_sets_session_override
    forge_test_reset
    set -g _FORGE_SESSION_REASONING_EFFORT 'low'

    function _forge_fzf
        printf 'medium'
    end

    _forge_action_reasoning_effort >/dev/null
    functions --erase _forge_fzf

    forge_test_assert_eq 'medium' "$_FORGE_SESSION_REASONING_EFFORT" 'reasoning-effort should update the session override from the picker selection'
    or return 1
end

function test_config_reasoning_effort_calls_binary
    forge_test_reset
    set -gx FORGE_STUB_REASONING_EFFORT 'low'

    function _forge_fzf
        printf 'high'
    end

    _forge_action_config_reasoning_effort >/dev/null
    functions --erase _forge_fzf

    forge_test_assert_log_python 'len(entries) == 2 and entries[0]["argv"] == ["config", "get", "reasoning-effort"] and entries[1]["argv"] == ["config", "set", "reasoning-effort", "high"]' 'config-reasoning-effort should read the current value and persist the new selection through the forge binary'
    or return 1
end

function test_accept_line_uses_execute_handoff_after_interactive_exec
    forge_test_reset

    set -l probe_output (fish -ic '
        source tests/fixtures/extension.fish
        forge_test_bootstrap
        forge_test_reset
        set -g _FORGE_CONVERSATION_ID cid-stub-001
        function _forge_exec_interactive
            set -g _FORGE_POST_OUTPUT_PADDING 1
            set -g _FORGE_RPROMPT_DIRTY 1
        end
        function _forge_reset
            set -g __forge_reset_called 1
        end
        function commandline
            switch "$argv[1]"
                case -r
                    set -g __forge_commandline_replace "$argv[2]"
                    builtin commandline $argv
                    return $status
                case -f
                    set -g __forge_commandline_function "$argv[2]"
                    builtin commandline $argv
                    return $status
                case "*"
                    builtin commandline $argv
                    return $status
            end
        end
        commandline -r ": hi"
        commandline -C 4
        _forge_accept_line >/dev/null 2>/dev/null
        printf "RESET:%s EXEC:%s BLANK:%s BUFFER:%s\n" \
            (set -q __forge_reset_called; and echo yes; or echo no) \
            "$__forge_commandline_function" \
            "$_FORGE_SKIP_BLANK_LINE" \
            "$__forge_commandline_replace"
    ' 2>/dev/null | string collect)

    forge_test_assert_contains 'RESET:no' "$probe_output" 'interactive : prompt dispatch should bypass the normal reset path when visible output is tracked'
    or return 1
    forge_test_assert_contains 'EXEC:execute' "$probe_output" 'interactive : prompt dispatch should hand prompt redraw back through execute'
    or return 1
    forge_test_assert_contains 'BLANK:0' "$probe_output" 'interactive : prompt dispatch should let the blank-line erase hook consume the execute marker before control returns'
    or return 1
    forge_test_assert_contains 'BUFFER:' "$probe_output" 'interactive : prompt dispatch should clear the buffer before execute redraw'
    or return 1
end

function test_exec_marks_padding_for_following_reset
    forge_test_reset

    _forge_exec fish keyboard >/dev/null

    forge_test_assert_eq '1' "$_FORGE_POST_OUTPUT_PADDING" 'binary-backed colon actions should mark prompt padding before reset'
    or return 1
end

function test_deferred_exec_repairs_history_with_original_prompt
    forge_test_reset

    if not command -q script
        return 0
    end

    set -l history_root "$FORGE_TEST_TMPDIR/pty-history"
    set -l isolated_home "$FORGE_TEST_TMPDIR/pty-home"
    set -l isolated_config "$FORGE_TEST_TMPDIR/pty-config"
    set -l history_name forgehistorytest
    set -l history_file "$history_root/fish/$history_name"_history
    set -l stub_log "$FORGE_TEST_TMPDIR/pty-calls.jsonl"
    set -l transcript_file "$FORGE_TEST_TMPDIR/pty-transcript.txt"
    set -l fixture_path "$FORGE_TEST_REPO_ROOT/tests/fixtures/extension.fish"
    mkdir -p "$history_root" "$isolated_home" "$isolated_config"

    set -l session_input "set -gx FORGE_STUB_LOG_PATH \"$stub_log\"
set -gx FORGE_SYNC_ENABLED false
source \"$fixture_path\"
forge_test_bootstrap
forge_test_reset
set -g _FORGE_CONVERSATION_ID cid-stub-001
: hello world
builtin history save
exit
"

    printf '%s' "$session_input" | env HOME="$isolated_home" XDG_CONFIG_HOME="$isolated_config" XDG_DATA_HOME="$history_root" fish_history="$history_name" TERM=dumb script -qec 'fish -i' "$transcript_file" >/dev/null 2>&1
    or begin
        forge_test_fail 'pty history probe should complete successfully'
        return 1
    end

    if not test -f "$history_file"
        forge_test_fail 'pty history probe should create an isolated fish history file'
        return 1
    end

    set -l history_output (string collect < "$history_file")
    forge_test_assert_contains '- cmd: : hello world' "$history_output" 'deferred : prompt execution should preserve the original prompt in fish history'
    or return 1
    if string match -q '*_forge_deferred_exec*' -- "$history_output"
        forge_test_fail 'deferred : prompt execution should not leave the helper command in fish history'
        return 1
    end

    if not test -f "$transcript_file"
        forge_test_fail 'pty history probe should capture the terminal transcript'
        return 1
    end

    set -l transcript_output (string collect < "$transcript_file")
    forge_test_assert_contains ': hello world' "$transcript_output" 'deferred : prompt execution should keep the original prompt visible in the terminal transcript'
    or return 1
    if string match -q '*_forge_deferred_exec*' -- "$transcript_output"
        forge_test_fail 'deferred : prompt execution should not expose the helper name in the terminal transcript'
        return 1
    end
    forge_test_assert_contains 'interactive prompt ok cid=cid-stub-001 input=hello world' "$transcript_output" 'deferred : prompt execution should still print Forge output'
    or return 1

    set -gx FORGE_STUB_LOG_PATH "$stub_log"
    forge_test_assert_log_python 'any(e["raw_argv"] == ["--agent", "forge", "-p", "hello world", "--cid", "cid-stub-001"] for e in entries)' 'deferred : prompt execution should still run forge through the queued deferred argv'
    or return 1
end

function test_at_completion_wraps_selected_path

    set -l probe_output (fish -ic '
        source tests/fixtures/extension.fish
        forge_test_bootstrap
        forge_test_reset
        function _forge_fzf_from_stdin
            set -g _FORGE_FZF_SELECTION "plans/example.md"
        end
        commandline -r "@"
        commandline -C 1
        _forge_completion
        printf "BUFFER:%s\n" (commandline)
    ' 2>/dev/null | string collect)

    forge_test_assert_contains 'BUFFER:@[plans/example.md]' "$probe_output" 'at completion should wrap the selected path in @[...] syntax'
    or return 1
end

function test_fzf_wrappers_force_posix_shell_for_preview_commands
    set -l repo_root (pwd)
    set -l fzf_definition (string collect < "$repo_root/functions/_forge_fzf.fish")
    forge_test_assert_contains 'env SHELL=/bin/sh fzf' "$fzf_definition" 'fzf wrapper should force a POSIX shell so preview commands match the zsh contract'
    or return 1

    set -l tty_definition (string collect < "$repo_root/functions/_forge_fzf_from_stdin.fish")
    forge_test_assert_contains 'SHELL=/bin/sh' "$tty_definition" 'tty-backed fzf wrapper should also force a POSIX shell for preview commands'
    or return 1
end

function test_reset_adds_single_separator_for_visible_output_handoff
    forge_test_reset

    set -g _FORGE_POST_INTERACTIVE_NEWLINE 1
    set -g _FORGE_POST_OUTPUT_PADDING 1
    set -l reset_capture "$FORGE_TEST_TMPDIR/reset-padding.bin"

    function commandline
        if test "$argv[1]" = '-r'
            set -g __forge_reset_cleared 1
        end
        if test "$argv[1]" = '-f'
            set -g __forge_reset_repaint "$argv[2]"
        end
        return 0
    end

    begin
        _forge_reset
    end >"$reset_capture"

    functions --erase commandline

    python3 -c 'import pathlib, sys
path = pathlib.Path(sys.argv[1])
data = path.read_bytes()
expected = b"\r\n"
if data != expected:
    print("FAIL: reset should emit exactly one separator line after visible Forge output", file=sys.stderr)
    print(f"expected bytes: {expected!r}", file=sys.stderr)
    print(f"actual bytes:   {data!r}", file=sys.stderr)
    sys.exit(1)
' "$reset_capture"
    or return 1

    if not set -q __forge_reset_cleared
        forge_test_fail 'visible-output reset should clear the commandline after the separator'
        return 1
    end
    if set -q __forge_reset_repaint
        forge_test_fail 'visible-output reset should not force an immediate repaint'
        return 1
    end

    set --erase __forge_reset_cleared __forge_reset_repaint

    if set -q _FORGE_POST_INTERACTIVE_NEWLINE; and test -n "$_FORGE_POST_INTERACTIVE_NEWLINE"
        forge_test_fail 'visible-output reset should clear the post-interactive newline flag'
        return 1
    end
    if set -q _FORGE_POST_OUTPUT_PADDING; and test -n "$_FORGE_POST_OUTPUT_PADDING"
        forge_test_fail 'visible-output reset should clear the post-output padding flag'
        return 1
    end
end

function test_rprompt_falls_back_to_default_model_without_session_override
    forge_test_reset
    set -g _FORGE_ACTIVE_AGENT 'forge'
    set -gx FORGE_STUB_DEFAULT_MODEL 'gpt-5-default'

    set -l output (forge_test_prompt_info | string collect)
    forge_test_assert_contains 'gpt-5-default' "$output" 'rprompt should show the default model when no session override is set'
    or return 1
    forge_test_assert_log_python 'len(entries) == 1 and entries[0]["argv"] == ["zsh", "rprompt"]' 'rprompt should query zsh rprompt once while using the default model'
    or return 1
end

function test_rprompt_uses_cached_zsh_output
    forge_test_reset
    set -g _FORGE_ACTIVE_AGENT 'sage'
    set -g _FORGE_SESSION_MODEL 'gpt-5'
    set -gx FORGE_STUB_RPROMPT_RAW ' %B%F{15}SAGE%f%b %B%F{15}1.5k%f%b %B%F{2}$0.01%f%b %F{134}gpt-5%f'

    set -l first_output (forge_test_prompt_info | string collect)
    set -l second_output (forge_test_prompt_info | string collect)

    forge_test_assert_contains 'SAGE' "$first_output" 'rprompt should include the parsed active agent label'
    or return 1
    forge_test_assert_contains '1.5k' "$first_output" 'rprompt should include the parsed token count'
    or return 1
    forge_test_assert_contains 'gpt-5' "$first_output" 'rprompt should include the parsed model'
    or return 1
    forge_test_assert_contains '$0.01' "$first_output" 'rprompt should include the parsed cost'
    or return 1
    forge_test_assert_eq "$first_output" "$second_output" 'rprompt output should stay stable when serving from cache'
    or return 1
    forge_test_assert_log_python 'len(entries) == 1 and entries[0]["argv"] == ["zsh", "rprompt"]' 'rprompt rendering should fill the zsh cache only once for unchanged state'
    or return 1
end

function test_rprompt_refreshes_immediately_after_command
    forge_test_reset
    set -g _FORGE_ACTIVE_AGENT 'sage'
    set -g _FORGE_SESSION_MODEL 'gpt-5'
    set -gx FORGE_STUB_RPROMPT_RAW ' %B%F{240}SAGE%f%b %F{240}gpt-5%f'

    set -l initial_output (forge_test_prompt_info | string collect)
    forge_test_assert_contains 'gpt-5' "$initial_output" 'initial prompt should include the model'
    or return 1

    set -gx FORGE_STUB_RPROMPT_RAW ' %B%F{15}SAGE%f%b %B%F{15}2.0k%f%b %F{134}gpt-5.1%f'
    _forge_exec fish keyboard >/dev/null

    set -l refreshed_output (forge_test_prompt_info | string collect)
    forge_test_assert_contains '2.0k' "$refreshed_output" 'prompt should refresh token info immediately after command execution'
    or return 1
    forge_test_assert_contains 'gpt-5.1' "$refreshed_output" 'prompt should refresh model info immediately after command execution'
    or return 1
    forge_test_assert_log_python 'len(entries) == 3 and entries[0]["argv"] == ["zsh", "rprompt"] and entries[1]["argv"] == ["fish", "keyboard"] and entries[2]["argv"] == ["zsh", "rprompt"]' 'prompt refresh should happen again right after a command marks the cache dirty'
    or return 1
end

function test_right_prompt_reinstall_recovers_from_missing_saved_original
    forge_test_reset

    function fish_right_prompt
        printf 'BASE'
    end

    set -g _FORGE_ACTIVE_AGENT 'forge'
    set -g _FORGE_SESSION_MODEL 'gpt-5.4'
    set -gx FORGE_STUB_RPROMPT_RAW ' %B%F{240}FORGE%f%b %F{240}gpt-5.4%f'

    _forge_install_right_prompt
    functions --erase __orig_fish_right_prompt 2>/dev/null
    _forge_install_right_prompt

    set -l output (fish_right_prompt | string collect)
    forge_test_assert_contains 'BASE' "$output" 'reinstall should recover the original right prompt after the saved copy is lost'
    or return 1
    forge_test_assert_contains 'FORGE' "$output" 'reinstall should still append Forge status after recovering the original prompt'
    or return 1

    _forge_uninstall_restore_prompt
    functions --erase fish_right_prompt 2>/dev/null
end

function test_deferred_prompt_title_uses_original_colon_buffer
    forge_test_reset

    function fish_title
        set -l current_command ''
        if set -q argv[1]
            set current_command "$argv[1]"
        else
            set current_command (status current-command)
        end
        printf 'TITLE:%s\n' "$current_command"
    end

    _forge_install_title
    set -g _FORGE_PENDING_EXEC 1
    set -g _FORGE_DEFERRED_EXEC_HISTORY ': hello world'

    set -l deferred_title (fish_title ':' | string collect)
    forge_test_assert_contains 'TITLE:: hello world' "$deferred_title" 'wrapped title should use the original colon buffer during deferred execution'
    or return 1

    set -g _FORGE_PENDING_EXEC 0
    set -g _FORGE_DEFERRED_EXEC_HISTORY ''
    set -l normal_title (fish_title ':' | string collect)
    forge_test_assert_contains 'TITLE::' "$normal_title" 'wrapped title should preserve the normal command when no deferred prompt is active'
    or return 1

    _forge_uninstall_restore_title
    functions --erase fish_title 2>/dev/null
end

for test_name in \
    test_doctor_wrapper \
    test_keyboard_wrapper \
    test_conversation_helpers_are_available_after_bootstrap \
    test_conversation_helpers_are_available_when_conf_is_sourced_directly \
    test_colon_completion_uses_native_completions \
    test_accept_line_supports_colon_command_without_space \
    test_accept_line_rejects_unknown_colon_command_without_space \
    test_accept_line_treats_space_prefixed_colon_text_as_prompt_text \
    test_accept_line_preserves_punctuation_prompt_text \
    test_commit_matches_zsh_and_clears_commandline \
    test_config_reload_clears_all_session_overrides \
    test_model_reset_dispatch_matches_zsh_config_reload_behavior \
    test_reasoning_effort_sets_session_override \
    test_config_reasoning_effort_calls_binary \
    test_exec_marks_padding_for_following_reset \
    test_accept_line_uses_execute_handoff_after_interactive_exec \
    test_deferred_exec_repairs_history_with_original_prompt \
    test_at_completion_wraps_selected_path \
    test_fzf_wrappers_force_posix_shell_for_preview_commands \
    test_reset_adds_single_separator_for_visible_output_handoff \
    test_rprompt_falls_back_to_default_model_without_session_override \
    test_rprompt_uses_cached_zsh_output \
    test_rprompt_refreshes_immediately_after_command \
    test_right_prompt_reinstall_recovers_from_missing_saved_original \
    test_deferred_prompt_title_uses_original_colon_buffer
    $test_name
    or begin
        forge_test_cleanup
        exit 1
    end
end

forge_test_cleanup
printf 'test_shell_integration: ok\n'
