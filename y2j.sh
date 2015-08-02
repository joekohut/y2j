#!/usr/bin/env bash

VERSION=1.1

die() {
	echo "$*" 1>&2
	exit 1
}

installer() {
	local target=${1:-/usr/local/bin}
	META_IMAGE=${META_IMAGE:-wildducktheories/y2j}

	cat <<EOF
#!/bin/bash
base64() {
	META_IMAGE=${META_IMAGE}
	BASE64=\$(which base64 2>/dev/null)
	if test -n "\$BASE64"; then
		\$BASE64 "\$@"
	else
		docker run --rm -i \${META_IMAGE} base64 "\$@"
	fi
}
install() {
	local target=\${1:-${target}}
	(
		base64 -D <<EOF_EOF
$(cat "$BASH_SOURCE" | base64)
EOF_EOF
	) | sudo tee \${target}/y2j.sh >/dev/null &&
	sudo chmod ugo+x \${target}/y2j.sh &&
	sudo ln -sf y2j.sh \${target}/y2j &&
	sudo ln -sf y2j.sh \${target}/j2y &&
	sudo ln -sf y2j.sh \${target}/yq &&
	echo "Installed \${target}/{y2h.sh,y2j,j2y,yq}."
}
install "\$@"
EOF
}

version() {
	echo "y2j.sh-${VERSION}"
}


python() {
	PYTHON=$(which python 2>/dev/null)
	if test -n "$PYTHON" && $PYTHON -c 'import sys, yaml, json;' 2>/dev/null; then
		$PYTHON "$@"
	else
		docker run --rm -i ${IMAGE} python "$@"
	fi
}

jq() {
	JQ=$(which jq 2>/dev/null)
	if test -n "$JQ"; then
		"$JQ" "$@"
	else
		docker run --rm -i ${IMAGE} jq "$@"
	fi
}

y2j() {
	if test "$1" = "-d"; then
		shift 1
		j2y "$@"
	else
		python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)'
	fi
}

j2y() {
	if test "$1" = "-d"; then
		shift 1
		y2j "$@"
	else
		python -c 'import sys, yaml, json; yaml.safe_dump(json.load(sys.stdin), sys.stdout, default_flow_style=False)'
	fi
}

y2j_sh() {
	cmd=$1
	shift 1
	case "$cmd" in
		installer|version)
			"$cmd" "$@"
		;;
		*)
			die "unrecognized command: $cmd"
		;;
	esac
}

yq() {
	test $# -gt 0 || die "usage: yq {jq-filter}"
	y2j | jq "$@" | j2y
}

case $(basename "$0") in
	y2j.sh)
		y2j_sh "$@"
	;;
	j2y)
		j2y "$@"
	;;
	y2j)
		y2j "$@"
	;;
	yq)
		yq "$@"
	;;
	*)
		die "unable to determine execution mode - check the name of script - '$(dirname $0)'"
	;;
esac
