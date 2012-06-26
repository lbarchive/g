#!/bin/bash
#
# g - Quick Directory Switcher
#
# Copyright (c) 2007-2009, 2012 Yu-Jie Lin
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE. 

G_VERSION="0.1.1"

# Which file to store directories
G_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/g"
mkdir -p "$G_DATA_DIR"
G_DIRS="${G_DATA_DIR}/dirs"

# Shows help information
G_ShowHelp() {
  echo "Commands:
  g (#|kw|dir) : change working directory
  g (-a|a)     : add current directory
  g (-a|a) dir : add dir
  g (-c|c)     : clean up non-existing directories
  g (-r|r)     : remove a directory from list
  g (-h|h)     : show what you are reading right now
"
  }

# Shows stored directories
G_ShowDirs() {
  [[ -z $1 ]] && echo Pick one:
  i=0
  while read kw d; do
    [[ -z $1 ]] && printf "%2d: %s" "$i" "$d"
    dir[$i]="$d"
    if [[ $kw != - ]]; then
      [[ -z $1 ]] && echo -n " [$kw]"
      key[$i]="$kw"
    fi
    [[ -z $1 ]] && echo
    (( i++ ))
  done < "$G_DIRS"
  echo;
  }

# Sorts directories after adding or removing
G_SortDirs() {
  sort -k 2 "$G_DIRS" > "$G_DIRS.tmp"
  mv -f "$G_DIRS.tmp" "$G_DIRS"
  }

# The main function
g() {
  [[ -d $1 ]] && cd "$1" && return 0
  # Check commands
  if (( $# > 0 )); then
    case "$1" in
      -a|--add|a|add)
        dir=$(pwd)
        [[ ! -z $2 ]] && dir="$2"
        if egrep ".+ $dir\$" "$G_DIRS" &> /dev/null; then
          echo "$dir already exists." >&2
          return 1
        fi
        read -p 'Keyword: ' kw
        kw="${kw:--}"
        echo "$kw $dir" >> "$G_DIRS"
        echo "$dir added."
        G_SortDirs
        return 0
        ;;
      -c|--clean|c|clean)
        G_ShowDirs 1
        echo -n "cleaning up..."
        rm -f "$G_DIRS"
        touch "$G_DIRS"
        for (( i=0; i<${#dir[@]}; i++)); do
          [[ -d ${dir[$i]} ]] && echo "${key[$i]} ${dir[$i]}" >> "$G_DIRS"
        done
        echo "done."
        return 0
        ;;
      -r|--remove|r|remove)
        G_ShowDirs
        read -p "Which dir to remove? " removed
        if [[ -z $removed ]] || (( $removed >= ${#dir[@]} )); then
          return 1
        fi
        rm -f "$G_DIRS"
        touch "$G_DIRS"
        for (( i=0; i<${#dir[@]}; i++)); do
          if [[ $i != $removed ]] && [[ ${key[$i]} != $removed ]]; then
            echo "${key[$i]} ${dir[$i]}" >> "$G_DIRS"
          fi
        done
        return 0
        ;;
      -h|--help|h|help)
        G_ShowHelp
        return 0
        ;;
      *)
        G_ShowDirs > /dev/null
        if egrep '^[0-9]+$'<<< "$1" >/dev/null \
        && (( $1 >= 0 )) \
        && (( $1 <= ${#dir[@]} )); then
          cd ${dir[$1]}
          return 0
        fi

        for (( i=0; i<${#key[@]}; i++)); do
          [[ ${key[$i]} == - ]] && continue
          if [[ ${key[$i]} == $1 ]]; then
            cd ${dir[$i]}
            return 0
          fi
        done

        echo "Cannot find dir to switch to!" >&2
        echo
        G_ShowHelp
        return 1
        ;;
    esac
  fi

  # Make sure there are some dirs in ~/.g_dirs
  if [[ ! -e $G_DIRS ]] || [[ $(wc -l "$G_DIRS") == 0* ]]; then
    echo "Please add some directories first!
"
    G_ShowHelp
    return 1
  fi

  G_ShowDirs
  read -p "Which dir? " i
  [[ $i == "" ]] && return 1

  cd "${dir[$i]}"
  unset dir
  }

# The Bash completion function
_g() {
  # Make sure we have $G_DIRS
  [[ ! -e $G_DIRS ]] && return 1

  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts=$(cut -d ' ' -f 2- "$G_DIRS")

  # Only do completion for once
  for opt in $opts; do
    [[ $prev == $opt ]] && return 1
  done
  COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
  return 0
  }

# If this script is sourced or run without arguments, it will think to be run
# as Bash function.
if [[ $# > 0 ]]; then
  g "$@"
else
  complete -F _g g
fi
