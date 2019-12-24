#!/bin/sh

usage() {
    echo usage: ${0##*/}
}

backup_rsync() {
    local src="$1"
    local remote="${2%%:*}:"
    local dir="${2##*:}"

    # remove any trailing '/'
    dir="${dir%%/}"
    [ "$remote" = "$2:" ] && remote=""

    echo "Rsyncing"
    rsync -ax -H --delete --delete-excluded \
	  --exclude-from "$src/.backup-exclude" \
	  --link-dest="$dir.1/" "$src/" "$remote$dir/"
}

check_dir() {
    local dir="$1"
    local DATE
    local FDATE

    [ -d "$1" ] || return 0

    DATE=$(date "+%Y-%m-%d")
    FDATE=$(stat -c %y "$dir")
    FDATE=${FDATE%% *}

    echo "backup date:$FDATE system date:$DATE"

    [ "${DATE}" = "${FDATE}" ]
}

rotate() {
    local dir=$(readlink -f "$1")
    local nb="5"
    local prev=""
    local idx

    check_dir "$dir" && return

    echo "Rotating backup dir"

    for idx in $(seq -f ".%g" $nb -1 1) ""; do
	[ "$prev" ] && mv "$dir$idx" "$dir$prev" \
		|| rm -rf "$dir$idx"
	prev="$idx"
    done
}

backup_rotate() {
    local remote="${1%%:*}"

    [ "$remote" = "$1" ] && rotate "$1" || \
	    ssh "$remote" "sh -s" < $(readlink -f $0) rotate "${1##*:}"
}

case "$1" in
    rsync-only)
	backup_rsync "$2" "$3"
	;;
    rotate)
	backup_rotate "$2"
	;;
    rsync)
	backup_rotate "$3"
	backup_rsync "$2" "$3"
	;;
    *)
	usage
	;;
esac
