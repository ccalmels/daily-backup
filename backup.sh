#!/bin/sh

usage() {
    local basename=${0##*/}
    cat <<EOF
usage: $basename rsync <source_dir> <[host:]backup_dir> [<number_of_increment>]
       $basename rotate <YYYY-MM-DD> <[host:]backup_dir> [<number_of_increment>]
       $basename rsync-only <source_dir> <[host:]backup_dir>
EOF
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

mday() {
    local mtime="$(stat -c %y "$1")"

    echo ${mtime%% *}
}

rotate() {
    local day="$1"
    local dir="$(readlink -f "$2")"
    local nb=${3:-5}
    local prev=""
    local idx

    [ -d "$dir" ] || return

    [ "$(mday "$dir")" = "$day" ] && return

    echo "Rotating backup dir"

    for idx in $(seq -f ".%g" $nb -1 1) ""; do
	[ "$prev" ] && mv "$dir$idx" "$dir$prev" \
		|| rm -rf "$dir$idx"
	prev="$idx"
    done
}

backup_rotate() {
    local remote="${2%%:*}"
    local dir="${2##*:}"

    [ "$remote" = "$2" ] && rotate "$1" "$2" "$3" || \
	    ssh "$remote" "sh -s$-" < "$0" rotate "$1" "$dir" "$3"
}

case "$1" in
    rsync-only)
	backup_rsync "$2" "$3"
	;;
    rotate)
	backup_rotate "$2" "$3" "$4"
	;;
    rsync)
	backup_rotate "$(date "+%Y-%m-%d")" "$3" "$4"
	backup_rsync "$2" "$3"
	;;
    *)
	usage
	;;
esac
