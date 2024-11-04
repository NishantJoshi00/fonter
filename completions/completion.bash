#!/bin/bash

_f_counter_completions() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # All possible options
    opts="-h --help +help -v --version +version +show-date +show-counter +incr"

    # Filter options based on what the user has typed
    if [[ ${cur} == -* ]] || [[ ${cur} == +* ]] ; then
        # Return all options that match the current input
        COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
        return 0
    fi
}

# Register the completion function
complete -F _f_counter_completions f-counter

