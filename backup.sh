#!/bin/sh

usage() {
	echo usage: ${0##*/}
}

backup_rsync() {
	local src="$1"
	local remote="${2%%:*}:"
	local dst="${2##*:}"

	# remove any trailing '/'
	dst="${dst%%/}"
	[ "$remote" = "$2:" ] && remote=""

	echo "Rsyncing"
	rsync -ax -H --delete --delete-excluded \
	      --exclude-from "$src/.backup-exclude" \
	     --link-dest="$dst.1/" "$src/" "$remote$dst/"
}

check_dir() {
	local dir="$1"
	local DATE
	local FDATE
	local DATE_FMT="+%d-%m-%y"

	[ -d "$1" ] || return 0

	DATE=$(date "$DATE_FMT")
	FDATE=$(date -d @$(stat -c %Z "$dir") "$DATE_FMT")

	[ "x${DATE}" = "x${FDATE}" ]
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
