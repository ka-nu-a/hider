#!/bin/bash
readonly LIST_FILE="./hider.list"
readonly CONFIG_FILE="./hider.conf"

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

echo ${SRC_ROOT}
echo ${DEST_ROOT}

