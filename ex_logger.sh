#!/bin/sh

MKPIPE_BIN=./mkpipe
. ./mkpipe.sh

trap "kill -TERM -$$" EXIT
mkpipe2 FD_RERR FD_WERR
mkpipe2 FD_RDBG FD_WDBG
mkpipe2 FD_RCTL FD_WCTL
cmd1='logger -s -t NETIF -p syslog.err "$line"'
cmd2='logger -s -t NETIF -p syslog.notice "$line"'
trap "echo FINISH >&$FD_WCTL" EXIT
({
	eval "exec $FD_WERR>&-"
	eval "exec $FD_WDBG>&-"
	eval "exec $FD_WCTL>&-"
	is_run=2
	while [ "$is_run" -gt 0 ]; do
		if eval 'read -t0 line <&$FD_RCTL'; then
			eval 'read line <&$FD_RCTL'
			if [ "$line" = "FINISH" ]; then
				is_run=0
			fi
		fi
		while eval 'read -t0 line <&$FD_RERR'; do
			eval 'read line <&$FD_RERR'
			if [ -z "$line" ]; then
				is_run=$((is_run-1))
				break
			else
				eval $cmd1
			fi
		done
		while eval 'read -t0 line <&$FD_RDBG'; do
			eval 'read line <&$FD_RDBG'
			if [ -z "$line" ]; then
				is_run=$((is_run-1))
				break
			else
				eval $cmd2
			fi
		done
		sleep 1s
	done
}) &

eval 'exec 2>&$FD_WERR'

echo error message >&2
echo debug info >&$FD_WDBG
