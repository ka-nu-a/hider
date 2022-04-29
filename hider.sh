#!/bin/bash
readonly LIST_FILE="./hider.list"
readonly CONFIG_FILE="./hider.conf"
readonly PALLALEL_EXEC=16

if [ ! -e ${LIST_FILE} ]; then
	echo "can not find ${LIST_FILE} exit..."
	exit 1
fi

if [ -e ${CONFIG_FILE} ]; then
	. ${CONFIG_FILE}
fi
if [ ! -v SRC_ROOT ]; then
	readonly SRC_ROOT=""
fi
if [ ! -v DEST_ROOT ]; then
	readonly DEST_ROOT=""
fi

#echo SRC_ROOT:${SRC_ROOT}
#echo DEST_ROOT:${DEST_ROOT}

function hiderCommonCheck(){
	# arguments length check
	if (( $# != 2 )); then
		if (( $# < 2 )); then
		echo "ERROR: too few arguments to function."
		fi
		if (( $# > 2 )); then
			echo "ERROR: too many arguments to function."
		fi
		exit 1
	fi

	# src file exist check
	if [ ! -e "$1" ]; then
		echo "ERROR: source directory or file NOT FOUND: \"$1\""
		exit 2
	fi

	# dest file exist check
	if [ -e "$2" ]; then
		echo "ERROR: destination file IS EXIST: \"$2\""
		exit 3
	fi
}

# original file to .tar.gz
# @param src(cant exists)
# @param dest (.tar.gz)
function hiderHide(){
	hiderCommonCheck "$@"
	ls "$1"
}

# .tar.gz to original file
# @param dest(cant exists)
# @param src(.tar.gz)
function hiderShow(){
	hiderCommonCheck "$@"
	ls "$2"
}

export -f hiderCommonCheck hiderHide hiderShow

echo -en "\"${SRC_ROOT}/src path1\" \"${DEST_ROOT}/dest_path1\"\0\"${SRC_ROOT}/src_path2\" \"${DEST_ROOT}/dest_path2\"\0" | xargs -0 -P${PALLALEL_EXEC} -I{} bash -c "hiderHide {}"
