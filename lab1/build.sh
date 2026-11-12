#!/bin/sh

if [ $# -ne 1 ]; then
    echo "Использование: $0 файл" >&2
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "Ошибка: файл '$1' не найден" >&2
    exit 2
fi

src_dir=$(cd "$(dirname "$1")" && pwd)
src_name=$(basename "$1")
src="$src_dir/$src_name"

out=$(grep -m 1 'Output:' "$src" | sed 's/.*Output:[[:space:]]*\([^[:space:]]*\).*/\1/')

if [ -z "$out" ]; then
    echo "Ошибка: в файле нет комментария 'Output: имя'" >&2
    exit 3
fi

tmp_dir=""

cleanup() {
    rm -rf "$tmp_dir"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 131' QUIT
trap 'exit 143' TERM

tmp_dir=$(mktemp -d) || {
    echo "Ошибка: не удалось создать временный каталог" >&2
    exit 5
}

cd "$tmp_dir" || exit 5
TMPDIR="$tmp_dir"
export TMPDIR

case "$src_name" in
    *.c)
        cc "$src" -o "$out"
        ;;
    *.cpp | *.cc | *.cxx)
        c++ "$src" -o "$out"
        ;;
    *.tex)
        TEXINPUTS="$src_dir:" pdflatex -interaction=nonstopmode -halt-on-error \
            "$src" > /dev/null &&
        mv "${src_name%.tex}.pdf" "$out"
        ;;
    *)
        echo "Ошибка: неизвестный тип файла '$src_name'" >&2
        exit 4
        ;;
esac

if [ $? -ne 0 ]; then
    echo "Ошибка: не удалось собрать '$src_name'" >&2
    exit 6
fi

if ! cp "$out" "$src_dir/$out"; then
    echo "Ошибка: не удалось скопировать '$out'" >&2
    exit 7
fi

echo "Готово: $src_dir/$out"
exit 0
