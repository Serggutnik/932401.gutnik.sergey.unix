#!/bin/sh

DIR=${DIR:-/data}
LOCK="$DIR/.lock"

if [ ! -d "$DIR" ]; then
    echo "Ошибка: каталог '$DIR' не найден" >&2
    exit 1
fi

ID=$(od -An -N4 -tx4 /dev/urandom | tr -d ' \n')
if [ -z "$ID" ]; then
    echo "Ошибка: не удалось сгенерировать идентификатор" >&2
    exit 2
fi

if ! exec 9>>"$LOCK"; then
    echo "Ошибка: не удалось открыть '$LOCK'" >&2
    exit 3
fi

file=""

cleanup() {
    [ -n "$file" ] && rm -f "$file"
    exit 0
}

trap cleanup HUP INT QUIT TERM

echo "Контейнер $ID запущен"

count=0
while :; do
    count=$((count + 1))
    content="$ID $count"

    flock -x 9
    i=0
    while :; do
        i=$((i + 1))
        case $i in
            ?) name="00$i" ;;
            ??) name="0$i" ;;
            *) name="$i" ;;
        esac
        [ -e "$DIR/$name" ] || break
    done
    echo "$content" > "$DIR/$name"
    flock -u 9

    file="$DIR/$name"
    echo "$ID: создан $name (#$count)"

    sleep 1

    actual=$(cat "$file" 2>/dev/null)
    if [ "$actual" != "$content" ]; then
        echo "$ID: КОНФЛИКТ в $name: ожидалось '$content', найдено '$actual'" >&2
    fi

    rm -f "$file"
    file=""
    echo "$ID: удалён $name"

    sleep 1
done
