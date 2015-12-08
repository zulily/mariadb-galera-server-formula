#!/bin/bash
#
# Copyright (C) 2015 zulily, llc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# xtra_full_backup.sh - a simple script to generate and prepare a backup of all databases
# using xtrabackup
#

BACKUP_NAME="db-all-"`hostname -f`"-"`date +%Y.%m.%d-%H.%M`
BACKUP_TOP_DIR=/backups/db/
DEST_DIR=${BACKUP_TOP_DIR}${BACKUP_NAME}/
BACKUP_FILE=${BACKUP_TOP_DIR}${BACKUP_NAME}.tar.gz

mkdir -p $DEST_DIR

# Perform the backup
/usr/bin/env xtrabackup --backup --target-dir=$DEST_DIR

# Prepare, *twice*
/usr/bin/env xtrabackup --prepare --target-dir=$DEST_DIR
/usr/bin/env xtrabackup --prepare --target-dir=$DEST_DIR

tar cvzf $BACKUP_FILE $DEST_DIR

# Some basic checks to make sure we don't nuke something we shouldn't...
if [ -s $BACKUP_FILE ] && [ -d $DEST_DIR ] && [ "$BACKUP_TOP_DIR" != "$DEST_DIR" ]; then
    rm -rf $DEST_DIR
fi

