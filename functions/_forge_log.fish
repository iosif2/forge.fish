function _forge_log
    set -l level $argv[1]
    set -l message $argv[2]
    set -l timestamp (set_color 888888)"["(date '+%H:%M:%S')"]"(set_color normal)

    set -g _FORGE_OUTPUT_MODE visible

    switch $level
        case error
            printf '%s%s%s %s %s%s%s\n' \
                (set_color red) '⏺' (set_color normal) \
                "$timestamp" \
                (set_color red) "$message" (set_color normal)
        case info
            printf '%s%s%s %s %s%s%s\n' \
                (set_color white) '⏺' (set_color normal) \
                "$timestamp" \
                (set_color white) "$message" (set_color normal)
        case success
            printf '%s%s%s %s %s%s%s\n' \
                (set_color yellow) '⏺' (set_color normal) \
                "$timestamp" \
                (set_color white) "$message" (set_color normal)
        case warning
            printf '%s%s%s %s %s%s%s\n' \
                (set_color bryellow) '⚠️' (set_color normal) \
                "$timestamp" \
                (set_color bryellow) "$message" (set_color normal)
        case debug
            printf '%s%s%s %s %s%s%s\n' \
                (set_color cyan) '⏺' (set_color normal) \
                "$timestamp" \
                (set_color 888888) "$message" (set_color normal)
        case '*'
            printf '%s\n' "$message"
    end
end
