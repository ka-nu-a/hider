#!/bin/bash
readonly LIST_FILE="./hider.list"
readonly CONFIG_FILE="./hider.conf"
readonly PALLALEL_EXEC=16

if (( $# != 1 )); then
  echo "need 1parameter (hide|show)."
	exit 1
elif [[ $1 != "hide" ]] && [[ $1 != "show" ]]; then
  echo "need 1parameter (hide|show)."
	exit 2
fi

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
		return 1
	fi

	# src file exist check
	if [[ ! -e "$1" ]]; then
		echo "ERROR: source directory or file NOT FOUND: \"$1\""
		return 2
	fi

	# dest file exist check
	if [[ -e "$2" ]]; then
		echo "ERROR: destination file IS EXIST: \"$2\""
		return 3
	fi
}

# original file to .tar.gz
# @param src (exists)
# @param dest (not exists .tar.gz)
function hiderHide(){
	hiderCommonCheck "$@"
	if (( $? != 0 )); then
	  return $?
	fi
	tar -zcvfP "$2" "$1" && rm -r "$1"
}

# .tar.gz to original file
# @param src (exists .tar.gz)
# @param dest (not exists)
function hiderShow(){
	hiderCommonCheck "$@"
	if (( $? != 0 )); then
	  return $?
	fi
	tar -zxvfP "$1" -C "/" && rm -r "$1"
}

export -f hiderCommonCheck hiderHide hiderShow

function makeFileList(){
	if (( $# != 4 )); then
		echo "ERROR: readList: arguments length"
		return 1
	fi
	cat "$1" | while read line
	do
		# skip comment line
		if [[ ${line:0:1} == "#" ]]; then
			continue
		fi
		if [[ $2 == "hide" ]]; then
			echo -n ${line} | gawk -v FPAT='([^ ]+)|(\"[^\"]+\")' -v "SRC_ROOT=$3" -v "DEST_ROOT=$4" '{printf "%s%s %s%s\0", SRC_ROOT, $1, DEST_ROOT, $2}'
		elif [[ $2 == "show" ]]; then
			echo -n ${line} | gawk -v FPAT='([^ ]+)|(\"[^\"]+\")' -v "SRC_ROOT=$3" -v "DEST_ROOT=$4" '{printf "%s%s %s%s\0", DEST_ROOT, $2, SRC_ROOT, $1}'
		fi
	done
}

if [[ $1 == "hide" ]]; then
	makeFileList ${LIST_FILE} $1 $SRC_ROOT $DEST_ROOT | xargs -0 -P${PALLALEL_EXEC} -I{} bash -c "hiderHide {}"
elif [[ $1 == "show" ]]; then
	makeFileList ${LIST_FILE} $1 $SRC_ROOT $DEST_ROOT | xargs -0 -P${PALLALEL_EXEC} -I{} bash -c "hiderShow {}"
fi
