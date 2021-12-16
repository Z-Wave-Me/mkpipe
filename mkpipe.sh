# path to mkpipe binary
MKPIPE_BIN=${MKPIPE_BIN:-/usr/local/bin/mkpipe}
if [ ! -x "$MKPIPE_BIN" ]; then
	echo "mkpipe binary path is wrong" >&2
	exit 1
fi

# Create a pipe
#  $1 - read fd
#  $2 - write fd
#  $3 - mkpipe options
# A second line from mkpipe output is placed into RET.
mkpipe()
{
	local PID
	local FD_READ FD_WRITE
	local MKPIPE_OPTS="$3"
	local ret_

	FD_READ=$1
	FD_WRITE=$2
	PID=`$MKPIPE_BIN $MKPIPE_OPTS`
	ret_=`echo "$PID" | sed -ne '2 p'`
	PID=`echo "$PID" | sed -ne '1 p'`
	eval "exec $FD_READ</proc/$PID/fd/3 $FD_WRITE>/proc/$PID/fd/4"
	kill $PID
	RET="$ret_"
}

# Create a pipe(allocate first two free fd for pipe ends)
#  $1 - var name where read fd will be saved
#  $2 - var name where write fd will be saved
#  $3 - mkpipe options
# Save into RET var read fd and write fd separated with space character,
# and a second line from mkpipe output is placed into RET second line.
mkpipe2()
{
	local MKPIPE_OPTS="$3"
	local MYPID PID FDS
	local FD_READ FD_WRITE
	local ret_

	if [ -z "$1" ]; then
		echo "A variable name for read fd isn't specified" >&2
		exit 1
	fi
	if [ -z "$2" ]; then
		echo "A variable name for write fd isn't specified" >&2
		exit 1
	fi
	# Search a first empty fd
	# We can't use $$, because $$ in a subshell is equal to parent pid instead
	# of subshell pid.
	MYPID=`exec sh -c 'echo $PPID'`
	# TODO: Do we need some boundary for max fd number to suppress endless loop?
	# Search read fd. Start from 3
	FD_READ=3
	while true; do
		[ -e "/proc/$MYPID/fd/$FD_READ" ] || break
		FD_READ=$((FD_READ+1))
	done
	# Search write fd. Start from found read fd.
	FD_WRITE=$((FD_READ+1))
	while true; do
		[ -e "/proc/$MYPID/fd/$FD_WRITE" ] || break
		FD_WRITE=$((FD_WRITE+1))
	done

	PID=`$MKPIPE_BIN $MKPIPE_OPTS`
	ret_=`echo "$PID" | sed -ne '2 p'`
	PID=`echo "$PID" | sed -ne '1 p'`
	eval "exec $FD_READ</proc/$PID/fd/3 $FD_WRITE>/proc/$PID/fd/4"
	kill $PID
	RET="$ret_"
	mkpipe2_set_pipefds_ $1 $FD_READ $2 $FD_WRITE
}

mkpipe2_set_pipefds_()
{
	eval "$1=$2; $3=$4"
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
