function _forge_report_style --argument level
    switch $level
        case error
            printf '%s\n%s\n' red '⏺'
        case info
            printf '%s\n%s\n' white '⏺'
        case success
            printf '%s\n%s\n' yellow '⏺'
        case warning
            printf '%s\n%s\n' bryellow '⚠️'
        case debug
            printf '%s\n%s\n' cyan '⏺'
        case '*'
            printf '%s\n%s\n' normal ''
    end
end

function _forge_report_message_color --argument level
    switch $level
        case error
            printf '%s\n' red
        case info success
            printf '%s\n' white
        case warning
            printf '%s\n' bryellow
        case debug
            printf '%s\n' 888888
        case '*'
            printf '%s\n' normal
    end
end

function _forge_report
    set -l level "$argv[1]"
    set -l message "$argv[2]"
    set -l timestamp (set_color 888888)'['(date '+%H:%M:%S')']'(set_color normal)
    set -l style (_forge_report_style "$level")
    set -l icon_color "$style[1]"
    set -l icon "$style[2]"
    set -l message_color (_forge_report_message_color "$level")

    set -g _FORGE_OUTPUT_MODE visible

    if test -n "$icon"
        printf '%s%s%s %s %s%s%s\n' \
            (set_color "$icon_color") "$icon" (set_color normal) \
            "$timestamp" \
            (set_color "$message_color") "$message" (set_color normal)
        return 0
    end

    printf '%s\n' "$message"
end
