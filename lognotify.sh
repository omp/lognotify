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

# Location of the cache and configuration directories.
CACHEDIR="${HOME}/.cache/lognotify"
CONFIGDIR="${HOME}/.config/lognotify"

# At the present, only the first argument is used. This may change later.
IDENTIFIER="$1"

# Load settings from configuration file.
if [ -f "${CONFIGDIR}/${IDENTIFIER}" ]; then
	source "${CONFIGDIR}/${IDENTIFIER}"
else
	echo "$0: configuration file not found" >&2
	exit 1
fi

# Create cache directory, if nonexistent.
if [ ! -d "${CACHEDIR}" ]; then
	echo -n "* Creating cache directory... "
	mkdir -p "${CACHEDIR}"
	echo "Done"
fi

# Create cache file, if nonexistent.
if [ ! -f "${CACHEDIR}/${IDENTIFIER}" ]; then
	echo -n "* Creating cache file for log... "
	touch "${CACHEDIR}/${IDENTIFIER}"
	echo "Done"
fi

# Determine number of lines in cache file.
echo -n "* Determining number of lines in cached log... "
LINES=$(wc -l "${CACHEDIR}/${IDENTIFIER}" | cut -f1 -d' ')
echo "${LINES}"

# Acquire new lines via SSH.
echo -n "* Acquiring new lines via SSH... "
if [ "${LINES}" == 0 ]; then
	COMMAND="cat ${LOGPATH}"
else
	COMMAND="cat ${LOGPATH} | sed -e '1,${LINES}d'"
fi
LOGAPPEND=$(ssh ${SSH_OPTIONS} ${SSH_HOSTNAME} "${COMMAND}")
echo "Done"

# Output new lines, and append them to the cache file.
if [ -n "${LOGAPPEND}" ]; then
	echo "* Number of new lines: $(echo "${LOGAPPEND}" | wc -l)"
	echo "${LOGAPPEND}" | tee -a "${CACHEDIR}/${IDENTIFIER}"
else
	echo "* No new lines in log."
fi
