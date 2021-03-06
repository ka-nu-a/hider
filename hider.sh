#!/bin/bash
readonly LIST_FILE="./hider.list"
readonly CONFIG_FILE="./hider.conf"
readonly PALLALEL_EXEC=16

if [ -e ${CONFIG_FILE} ]; then
	. ${CONFIG_FILE}
else
	echo "can not find ${CONFIG_FILE}. created."
	cat << \
EOT >> ${CONFIG_FILE}
SRC_ROOT=
DEST_ROOT=
EOT
fi
if [ ! -e ${LIST_FILE} ]; then
	cat << \
EOT >> ${LIST_FILE}
# format
# src dest
# 
# source path is under the [SRC_ROOT]. can use abs path, then only undefined src_root at hider.conf.
# destination path is under the [DEST_ROOT]. can use abs path, then only undefined dest_root at hider.conf.

EOT
	file_created+=( ${LIST_FILE} )
	echo "can not find ${LIST_FILE}. exit..."
	exit 1
fi

if (( $# != 1 )); then
  echo "need 1parameter ([h]ide|[s]how)."
	exit 2
elif [[ $1 != "hide" ]] && [[ $1 != "show" ]] && [[ $1 != "h" ]] && [[ $1 != "s" ]]; then
  echo "need 1parameter ([h]ide|[s]how)."
	exit 3
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
	tar -zcvPf "$2" "$1" && rm -r "$1"
}

# .tar.gz to original file
# @param src (exists .tar.gz)
# @param dest (not exists)
function hiderShow(){
	hiderCommonCheck "$@"
	if (( $? != 0 )); then
	  return $?
	fi
	tar -zxvPf "$1" -C "/" && rm -r "$1"
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
		if [[ $2 == "hide" ]] || [[ $2 == "h" ]]; then
			echo -n ${line} | gawk -v FPAT='([^ ]+)|(\"[^\"]+\")' -v "SRC_ROOT=$3" -v "DEST_ROOT=$4" '{printf "%s%s %s%s\0", SRC_ROOT, $1, DEST_ROOT, $2}'
		elif [[ $2 == "show" ]] || [[ $2 == "s" ]]; then
			echo -n ${line} | gawk -v FPAT='([^ ]+)|(\"[^\"]+\")' -v "SRC_ROOT=$3" -v "DEST_ROOT=$4" '{printf "%s%s %s%s\0", DEST_ROOT, $2, SRC_ROOT, $1}'
		fi
	done
}

if [[ $1 == "hide" ]] || [[ $1 == "h" ]]; then
	makeFileList ${LIST_FILE} $1 $SRC_ROOT $DEST_ROOT | xargs -0 -P${PALLALEL_EXEC} -I{} bash -c "hiderHide {}"
elif [[ $1 == "show" ]] || [[ $1 == "s" ]]; then
	makeFileList ${LIST_FILE} $1 $SRC_ROOT $DEST_ROOT | xargs -0 -P${PALLALEL_EXEC} -I{} bash -c "hiderShow {}"
fi
