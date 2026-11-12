#!/bin/sh

IMAGE=lab2-worker
VOLUME=lab2-shared
PREFIX=lab2-worker-

cd "$(dirname "$0")" || exit 1

stop_all() {
    ids=$(docker ps -aq --filter "name=^$PREFIX")
    if [ -n "$ids" ]; then
        docker stop -t 5 $ids > /dev/null
        docker rm $ids > /dev/null
    fi
    echo "Контейнеры остановлены"
}

case "${1:-1}" in
    stop)
        stop_all
        exit 0
        ;;
    check)
        conflicts=0
        for c in $(docker ps -aq --filter "name=^$PREFIX"); do
            n=$(docker logs "$c" 2>&1 | grep -c 'КОНФЛИКТ')
            conflicts=$((conflicts + n))
        done
        echo "Файлы в томе:"
        docker run --rm -v "$VOLUME:/data" alpine:3.20 \
            sh -c 'cd /data && for f in [0-9]*; do [ -f "$f" ] && echo "  $f: $(cat "$f")"; done'
        echo "Конфликтов в логах: $conflicts"
        [ "$conflicts" -eq 0 ]
        exit $?
        ;;
    *[!0-9]* | 0)
        echo "Использование: $0 [N | stop | check]" >&2
        exit 1
        ;;
esac

n=$1

docker build -q -t "$IMAGE" . > /dev/null || {
    echo "Ошибка: не удалось собрать образ" >&2
    exit 2
}

docker volume create "$VOLUME" > /dev/null || exit 3

stop_all
docker run --rm -v "$VOLUME:/data" alpine:3.20 sh -c 'rm -f /data/[0-9]* /data/.lock'

i=1
while [ "$i" -le "$n" ]; do
    docker run -d --name "$PREFIX$i" -v "$VOLUME:/data" "$IMAGE" > /dev/null || exit 4
    i=$((i + 1))
done

echo "Запущено контейнеров: $n (том $VOLUME)"
