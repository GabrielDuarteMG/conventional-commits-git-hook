#!/bin/sh

types=('build' 'docs' 'feat' 'fix' 'perf' 'refactor' 'style' 'test' 'chore')
icons=('🔧' '📚' '✨' '🐛' '⚡' '♻️' '🎨' '🧪' '📦')

build_regex() {
    regexp="^[.0-9]+$|"
    regexp="${regexp}^([Rr]evert|[Mm]erge):? .*$|^("

    for i in "${!types[@]}"; do
        regexp="${regexp}${icons[$i]} ${types[$i]}|"
    done

    regexp="${regexp%|})(\(.+\))?: "
}


check_type_without_icon() {
    for i in "${!types[@]}"; do
        if [[ $commit_message =~ ^${types[$i]} ]]; then
            if [[ ! $commit_message =~ ^${icons[$i]} ]]; then
                return 0
            fi
        fi
    done
    return 1
}
# Função para exibir menu para seleção do tipo de commit
showMenuToSelect() {
    echo "Selecione o tipo de commit:"
    for i in "${!types[@]}"; do
        echo "$i) ${icons[$i]} ${types[$i]}"
    done

    exec < /dev/tty
    while true; do
        read -p "Digite o número correspondente ao tipo: " selected
        if [[ $selected =~ ^[0-9]+$ ]] && [ $selected -ge 0 ] && [ $selected -lt ${#types[@]} ]; then
            commit_message="${icons[$selected]} ${types[$selected]}: ${commit_message}"
            npm version patch --no-git-tag-version
            git add .
            git commit -m "$commit_message"
            break
        else
            echo "Seleção inválida, tente novamente."
        fi
    done
}

print_error() {
    local regular_expression=$2
    echo -e "\n\e[31m[Mensagem de Commit Inválida]"
    echo -e "-------------------------------\033[0m\e[0m"
    echo -e "Tipos válidos: "
    for i in "${!types[@]}"; do
        echo -e "${icons[$i]} \e[36m${types[$i]}\033[0m"
    done
    echo -e "\e[37mMensagem atual: \e[33m\"$commit_message\"\033[0m"
    echo -e "\e[37mExemplo de mensagem válida: \e[36m\"🐛 fix(subject): mensagem\"\033[0m"
    echo -e "\e[37mRegex esperado: \e[33m\"$regexp\"\033[0m"
}

INPUT_FILE=$1
commit_message=$(head -n1 "$INPUT_FILE")

build_regex

if [[ ! $commit_message =~ $regexp ]]; then
    if check_type_without_icon; then
        echo "Tipo de commit sem ícone"
        for i in "${!types[@]}"; do
            if [[ $commit_message =~ ^${types[$i]} ]]; then
                commit_message="${icons[$i]} ${commit_message}"
                npm version patch --no-git-tag-version
                git add .
                git commit -m "$commit_message"
                exit 1
            fi
        done
    fi
    print_error "Mensagem de commit inválida" $regexp
    showMenuToSelect
    exit 1
fi
