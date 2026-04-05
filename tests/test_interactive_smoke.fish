#!/usr/bin/env fish

set -l test_dir (path dirname (status filename))
source "$test_dir/fixtures/extension.fish"

forge_test_bootstrap
forge_test_setup_tmpdir

function _forge_start_background_update
    return 0
end

function test_default_interactive_prompt
    forge_test_reset
    set -gx FORGE_SYNC_ENABLED false

    _forge_action_default "" "Hi"
    forge_test_assert_eq "cid-stub-001" "$_FORGE_CONVERSATION_ID" "interactive default prompt should persist the generated conversation id"
    or return 1
    forge_test_assert_log_python 'len(entries) == 2 and entries[0]["argv"] == ["conversation", "new"] and entries[1]["raw_argv"] == ["--agent", "forge", "-p", "Hi", "--cid", "cid-stub-001"] and entries[1]["argv"] == ["-p", "Hi", "--cid", "cid-stub-001"]' "default interactive prompt should use forge as the implicit agent"
    or return 1
end

function test_sage_interactive_prompt
    forge_test_reset
    set -gx FORGE_SYNC_ENABLED false

    _forge_action_default sage "hello"
    forge_test_assert_eq "sage" "$_FORGE_ACTIVE_AGENT" "interactive sage prompt should activate sage"
    or return 1
    forge_test_assert_log_python 'len(entries) == 3 and entries[0]["argv"] == ["list", "commands", "--porcelain"] and entries[1]["argv"] == ["conversation", "new"] and entries[2]["raw_argv"] == ["--agent", "sage", "-p", "hello", "--cid", "cid-stub-001"]' "sage interactive prompt should prefix the explicit agent"
    or return 1
end

function test_muse_interactive_prompt
    forge_test_reset
    set -gx FORGE_SYNC_ENABLED false

    _forge_action_default muse "hello"
    forge_test_assert_eq "muse" "$_FORGE_ACTIVE_AGENT" "interactive muse prompt should activate muse"
    or return 1
    forge_test_assert_log_python 'len(entries) == 3 and entries[0]["argv"] == ["list", "commands", "--porcelain"] and entries[1]["argv"] == ["conversation", "new"] and entries[2]["raw_argv"] == ["--agent", "muse", "-p", "hello", "--cid", "cid-stub-001"]' "muse interactive prompt should prefix the explicit agent"
    or return 1
end

test_default_interactive_prompt
or begin
    forge_test_cleanup
    exit 1
end

test_sage_interactive_prompt
or begin
    forge_test_cleanup
    exit 1
end

test_muse_interactive_prompt
or begin
    forge_test_cleanup
    exit 1
end

forge_test_cleanup
printf 'test_interactive_smoke: ok\n'
