#!/usr/bin/env fish

set -l test_dir (path dirname (status filename))
source "$test_dir/fixtures/extension.fish"

forge_test_bootstrap
forge_test_setup_tmpdir
set -l ok_text (forge_test_fixture_text ok.txt)

function test_foreground_sync
    forge_test_reset

    set -l output (_forge_action_sync | string collect)
    forge_test_assert_contains "$ok_text" "$output" "foreground sync should return the happy-path fixture output"
    or return 1
    forge_test_assert_log_python 'len(entries) == 1 and entries[0]["raw_argv"] == ["--agent", "forge", "workspace", "sync", "--init"] and entries[0]["argv"] == ["workspace", "sync", "--init"]' "foreground sync should use the agent-prefixed wrapper"
    or return 1
end

function test_background_sync_after_workspace_info
    forge_test_reset

    _forge_start_background_sync
    forge_test_wait_for_log_entries 2
    or return 1

    set -l workspace (pwd -P)
    forge_test_assert_log_python 'len(entries) >= 2 and entries[0]["argv"] == ["workspace", "info", "'"$workspace"'" ] and entries[1]["argv"] == ["workspace", "sync", "'"$workspace"'" ]' "background sync should check workspace info before launching sync"
    or return 1
end

test_foreground_sync
or begin
    forge_test_cleanup
    exit 1
end

test_background_sync_after_workspace_info
or begin
    forge_test_cleanup
    exit 1
end

forge_test_cleanup
printf 'test_sync: ok\n'
