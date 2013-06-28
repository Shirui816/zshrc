# Created by newuser for 5.0.2

autoload colors && colors
alias ls='ls --color=auto -F'
alias fcfb='fcitx-fbterm-helper -l'
autoload -U compinit && compinit
setopt prompt_subst
autoload -Uz vcs_info
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE=~/.zhistory
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt EXTENDED_HISTORY      
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt AUTO_LIST
setopt AUTO_MENU

zstyle ':completion:*' verbose yes
zstyle ':completion:*' menu select
zstyle ':completion:*:*:default' force-list always
zstyle ':completion:*' select-prompt '%SSelect:  lines: %L  matches: %M  [%p]'

zstyle ':completion:*:match:*' original only
zstyle ':completion::prefix-1:*' completer _complete
zstyle ':completion:predict:*' completer _complete
zstyle ':completion:incremental:*' completer _complete _correct
zstyle ':completion:*' completer _complete _prefix _correct _prefix _match _approximate

zstyle ':completion:*' expand 'yes'
zstyle ':completion:*' squeeze-shlashes 'yes'
zstyle ':completion::complete:*' '\\'

eval $(dircolors -b)
export ZLSCOLORS="${LS_COLORS}"
zmodload zsh/complist
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

compdef pkill=kill
compdef pkill=killall
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:*:*:processes' force-list always
zstyle ':completion:*:processes' command 'ps -au$USER'

zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:descriptions' format $'\e[01;33m -- %d --\e[0m'
zstyle ':completion:*:messages' format $'\e[01;35m -- %d --\e[0m'
zstyle ':completion:*:warnings' format $'\e[01;31m -- No Matches Found --\e[0m'
zstyle ':completion:*:corrections' format $'\e[01;32m -- %d (errors: %e) --\e[0m'

zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'


PROMPT="%B(T_T)%b %{$fg_bold[green]%}%B%~%b"'${git_prompt}'" >>> "

git_check_if_worktree() {
    if [ -n "${skip_zsh_git}" ]; then
        git_pwd_is_worktree='false'
        return 1
    fi
    if [ "${UID}" = '0' ]; then
        git_check_if_workdir_path="${git_check_if_workdir_path:-/root:/etc}"
    else
        git_check_if_workdir_path="${git_check_if_workdir_path:-/home}"
        git_check_if_workdir_path_exclude="${git_check_if_workdir_path_exclude:-${HOME}/_sshfs}"
    fi

    if begin_with "${PWD}" ${=git_check_if_workdir_path//:/ }; then
        if ! begin_with "${PWD}" ${=git_check_if_workdir_path_exclude//:/ }; then
            local git_pwd_is_worktree_match='true'
        else
            local git_pwd_is_worktree_match='false'
        fi
    fi

    if ! [ "${git_pwd_is_worktree_match}" = 'true' ]; then
        git_pwd_is_worktree='false'
        return 1
    fi

    if [ -d '.git' ] || [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" = 'true' ]; then
        git_pwd_is_worktree='true'
        git_worktree_is_bare="$(git config core.bare)"
    else
        unset git_branch git_worktree_is_bare
        git_pwd_is_worktree='false'
    fi
}

git_branch() {
    git_branch="$(git symbolic-ref HEAD 2>/dev/null)"
    git_branch="${git_branch##*/}"
    git_branch="${git_branch:-no branch}"
}

git_dirty() {
    if [ "${git_worktree_is_bare}" = 'false' ] && [ -n "$(git status --untracked-files='no' --porcelain)" ]; then
        git_dirty="%B%{$fg_bold[green]%}+%b"
    else
        unset git_dirty
    fi
}

begin_with() {
    local string="${1}"
    shift
    local element=''
    for element in "$@"; do
        if [[ "${string}" =~ "^${element}" ]]; then
            return 0
        fi
    done
    return 1
}


precmd() {
    git_check_if_worktree
    if [ "${git_pwd_is_worktree}" = 'true' ]; then
        git_branch
        git_dirty
        git_prompt=" %B%{$fg_bold[blue]%}[%b${git_branch}${git_dirty}%B%{$fg_bold[blue]%}]%b"
    else
        unset git_prompt
    fi
}

recolor-cmd() {
    region_highlight=()
    colorize=true
    start_pos=0
    for arg in ${(z)BUFFER}; do
        ((start_pos+=${#BUFFER[$start_pos+1,-1]}-${#${BUFFER[$start_pos+1,-1]## #}}))
        ((end_pos=$start_pos+${#arg}))
        if $colorize; then
            colorize=false
            res=$(LC_ALL=C builtin type $arg 2>/dev/null)
            case $res in
                *'reserved word'*)   style="fg=magenta,bold";;
                *'alias for'*)       style="fg=cyan,bold";;
                *'shell builtin'*)   style="fg=yellow,bold";;
                *'shell function'*)  style='fg=green,bold';;
                *"$arg is"*)
                    [[ $arg = 'sudo' ]] && style="fg=red,bold" || style="fg=blue,bold";;
                *)                   style='none,bold';;
            esac
            region_highlight+=("$start_pos $end_pos $style")
        fi
        [[ ${${TOKENS_FOLLOWED_BY_COMMANDS[(r)${arg//|/\|}]}:+yes} = 'yes' ]] && colorize=true
        start_pos=$end_pos
    done
}

check-cmd-self-insert() {
    zle .self-insert && recolor-cmd
}

check-cmd-backward-delete-char() {
    zle .backward-delete-char && recolor-cmd
}

zle -N self-insert check-cmd-self-insert
zle -N backward-delete-char check-cmd-backward-delete-char
