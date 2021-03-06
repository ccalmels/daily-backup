#!/bin/sh

usage() {
    local basename=${0##*/}
    echo "\
usage: $basename rsync <source_dir> <[host:]backup_dir> [<number_of_increment>]
       $basename rotate <YYYY-MM-DD> <[host:]backup_dir> [<number_of_increment>]
       $basename rsync-only <source_dir> <[host:]backup_dir>"
}

backup_rsync() {
    local src="$1"
    local dest="$2"
    local dir="${2##*:}"
    local exclude_file="$src/.backup-exclude"
    local exclude_options

    # remove any trailing '/'
    dir="${dir%%/}"

    [ -r "$exclude_file" ] &&
	exclude_options="--delete-excluded --exclude-from "$exclude_file""

    echo "Rsyncing"
    rsync -ax -H --delete $exclude_options \
	  --link-dest="$dir.1/" "$src/" "$dest/"
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
	if [ "$prev" ]; then
	    mv "$dir$idx" "$dir$prev"
	else
	    rm -rf "$dir$idx"
	fi
	prev="$idx"
    done
}

backup_rotate() {
    local remote="${2%%:*}"
    local dir="${2##*:}"

    if [ "$remote" = "$2" ]; then
	rotate "$1" "$2" "$3"
    else
	ssh "$remote" "sh -s$-" < "$0" rotate "$1" "$dir" "$3"
    fi
}

case "$1" in
    rsync-only)
	backup_rsync "$2" "$3"
	;;
    rotate)
	backup_rotate "$2" "$3" "$4"
	;;
    rsync)
	backup_rotate "$(mday "$2")" "$3" "$4"
	backup_rsync "$2" "$3"
	;;
    *)
	usage
	;;
esac
