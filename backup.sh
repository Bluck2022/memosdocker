#!/bin/sh
set -euo pipefail

TODAY=$(date +%F)
YESTERDAY=$(date -u -d "@$(($(date -u +%s) - 86400))" +%F)
SEVEN_DAYS_AGO=$(date -u -d "@$(($(date -u +%s) - 7*86400))" +%F)

LOCAL_DIR="/tmp"
BACKUP_FILE="${LOCAL_DIR}/memos_${TODAY}.sql.gz"

echo "[$(date)] 开始导出数据库 ..."
mysqldump -h db -u root -p"${MYSQL_ROOT_PASSWORD}" \
          --single-transaction --databases memos | gzip > "$BACKUP_FILE"

echo "[$(date)] 上传到 Google Drive ..."
rclone copy "$BACKUP_FILE" gdrive:memos_backup/

echo "[$(date)] 清理 Google Drive：保留今天、昨天、7 天前"
KEEP_LIST="memos_${TODAY}.sql.gz memos_${YESTERDAY}.sql.gz memos_${SEVEN_DAYS_AGO}.sql.gz"
for f in $(rclone lsf gdrive:memos_backup/); do
    printf '%s\n' $KEEP_LIST | grep -qw "$f" || rclone delete "gdrive:memos_backup/$f"
done

echo "[$(date)] 清理本地：只留最新 1 份"
find "$LOCAL_DIR" -maxdepth 1 -type f -name 'memos_*.sql.gz' ! -name "memos_${TODAY}.sql.gz" -delete

echo "[$(date)] 备份完成"
