# Bash completion for kpenv
# Install: copy to /etc/bash_completion.d/kpenv or source in ~/.bashrc

_kpenv_completions() {
    local cur prev opts commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Main commands
    commands="init sync-example backup-env restore-env help"

    # Options
    opts="--env --password --help"

    # Environment values for --env
    envs="development staging production"

    # Complete based on previous word
    case "${prev}" in
        --env|--env=)
            # Complete environment names
            COMPREPLY=( $(compgen -W "${envs}" -- "${cur}") )
            return 0
            ;;
        --password|--password=)
            # Don't complete passwords
            return 0
            ;;
        kpenv)
            # Complete commands
            COMPREPLY=( $(compgen -W "${commands}" -- "${cur}") )
            return 0
            ;;
        init|sync-example|backup-env|restore-env)
            # Complete options for commands
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
    esac

    # Handle --env= style completion
    if [[ "${cur}" == --env=* ]]; then
        local prefix="${cur%%=*}="
        local typed="${cur#*=}"
        COMPREPLY=( $(compgen -W "${envs}" -- "${typed}") )
        # Add the prefix back
        COMPREPLY=( "${COMPREPLY[@]/#/${prefix}}" )
        return 0
    fi

    # Default: complete with commands or options
    if [[ "${cur}" == -* ]]; then
        COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
    else
        COMPREPLY=( $(compgen -W "${commands}" -- "${cur}") )
    fi

    return 0
}

# Register completion
complete -F _kpenv_completions kpenv
