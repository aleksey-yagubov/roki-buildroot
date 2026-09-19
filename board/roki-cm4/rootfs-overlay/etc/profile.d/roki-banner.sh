case $- in
    *i*) ;;
    *) return ;;
esac

[ -t 1 ] || return

if [ "${TERM:-dumb}" != dumb ]; then
    printf '\033[1;34m'
fi
printf '%s\n' '########   #######  ##    ## ####         ##     ## ########    ###    ########  '
printf '%s\n' '##     ## ##     ## ##   ##   ##          ##     ## ##         ## ##   ##     ## '
printf '%s\n' '##     ## ##     ## ##  ##    ##          ##     ## ##        ##   ##  ##     ## '
printf '%s\n' '########  ##     ## #####     ##  ####### ######### ######   ##     ## ##     ## '
printf '%s\n' '##   ##   ##     ## ##  ##    ##          ##     ## ##       ######### ##     ## '
printf '%s\n' '##    ##  ##     ## ##   ##   ##          ##     ## ##       ##     ## ##     ## '
printf '%s\n' '##     ##  #######  ##    ## ####         ##     ## ######## ##     ## ########  '
if [ "${TERM:-dumb}" != dumb ]; then
    printf '\033[0m'
fi
printf '\n'

if [ -r /etc/roki-build-date ]; then
    IFS= read -r build_date < /etc/roki-build-date || build_date=unknown
    if [ "${TERM:-dumb}" != dumb ]; then
        printf '\033[1;32mСобрано: %s\033[0m\n' "${build_date}"
    else
        printf 'Собрано: %s\n' "${build_date}"
    fi
fi
printf '\n'

printf '%s\n' ' Голова робота ROKI-2, система на базе Buildroot.'
printf '%s\n' ' Для управления сервисами используйте dinitctl.'
printf '%s\n' ' Для подключения к wifi используйте iwctl.'
printf '%s\n' ' Для просмотра работающих процессов используйте htop.'
printf '%s\n' ' Репозиторий образа https://github.com/aleksey-yagubov/roki-buildroot'
printf '%s\n' ' Сделал Ягубов Алексей с помощью ChatGPT Codex'
