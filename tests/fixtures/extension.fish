set -g FORGE_TEST_FIXTURES_DIR (path dirname (status filename))
set -g FORGE_TESTS_DIR (path dirname $FORGE_TEST_FIXTURES_DIR)
set -g FORGE_TEST_REPO_ROOT (path dirname $FORGE_TESTS_DIR)

function forge_test_bootstrap
    if not contains -- "$FORGE_TEST_REPO_ROOT/functions" $fish_function_path
        set -gx fish_function_path "$FORGE_TEST_REPO_ROOT/functions" $fish_function_path
    end

    set -gx FORGE_BIN "$FORGE_TEST_REPO_ROOT/tests/bin/forge-stub"

    if set -q _FORGE_PLUGIN_LOADED
        if functions -q _forge_uninstall
            _forge_uninstall
        else
            for var in (set --names | string match --entire --regex '^_FORGE_.*$')
                set --erase $var
            end
        end
    end

    source "$FORGE_TEST_REPO_ROOT/conf.d/forge.fish"
    set -g _FORGE_BIN "$FORGE_BIN"

    for function_file in "$FORGE_TEST_REPO_ROOT"/functions/*.fish
        source "$function_file"
    end
end

function forge_test_setup_tmpdir
    set -gx FORGE_TEST_TMPDIR (mktemp -d)
    set -gx FORGE_STUB_LOG_PATH "$FORGE_TEST_TMPDIR/calls.jsonl"
end

function forge_test_cleanup
    if set -q FORGE_TEST_TMPDIR; and test -d "$FORGE_TEST_TMPDIR"
        rm -rf "$FORGE_TEST_TMPDIR"
    end

    set -e FORGE_TEST_TMPDIR
    set -e FORGE_STUB_LOG_PATH
    set -e FORGE_STUB_WORKSPACE_INFO_STATUS
    set -e FORGE_SYNC_ENABLED
end

function forge_test_reset
    set -g _FORGE_COMMANDS ""
    set -g _FORGE_CONVERSATION_ID ""
    set -g _FORGE_ACTIVE_AGENT ""
    set -g _FORGE_PREVIOUS_CONVERSATION_ID ""
    set -g _FORGE_SESSION_MODEL ""
    set -g _FORGE_SESSION_PROVIDER ""
    set -g _FORGE_SESSION_REASONING_EFFORT ""
    set -g _FORGE_RPROMPT_ZSH_CACHE ""
    set -g _FORGE_RPROMPT_SIGNATURE ""
    set -g _FORGE_RPROMPT_CACHE_READY 0
    set -g _FORGE_RPROMPT_DIRTY 1
    set -g _FORGE_OUTPUT_MODE ""
    set -g _FORGE_THEME_LOADED ""
    set -g _FORGE_ORIG_RIGHT_PROMPT_DEF ""
    set -g _FORGE_ORIG_TITLE_DEF ""
    set -g _FORGE_DEFERRED_EXEC_HISTORY ""
    set -g _FORGE_DEFERRED_EXEC_ERASE_WRAPPER ""
    set -g _FORGE_DEFERRED_EXEC_WRAPPER_COMMAND ""
    set -g _FORGE_HAS_COMMANDLINE_SEARCH_FIELD ""

    set -e FORGE_ACTIVE
    set -e FORGE_MODEL
    set -e FORGE_CTX_USED
    set -e FORGE_CTX_MAX
    set -e FORGE_STUB_RPROMPT_RAW
    set -e FORGE_STUB_DEFAULT_MODEL
    set -e FORGE_STUB_REASONING_EFFORT

    if set -q FORGE_STUB_LOG_PATH
        rm -f "$FORGE_STUB_LOG_PATH" 2>/dev/null
    end

    set -e FORGE_STUB_WORKSPACE_INFO_STATUS
    set -e FORGE_SYNC_ENABLED
end

function forge_test_fixture_text --argument file_name
    string collect < "$FORGE_TEST_FIXTURES_DIR/$file_name"
end

function forge_test_prompt_info
    if functions -q __forge_status_prompt
        __forge_status_prompt
    end
end

function forge_test_fail --argument message
    printf 'FAIL: %s\n' "$message" >&2
    return 1
end

function forge_test_assert_eq --argument expected actual message
    if test "$expected" != "$actual"
        printf 'FAIL: %s\nexpected: %s\nactual:   %s\n' "$message" "$expected" "$actual" >&2
        return 1
    end
end

function forge_test_assert_contains --argument needle haystack message
    if not string match -q "*$needle*" -- "$haystack"
        printf 'FAIL: %s\nneedle: %s\nhaystack: %s\n' "$message" "$needle" "$haystack" >&2
        return 1
    end
end

function forge_test_assert_log_python --argument expression message
    if not test -f "$FORGE_STUB_LOG_PATH"
        printf 'FAIL: %s\nmissing log file: %s\n' "$message" "$FORGE_STUB_LOG_PATH" >&2
        return 1
    end

    python3 -c 'import json, sys
path, expression, message = sys.argv[1:4]
with open(path, encoding="utf-8") as handle:
    entries = [json.loads(line) for line in handle if line.strip()]
safe_builtins = {"len": len, "any": any, "all": all}
if not eval(expression, {"__builtins__": safe_builtins}, {"entries": entries}):
    print(f"FAIL: {message}", file=sys.stderr)
    print(f"expression: {expression}", file=sys.stderr)
    print(json.dumps(entries, indent=2, ensure_ascii=False), file=sys.stderr)
    sys.exit(1)
' "$FORGE_STUB_LOG_PATH" "$expression" "$message"
end

function forge_test_wait_for_log_entries --argument expected_count
    for attempt in (seq 1 40)
        if test -f "$FORGE_STUB_LOG_PATH"
            set -l actual_count (python3 -c 'import sys
path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    print(sum(1 for line in handle if line.strip()))
' "$FORGE_STUB_LOG_PATH")
            if test "$actual_count" -ge "$expected_count"
                return 0
            end
        end
        sleep 0.05
    end

    printf 'FAIL: timed out waiting for %s log entries\n' "$expected_count" >&2
    return 1
end
