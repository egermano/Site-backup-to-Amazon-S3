#!/bin/sh

# Updates etc at: https://github.com/woxxy/MySQL-backup-to-Amazon-S3
# Under a MIT license

# change these variables to what you need
S3BUCKET=mybuacket
FILENAME=filename
TARGETFOLDER=/var/www/
# the following line prefixes the backups with the defined directory. it must be blank or end with a /
S3PATH=site_backup/
#tmp path.
TMP_PATH=~/

DATESTAMP=$(date +".%m.%d.%Y")
DAY=$(date +"%d")
DAYOFWEEK=$(date +"%A")

PERIOD=${1-day}
if [ ${PERIOD} = "auto" ]; then
        if [ ${DAY} = "01" ]; then
                PERIOD=month
        elif [ ${DAYOFWEEK} = "Sunday" ]; then
                PERIOD=week
        else
                PERIOD=day
        fi        
fi

echo "Starting compression..."

# tar cvzf /mnt/tmp/ibab.com.brtest.tar.gz /mnt/www/ibab.com.br/
tar cvzf ${TMP_PATH}${FILENAME}${DATESTAMP}.tar.gz ${TARGETFOLDER}

echo "Done compressing the backup file."

# we want at least two backups, two months, two weeks, and two days
echo "Removing old backup (2 ${PERIOD}s ago)..."
s3cmd del --recursive s3://${S3BUCKET}/${S3PATH}previous_${PERIOD}/
echo "Old backup removed."

echo "Moving the backup from past $PERIOD to another folder..."
s3cmd mv --recursive s3://${S3BUCKET}/${S3PATH}${PERIOD}/ s3://${S3BUCKET}/${S3PATH}previous_${PERIOD}/
echo "Past backup moved."

# upload all databases
echo "Uploading the new backup..."
s3cmd put -f ${TMP_PATH}${FILENAME}${DATESTAMP}.tar.gz s3://${S3BUCKET}/${S3PATH}${PERIOD}/
echo "New backup uploaded."

echo "Removing the cache files..."
# remove databases dump
rm ${TMP_PATH}${FILENAME}${DATESTAMP}.tar.gz
echo "Files removed."
echo "All done."