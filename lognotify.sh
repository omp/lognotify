#!/bin/bash
#
# lognotify.sh
# http://github.com/omp/lognotify
#
# Copyright 2010 David Vazgenovich Shakaryan <dvshakaryan@gmail.com>
# Distributed under the terms of the GNU General Public License v3.
# See http://www.gnu.org/licenses/gpl.txt for the full license text.
#
# Retrieve additions to remote log files via SSH. Log files are cached locally
# and only new lines are fetched from the server.

CACHEDIR="${HOME}/.cache/lognotify"
CONFIGDIR="${HOME}/.config/lognotify"

if [ $# != 1 ]; then
	echo "$0: incorrect number of arguments" >&2
	exit 1
fi

IDENTIFIER="$1"

if [ -f "${CONFIGDIR}/${IDENTIFIER}" ]; then
	source "${CONFIGDIR}/${IDENTIFIER}"
else
	echo "$0: configuration file for specified identifier not found" >&2
	exit 1
fi

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
	LOGAPPEND=$(ssh ${SSH_OPTIONS} ${SSH_HOSTNAME} "cat ${LOGPATH}")
else
	LOGAPPEND=$(ssh ${SSH_OPTIONS} ${SSH_HOSTNAME} "cat ${LOGPATH} | sed -e '1,${LINES}d'")
fi
echo "Done"

if [ -n "${LOGAPPEND}" ]; then
	echo "* Number of new lines: $(echo "${LOGAPPEND}" | wc -l)"
	echo "${LOGAPPEND}" | tee -a "${CACHEDIR}/${IDENTIFIER}"
else
	echo "* No new lines in log."
fi
