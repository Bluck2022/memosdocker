#!/bin/sh
set -e

# 复制配置文件到可写位置
mkdir -p /root/.config/rclone
cp /tmp/rclone.conf /root/.config/rclone/rclone.conf

DATE=$(date +%F)
DUMP_FILE="memos_${DATE}.sql"
LOCAL_DIR="/backup"
REMOTE_DIR="gdrive:memos_backup"   # 改成你的 rclone remote 名称

echo "[$(date)] 开始导出数据库 ..."
mysqldump -h db -u root -p"$MYSQL_ROOT_PASSWORD" \
          --databases memos \
          --single-transaction --quick --routines --triggers \
          > "${LOCAL_DIR}/${DUMP_FILE}"

echo "[$(date)] 上传到 Google Drive ..."
rclone copy "${LOCAL_DIR}/${DUMP_FILE}" "${REMOTE_DIR}/" \
            --config /root/.config/rclone/rclone.conf \
            --drive-use-trash=false \
            --log-level INFO

echo "[$(date)] 云端保留最近 3 份 ..."
rclone delete "${REMOTE_DIR}/" \
            --config /root/.config/rclone/rclone.conf \
            --drive-use-trash=false \
            --min-age 3d --max-depth 1

echo "[$(date)] 本地只保留 1 份 ..."
find "${LOCAL_DIR}" -type f -name 'memos_*.sql' ! -name "${DUMP_FILE}" -delete

echo "[$(date)] 备份完成"
