#!/bin/bash

# Just for running this example from the source dir.
MKPIPE_BIN=./mkpipe
. mkpipe.sh

# pipe for a data
mkpipe 5 6
# pipe for an error info
mkpipe 7 8

({
	echo some data here
	echo error info >&2
	echo yet another data
	echo error again >&2
	exit 1
} 1>&6 2>&8)
ecode=$?
read_all data <&5
read_all emsg <&7

echo "error from the child: $emsg"
echo "data from the child: $data"

# In this case this is not actually needed.
rmpipe 5 6
rmpipe 7 8
