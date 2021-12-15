# path to mkpipe binary
MKPIPE_BIN=${MKPIPE_BIN:-/usr/local/bin/mkpipe}
if [ ! -x "$MKPIPE_BIN" ]; then
	echo "mkpipe binary path is wrong" >&2
	exit 1
fi

# Create a pipe
#  $1 - read fd
#  $2 - write fd
mkpipe()
{
	local PID1 PID2
	local FD_READ FD_WRITE

	FD_READ=$1
	FD_WRITE=$2
	PID=`$MKPIPE_BIN`
	eval "exec $FD_READ</proc/$PID/fd/3 $FD_WRITE>/proc/$PID/fd/4"
	kill $PID
}

# Close a pipe file descriptors(actually any fd, not only pipe fd)
# $1 - read fd
# $2 - write fd
rmpipe()
{
	local FD_READ FD_WRITE

	FD_READ=$1
	FD_WRITE=$2
	eval "exec $FD_READ<&- $FD_WRITE>&-"
}

# Read all data from stdin
# $1 - variable name
read_all()
{
        eval "local ${1}_"

        eval "$1=\"\""
        while eval "read -t0 ${1}_"; do
                eval "read ${1}_"
                eval "$1=\"\${${1}}\${${1}_}
\""
        done
}
