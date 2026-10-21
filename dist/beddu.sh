#!/usr/bin/env bash
# shellcheck disable=all
#
# beddu.sh - A lightweight bash framework for interactive scripts and pretty output
# Version: v1.3.1
#
# Copyright © 2026 Manuele Sarfatti
# Licensed under the MIT license
# See https://github.com/mjsarfatti/beddu

# Do not load beddu two times
[[ $BEDDU_LOADED ]] && return
readonly BEDDU_LOADED=true

readonly _q='?'
readonly _a='❯'
readonly _o='◌'
readonly _O='●'
readonly _mark='✓'
readonly _warn='!'
readonly _cross='✗'
readonly _spinner='⣷⣯⣟⡿⢿⣻⣽⣾' # See for alternatives: https://antofthy.gitlab.io/info/ascii/Spinners.txt
readonly _spinner_frame_duration=0.1

up() {
    printf "\033[A"
}
down() {
    printf "\033[B"
}
bol() {
    printf "\r"
}
eol() {
    printf "\033[999C"
}
cl() {
    printf "\033[2K"
}
upclear() {
    up; bol; cl
}
line() {
    printf "\n"
}
show_cursor() {
    printf "\033[?25h"
}
hide_cursor() {
    printf "\033[?25l"
    _beddu_set_traps
}
_beddu_set_traps() {
    local signal current
    for signal in EXIT INT TERM; do
        current="$(trap -p "$signal")"
        [[ "$current" == *_beddu_on_signal* ]] && continue
        if [[ -n "$current" ]]; then
            eval "set -- ${current#trap -- }"
            printf -v "_beddu_trap_${signal}" '%s' "$1"
        else
            unset "_beddu_trap_${signal}"
        fi
    done
    trap '_beddu_on_signal EXIT "$?"' EXIT
    trap '_beddu_on_signal INT' INT
    trap '_beddu_on_signal TERM' TERM
}
_beddu_on_signal() {
    local signal="$1" status="$2"
    local saved="_beddu_trap_${signal}"
    if [[ "$signal" == EXIT ]]; then
        if declare -F spinning >/dev/null && spinning; then
            spop
        else
            show_cursor
        fi
    fi
    if [[ -n "${!saved+set}" ]]; then
        if [[ "${status:-0}" -eq 0 ]]; then
            eval "${!saved}"
        else
            _beddu_return "$status" || eval "${!saved}"
        fi
    elif [[ "$signal" != EXIT ]]; then
        trap - "$signal"
        kill -"$signal" "$BASHPID"
    fi
}
_beddu_return() {
    return "$1"
}

readonly _q='?'
readonly _a='❯'
readonly _o='🞆'
readonly _O='🞊'
readonly _spinner='⣷⣯⣟⡿⢿⣻⣽⣾' # See for alternatives: https://antofthy.gitlab.io/info/ascii/Spinners.txt
readonly _spinner_frame_duration=0.1
readonly _cross='⛔'
readonly _color_error=196
readonly _icon_error="$_cross"
readonly _print_error="[ ERROR ]"
readonly _warn='☢️'
readonly _color_warning=178
readonly _icon_warning="$_warn"
readonly _print_warning="[ WARN  ]"
readonly _tick='✅'
readonly _color_success=40
readonly _icon_success="$_tick"
readonly _print_success="[  OK  ]"
readonly _info='ℹ️ '
readonly _color_info=32
readonly _icon_info="$_info"
readonly _print_info="[ INFO  ]"
readonly _bullet='📓'
readonly _color_debug=253
readonly _icon_debug="$_bullet"
readonly _print_debug="[ DEBUG ]"
readonly _color_normal=189

_setup_format_codes() {
    declare -n _codes="$1"
    _codes['bold']=1
    _codes['italic']=3
    _codes['underline']=4
    _codes['black']=30
    _codes['red']=31
    _codes['green']=32
    _codes['yellow']=33
    _codes['blue']=34
    _codes['purple']=35
    _codes['cyan']=36
    _codes['white']=37
    _codes['grey']=90
    _codes['gray']="${_codes[grey]}"
    _codes['italics']="${_codes[italic]}"
    for c in "${!_codes[@]}"; do
        _codes['--'"$c"]="${_codes["$c"]}"
    done
    _codes['b']="${_codes[bold]}"
    _codes['-b']="${_codes[bold]}"
    _codes['i']="${_codes[italic]}"
    _codes['-i']="${_codes[italic]}"
    _codes['u']="${_codes[underline]}"
    _codes['-u']="${_codes[underline]}"
}
_setup_ansi_256_codes() {
    declare -n _codes="$1"
    _codes['normal']="${_color_normal}"
    _codes['debug']="${_color_debug}"
    _codes['info']="${_color_info}"
    _codes['success']="${_color_success}"
    _codes['warning']="${_color_warning}"
    _codes['error']="${_color_error}"
    _codes['norm']="${_codes[normal]}"
    _codes['light']="${_codes[debug]}"
    _codes['neutral']="${_codes[info]}"
    _codes['positive']="${_codes[success]}"
    _codes['warn']="${_codes[warning]}"
    _codes['negative']="${_codes[error]}"
    for c in "${!_codes[@]}"; do
        _codes['--'"$c"]="${_codes["$c"]}"
    done
}
declare -A format_codes ansi_256_codes
_setup_format_codes   format_codes
_setup_ansi_256_codes ansi_256_codes
_ansi_code() {
    printf '%s%d%s' '\033[' "${1:-0}" 'm'
}
_ansi_color_256() {
    printf '%s%d%s' '\033[38;5;' "${1:-0}" 'm'
}
_matches() {
    [[ ${1} =~ ${2} ]] && return 0
    return 1
}
_is_color_256() {
    local color_num=$1
    if _matches "$color_num" "^[0-9]+$" && [ "$color_num" -ge 0 ] && [ "$color_num" -le 255 ]; then
        return 0
    fi
    return 1
}
_is_format_code() {
    local code=$1
    if [[ -n "${format_codes[$code]}" ]]; then
        return 0
    fi
    return 1
}
_is_ansi_color_code() {
    local code=$1
    if [[ -n "${ansi_256_codes[$code]}" ]]; then
        return 0
    fi
    return 1
}
pen() {
    local new_line="\n"
    local text="${*: -1}"      
    local args=("${@:1:$#-1}") 
    local format_code=""
    local reset_code="\033[0m"
    for arg in "${args[@]}"; do
        arg=${arg,,} 
        case "$arg" in
        -n) new_line="" ;;
        bold) format_code+="\033[1m" ;;
        italic) format_code+="\033[3m" ;;
        underline) format_code+="\033[4m" ;;
        black) format_code+="\033[30m" ;;
        red) format_code+="\033[31m" ;;
        green) format_code+="\033[32m" ;;
        yellow) format_code+="\033[33m" ;;
        blue) format_code+="\033[34m" ;;
        purple) format_code+="\033[35m" ;;
        cyan) format_code+="\033[36m" ;;
        white) format_code+="\033[37m" ;;
        grey | gray) format_code+="\033[90m" ;;
        [0-9]*)
            if [[ "$arg" =~ ^[0-9]+$ ]] && [ "$arg" -ge 0 ] && [ "$arg" -le 255 ]; then
                format_code+="\033[38;5;${arg}m"
            fi
            ;;
        *) ;; 
        esac
    done
    printf "%b%s%b%b" "${format_code}" "${text}" "${reset_code}" "${new_line}"
}

run() {
    local outvar_name errvar_name
    local -n outvar errvar # Declare namerefs (will be assigned below if needed)
    local cmd
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --out)
            outvar_name="$2"
            shift 2
            ;;
        --err)
            errvar_name="$2"
            shift 2
            ;;
        *)
            cmd=("$@")
            break
            ;;
        esac
    done
    [[ -n "${outvar_name}" ]] && local -n outvar="${outvar_name}"
    [[ -n "${errvar_name}" ]] && local -n errvar="${errvar_name}"
    local stdout_file stderr_file
    stdout_file=$(mktemp)
    stderr_file=$(mktemp)
    local old_settings=$- 
    set +e # Don't immediately exit on error
    "${cmd[@]}" >"${stdout_file}" 2>"${stderr_file}"
    local exit_code=$?
    [[ -n "${outvar_name}" ]] && outvar="$(<"$stdout_file")"
    [[ -n "${errvar_name}" ]] && errvar="$(<"$stderr_file")"
    if [ $exit_code -ne 0 ] && [[ -z "${errvar_name}" ]]; then
        cleaned_errvar=$(sed 's/^[^:]\{1,\}:\( line [0-9]\{1,\}:\)\{0,1\} \(.*\)/\2/' "$stderr_file")
        line
        throw "Command \`$(pen 245 "${cmd[*]}")\` failed with error:"
        pen 245 "  ${cleaned_errvar}"
        pen "  called from: $(pen 245 "${BASH_SOURCE[1]}:${BASH_LINENO[0]}") in $(pen 245 "${FUNCNAME[1]:-main}")"
        line
    fi
    rm -f "${stdout_file}" "${stderr_file}"
    if [[ $old_settings == *e* ]]; then set -e; else set +e; fi
    return $exit_code
}

centered_text() {
    local text width text_len padding left right
    text="$1"
    width="$2"
    text_len="${#text}"
    [[ "$text_len" -ge "$width" ]] && printf "%s" "$text" && return
    padding=$((width - text_len))
    left=$((padding / 2))
    right=$((padding - left))
    printf "%*s%s%*s" "$left" "" "$text" "$right" ""
}

centered_text() {
    local text width text_len padding left right
    text="$1"
    width="$2"
    text_len="${#text}"
    [[ "$text_len" -ge "$width" ]] && printf "%s" "$text" && return
    padding=$((width - text_len))
    left=$((padding / 2))
    right=$((padding - left))
    printf "%*s%s%*s" "$left" "" "$text" "$right" ""
}
_level() {
    local icon level
    local color="debug"
    local alt_icon="⋄"
    local show_level=false
    local plain=false
    while :; do
        arg="${1#--}"
        arg="${arg#-}"
        case "$arg" in
                  show-level) show_level=true
                              shift ;;
                       plain) plain=true
                              ;;
                   level | l) level="$2";
                              shift; shift
                              read -r color alt_icon \
                                  < <( _level "--$level")
                              ;; 
              debug | d | 7) color="debug"    alt_icon="⋄"
                                shift ;;
               info | i | 6) color="info"     alt_icon="ⓘ"
                                shift ;;
            success | s | 5) color="success"  alt_icon="✓"    # non-standard level 5 - (usually NOTICE)
                                shift ;;
                 ok | o | 5) color="success"  alt_icon="✓"
                                shift ;; 
     warn | warning | w | 4) color="warning"  alt_icon="!" 
                                shift ;;
              error | e | 3) color="error"    alt_icon="✗" 
                                shift ;; 
                             *) ;;
        esac
        shift
    done
    level="_print_${color}"
    icon_name="_icon_${color}"
    if $plain; then icon="$alt_icon"; else icon="${!icon_name}"; fi
    $show_level && printf ' [%s] ' "${!level}"
    echo -e "$color" "$icon"
}
log() {
    local color icon
    local -i logto
    if spinning; then
        spop
        upclear
    fi
    pen -n green "${_mark:-✓} "
    pen "$@"
}
logdebug()   { log --level 'debug'   "$@"; }
logok()      { log --level 'ok'      "$@"; }
loginfo()    { log --level 'info'    "$@"; }
logwarn()    { log --level 'warning' "$@"; }
logerr()     { log --level 'error'   "$@"; }

repen() {
    upclear
    pen "$@"
}

_spinner_pid=""
_frame_duration="${_spinner_frame_duration:-0.1}"
spin() {
    local message=("$@")
    local spinner="${_spinner:-⣷⣯⣟⡿⢿⣻⣽⣾}"
    if spinning; then
        sleep "$_frame_duration"
        spop --keep-cursor-hidden
    fi
    hide_cursor
    (
        trap "exit 0" USR1
        pen -n cyan "${spinner:0:1} "
        pen "${message[@]}"
        while true; do
            for ((i = 0; i < ${#spinner}; i++)); do
                frame="${spinner:$i:1}"
                up
                bol
                pen -n cyan "${frame} "
                pen "${message[@]}"
                sleep "$_frame_duration"
            done
        done
    ) &
    _spinner_pid=$!
}
spop() {
    local old_settings=$- 
    set +e # Don't immediately exit on error
    local keep_cursor_hidden=false
    [[ "$1" == "--keep-cursor-hidden" ]] && keep_cursor_hidden=true
    if spinning; then
        kill -USR1 "${_spinner_pid}" 2>/dev/null
        sleep "$_frame_duration"
        if ps -p "${_spinner_pid}" >/dev/null 2>&1; then
            kill "${_spinner_pid}" 2>/dev/null
        fi
        if [[ "$keep_cursor_hidden" == false ]]; then
            show_cursor
        fi
        _spinner_pid=""
    fi
    if [[ $old_settings == *e* ]]; then set -e; else set +e; fi
}
spinning() {
    [[ -n "${_spinner_pid}" ]]
}

throw() {
    if spinning; then
        spop
        upclear
    fi
    pen -n red "${_cross:-✗} "
    pen "$@"
}

warn() {
    if spinning; then
        spop
        upclear
    fi
    pen -n yellow bold italic "${_warn:-!} "
    pen italic "$@"
}

choose() {
    local -n outvar="$1"
    local prompt
    local options=("${@:3}") 
    local current=0
    local count=${#options[@]}
    prompt=$(
        pen -n blue "${_q:-?} "
        pen -n "${2} "
        pen gray "[↑↓]"
    )
    hide_cursor
    pen "$prompt"
    while true; do
        local index=0
        for item in "${options[@]}"; do
            if ((index == current)); then
                pen -n blue "${_O:-●} "
                pen "${item}"
            else
                pen gray "${_o:-◌} ${item}"
            fi
            ((++index))
        done
        read -s -r -n1 key
        if [[ $key == $'\e' ]]; then
            read -s -r -n2 -t 0.0001 escape
            key+="$escape"
        fi
        case "$key" in
        $'\e[A' | 'k') 
            ((--current))
            [[ $current -lt 0 ]] && current=$((count - 1))
            ;;
        $'\e[B' | 'j') 
            ((++current))
            [[ $current -ge "$count" ]] && current=0
            ;;
        '')
            break
            ;;
        esac
        echo -en "\e[${count}A\e[J"
    done
    outvar="${options[$current]}"
}

confirm() {
    local default="y"
    local hint="[Y/n]"
    local prompt
    local response
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --default-no)
            default="n"
            hint="[y/N]"
            shift
            ;;
        --default-yes)
            shift
            ;;
        *) break ;;
        esac
    done
    prompt=$(
        pen -n blue "${_q:-?} "
        pen -n "$1"
        pen gray " $hint"
        pen -n blue "${_a:-❯} "
    )
    show_cursor
    while true; do
        read -r -p "$prompt" response
        response="${response:-$default}"
        case "$response" in
        [Yy] | [Yy][Ee][Ss])
            upclear
            pen -n blue "${_a:-❯} "
            pen "yes"
            return 0
            ;;
        [Nn] | [Nn][Oo])
            upclear
            pen -n blue "${_a:-❯} "
            pen "no"
            return 1
            ;;
        *)
            echo
            warn "Please answer yes or no."
            ;;
        esac
    done
}

request() {
    local -n outvar="$1"
    local prompt
    local answer
    prompt=$(
        pen -n info "${_q:-?} "
        pen normal "${2}"
        pen -n info "${_a:-❯} "
    )
    show_cursor
    while true; do
        read -r -p "$prompt" answer
        case "$answer" in
        "")
            echo
            warn "Please type your answer."
            ;;
        *) break ;;
        esac
    done
    outvar="$answer"
}

seek() {
    local -n outvar="$1"
    local prompt
    local answer
    prompt=$(
        pen -n info "${_q:-?} "
        pen normal "${2}"
        pen -n info "${_a:-❯} "
    )
    show_cursor
    read -r -p "$prompt" answer
    outvar="$answer"
}
