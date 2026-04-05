# Action handler: Run shell-native diagnostics for the Fish plugin
# Checks the local Fish integration state without delegating to the forge
# binary so it can diagnose plugin issues even when forge subcommands are
# unavailable or mismatched.
# Usage: _forge_action_doctor

function _forge_doctor_section
    printf '%s%s%s\n' (set_color --bold white) "$argv[1]" (set_color normal)
end

function _forge_doctor_detail
    printf '  %s%s%s\n' (set_color 888888) "$argv[1]" (set_color normal)
end

# Returns 0 if actual_version >= min_version (semantic version comparison).
# Strips a leading 'v' and ignores non-numeric suffixes on each segment.
function _forge_doctor_version_gte
    set -l v1 (string replace -r '^v' '' -- (string split ' ' -- $argv[1])[1])
    set -l v2 (string replace -r '^v' '' -- $argv[2])
    set -l parts1 (string split '.' -- $v1)
    set -l parts2 (string split '.' -- $v2)
    for i in 1 2 3
        set -l p1 0
        set -l p2 0
        if test (count $parts1) -ge $i
            set p1 (string replace -r '[^0-9].*$' '' -- $parts1[$i])
            string match -rq '^[0-9]+$' -- "$p1"; or set p1 0
        end
        if test (count $parts2) -ge $i
            set p2 (string replace -r '[^0-9].*$' '' -- $parts2[$i])
            string match -rq '^[0-9]+$' -- "$p2"; or set p2 0
        end
        if test $p1 -gt $p2
            return 0
        else if test $p1 -lt $p2
            return 1
        end
    end
    return 0
end

function _forge_action_doctor
    set -l passed 0
    set -l warnings 0
    set -l failed 0

    set -l terminal_info "$TERM"
    if test -n "$TERM_PROGRAM"
        if test -n "$TERM_PROGRAM_VERSION"
            set terminal_info "$TERM_PROGRAM $TERM_PROGRAM_VERSION"
        else
            set terminal_info "$TERM_PROGRAM"
        end
    end

    echo
    _forge_doctor_section "Forge Fish Doctor"
    _forge_doctor_detail "fish version: $version"
    _forge_doctor_detail "terminal: $terminal_info"

    echo
    _forge_doctor_section "Environment"

    if _forge_doctor_version_gte "$version" 3.4.0
        _forge_log success "Fish version $version (3.4.0+ required)"
        set passed (math $passed + 1)
    else
        _forge_log error "Fish version $version is too old; 3.4.0 or higher required"
        set failed (math $failed + 1)
    end

    if set -q _FORGE_PLUGIN_LOADED
        _forge_log success "Forge fish plugin variables are loaded"
        set passed (math $passed + 1)
    else
        _forge_log error "Forge fish plugin variables are not loaded"
        set failed (math $failed + 1)
    end

    echo
    _forge_doctor_section "Forge Installation"

    if test -n "$_FORGE_BIN"
        if string match -rq '/' -- "$_FORGE_BIN"
            if test -x "$_FORGE_BIN"
                _forge_log success "Forge binary is configured: $_FORGE_BIN"
                set passed (math $passed + 1)
            else
                _forge_log error "Configured forge binary is not executable: $_FORGE_BIN"
                set failed (math $failed + 1)
            end
        else if command -q "$_FORGE_BIN"
            _forge_log success "Forge binary resolves from PATH: $_FORGE_BIN"
            set passed (math $passed + 1)
        else
            _forge_log error "Forge binary is not available in PATH: $_FORGE_BIN"
            _forge_doctor_detail "Installation: curl -fsSL https://forgecode.dev/cli | sh"
            set failed (math $failed + 1)
        end
    else
        _forge_log error "_FORGE_BIN is empty"
        set failed (math $failed + 1)
    end

    echo
    _forge_doctor_section "Right Prompt"

    if test "$_FORGE_THEME_LOADED" = 1
        _forge_log success "Forge right prompt is installed"
        set passed (math $passed + 1)
    else
        _forge_log error "Forge right prompt is not installed"
        set failed (math $failed + 1)
    end

    if functions -q fish_right_prompt
        set -l rp_def (functions fish_right_prompt | string collect)
        if string match -q '*__forge_status_prompt*' -- "$rp_def"
            _forge_log success "fish_right_prompt is wrapped with Forge status"
            set passed (math $passed + 1)
        else
            _forge_log warning "fish_right_prompt exists but is not wrapped by Forge"
            set warnings (math $warnings + 1)
        end
    else
        _forge_log warning "fish_right_prompt is not defined"
        set warnings (math $warnings + 1)
    end

    echo
    _forge_doctor_section "Dependencies"

    if command -q fzf
        set -l fzf_ver (string split ' ' -- (fzf --version 2>/dev/null))[1]
        if test -n "$fzf_ver"
            if _forge_doctor_version_gte "$fzf_ver" 0.36.0
                _forge_log success "fzf $fzf_ver"
            else
                _forge_log error "fzf $fzf_ver is too old; 0.36.0 or higher required"
                _forge_doctor_detail "Update: https://github.com/junegunn/fzf#installation"
                set failed (math $failed + 1)
            end
        else
            _forge_log success "fzf: installed"
        end
        set passed (math $passed + 1)
    else
        _forge_log error "fzf not found"
        _forge_doctor_detail "Required for interactive features. Install: https://github.com/junegunn/fzf#installation"
        set failed (math $failed + 1)
    end

    set -l fd_backend (string split ' ' -- "$_FORGE_FD_CMD")[1]
    if test -n "$fd_backend"; and command -q "$fd_backend"
        set -l fd_ver (string split ' ' -- ($fd_backend --version 2>/dev/null))[2]
        if test -n "$fd_ver"
            if _forge_doctor_version_gte "$fd_ver" 10.0.0
                _forge_log success "$fd_backend $fd_ver"
            else
                _forge_log error "$fd_backend $fd_ver is too old; 10.0.0 or higher required"
                _forge_doctor_detail "Update: https://github.com/sharkdp/fd#installation"
                set failed (math $failed + 1)
            end
        else
            _forge_log success "$fd_backend: installed"
        end
        set passed (math $passed + 1)
    else
        _forge_log warning "fd/fdfind not found"
        _forge_doctor_detail "Enhanced file discovery. Install: https://github.com/sharkdp/fd#installation"
        set warnings (math $warnings + 1)
    end

    set -l preview_backend (string split ' ' -- "$_FORGE_CAT_CMD")[1]
    if test -n "$preview_backend"; and command -q "$preview_backend"
        set -l bat_ver (string split ' ' -- ($preview_backend --version 2>/dev/null))[2]
        if test -n "$bat_ver"
            if _forge_doctor_version_gte "$bat_ver" 0.20.0
                _forge_log success "$preview_backend $bat_ver"
            else
                _forge_log error "$preview_backend $bat_ver is too old; 0.20.0 or higher required"
                _forge_doctor_detail "Update: https://github.com/sharkdp/bat#installation"
                set failed (math $failed + 1)
            end
        else
            _forge_log success "$preview_backend: installed"
        end
        set passed (math $passed + 1)
    else
        _forge_log warning "bat not found"
        _forge_doctor_detail "Enhanced preview. Install: https://github.com/sharkdp/bat#installation"
        set warnings (math $warnings + 1)
    end

    echo
    _forge_doctor_section "System"

    if test -n "$FORGE_EDITOR"
        _forge_log success "FORGE_EDITOR: $FORGE_EDITOR"
        set passed (math $passed + 1)
        if test -n "$EDITOR"
            _forge_doctor_detail "EDITOR also set: $EDITOR (ignored)"
        end
    else if test -n "$EDITOR"
        _forge_log success "EDITOR: $EDITOR"
        set passed (math $passed + 1)
        _forge_doctor_detail "Tip: set FORGE_EDITOR for a forge-specific editor override"
    else
        _forge_log warning "No editor configured"
        _forge_doctor_detail "export EDITOR=vim or set -Ux FORGE_EDITOR nvim"
        set warnings (math $warnings + 1)
    end

    echo
    _forge_doctor_section "Keyboard"

    set -l platform (uname 2>/dev/null)
    set -l check_performed 0

    if test "$TERM_PROGRAM" = vscode
        set check_performed 1
        if test "$platform" = Darwin
            set -l vscode_settings "$HOME/Library/Application Support/Code/User/settings.json"
        else
            set -l vscode_settings "$HOME/.config/Code/User/settings.json"
        end
        if test -f "$vscode_settings"
            if grep -q '"terminal.integrated.macOptionIsMeta"[[:space:]]*:[[:space:]]*true' "$vscode_settings" 2>/dev/null
                or grep -q '"terminal.integrated.sendAltAsMetaKey"[[:space:]]*:[[:space:]]*true' "$vscode_settings" 2>/dev/null
                _forge_log success "VS Code: Alt/Option key configured as Meta"
                set passed (math $passed + 1)
            else
                _forge_log warning "VS Code: Alt/Option key NOT configured as Meta"
                _forge_doctor_detail "Alt+f/b word navigation shortcuts will not work"
                if test "$platform" = Darwin
                    _forge_doctor_detail "Add to settings.json: \"terminal.integrated.macOptionIsMeta\": true"
                else
                    _forge_doctor_detail "Add to settings.json: \"terminal.integrated.sendAltAsMetaKey\": true"
                end
                set warnings (math $warnings + 1)
            end
        else
            _forge_log warning "VS Code settings file not found; cannot verify Alt key configuration"
            set warnings (math $warnings + 1)
        end
    else if test "$TERM_PROGRAM" = iTerm.app
        set check_performed 1
        _forge_log info "iTerm2 detected"
        _forge_doctor_detail "To enable Alt+f/b word navigation:"
        _forge_doctor_detail "Preferences → Profiles → Keys → Left/Right Option Key → Esc+"
    else if test "$TERM_PROGRAM" = Apple_Terminal
        set check_performed 1
        _forge_log info "Terminal.app detected"
        _forge_doctor_detail "To enable Option+f/b word navigation:"
        _forge_doctor_detail "Preferences → Profiles → Keyboard → Use Option as Meta key"
    else if test "$TERM" = xterm; or test "$TERM" = xterm-256color
        set check_performed 1
        set -l xresources "$HOME/.Xresources"
        if test -f "$xresources"
            if grep -q 'XTerm\*metaSendsEscape:[[:space:]]*true' "$xresources" 2>/dev/null
                or grep -q 'XTerm\*eightBitInput:[[:space:]]*false' "$xresources" 2>/dev/null
                _forge_log success "xterm: Meta key configured in ~/.Xresources"
                set passed (math $passed + 1)
            else
                _forge_log warning "xterm: Meta key not configured for word navigation"
                _forge_doctor_detail "Add to ~/.Xresources: XTerm*metaSendsEscape: true"
                _forge_doctor_detail "Then reload: xrdb ~/.Xresources"
                set warnings (math $warnings + 1)
            end
        else
            _forge_log info "xterm detected; no ~/.Xresources found"
            _forge_doctor_detail "For Alt+f/b word navigation, add to ~/.Xresources:"
            _forge_doctor_detail "XTerm*metaSendsEscape: true"
        end
    end

    if test $check_performed -eq 0
        _forge_log info "Terminal: $terminal_info"
        _forge_doctor_detail "Could not check Alt/Meta key configuration automatically"
        if test "$platform" = Darwin
            _forge_doctor_detail "Ensure your terminal sends Option key as Esc+ for Alt+f/b word navigation"
        else
            _forge_doctor_detail "Ensure your terminal sends Alt key as Meta for Alt+f/b word navigation"
        end
    end

    echo
    _forge_doctor_section "Nerd Font"

    if test -n "$NERD_FONT"
        if test "$NERD_FONT" = 1; or test "$NERD_FONT" = true
            _forge_log success "NERD_FONT: enabled"
            set passed (math $passed + 1)
        else
            _forge_log warning "NERD_FONT: disabled ($NERD_FONT)"
            _forge_doctor_detail "Enable with: set -Ux NERD_FONT 1"
            set warnings (math $warnings + 1)
        end
    else if test -n "$USE_NERD_FONT"
        if test "$USE_NERD_FONT" = 1; or test "$USE_NERD_FONT" = true
            _forge_log success "USE_NERD_FONT: enabled"
            set passed (math $passed + 1)
        else
            _forge_log warning "USE_NERD_FONT: disabled ($USE_NERD_FONT)"
            _forge_doctor_detail "Enable with: set -Ux NERD_FONT 1"
            set warnings (math $warnings + 1)
        end
    else
        _forge_log success "Nerd Font: enabled (default)"
        _forge_doctor_detail "Set NERD_FONT=0 to disable if icons appear broken"
        set passed (math $passed + 1)
    end

    echo
    printf '%s' (set_color yellow)"Visual check — can you see the icons clearly without overlap?"(set_color normal)
    echo
    printf '   %s%s%s %s%s%s\n' \
        (set_color --bold) "󱙺 FORGE 33.0k" (set_color normal) \
        (set_color cyan) " main" (set_color normal)
    echo
    _forge_doctor_detail "If you see boxes □ or question marks ?, install a Nerd Font:"
    _forge_doctor_detail "https://www.nerdfonts.com/"

    echo
    _forge_doctor_section "Summary"
    if test $failed -gt 0
        _forge_log error "Doctor finished with $failed failure(s), $warnings warning(s), $passed passing check(s)"
    else if test $warnings -gt 0
        _forge_log warning "Doctor finished with $warnings warning(s), $passed passing check(s)"
    else
        _forge_log success "Doctor finished: all $passed check(s) passed"
    end
end
