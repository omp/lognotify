#!/bin/bash
#
# Copyright 2010 David Vazgenovich Shakaryan <dvshakaryan@gmail.com>
# Distributed under the terms of the GNU General Public License v3

if [ $# != 3 ]; then
	echo "$0: incorrect number of arguments" >&2
	exit 1
fi

IDENTIFIER="$1"
SERVER="$2"
LOGPATH="$3"

CACHEDIR="${HOME}/.cache/lognotify"

# Setup cache directory if nonexistent.
if [ ! -d "${CACHEDIR}" ]; then
	echo -n "* Creating cache directory... "
	mkdir -p "${CACHEDIR}"
	echo "Done"
fi

if [ ! -f "${CACHEDIR}/${IDENTIFIER}" ]; then
	echo -n "* Creating cache file for log... "
	touch "${CACHEDIR}/${IDENTIFIER}"
	echo "Done"
fi

echo -n "* Determining number of lines in cached log... "
LINES=$(wc -l "${CACHEDIR}/${IDENTIFIER}" | cut -f1 -d' ')
echo "${LINES}"

echo -n "* Acquiring new lines via SSH... "
if [ "${LINES}" == 0 ]; then
	LOGAPPEND=$(ssh ${SERVER} "cat ${LOGPATH}")
else
	LOGAPPEND=$(ssh ${SERVER} "cat ${LOGPATH} | sed -e '1,${LINES}d'")
fi
echo "Done"

if [ -n "${LOGAPPEND}" ]; then
	echo "* Number of new lines: $(echo "${LOGAPPEND}" | wc -l)"
	echo
	echo "${LOGAPPEND}" | tee -a "${CACHEDIR}/${IDENTIFIER}"
else
	echo "* No new lines found."
fi
