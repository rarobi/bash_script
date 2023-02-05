#!/bin/sh

SERVER_APP_DB_DATABASE=ksco_stg_db


MYSQL_SCHEMA="ksco_stg_db"
ROOT_DIRECTORY="/home/robi/"
LOG="${ROOT_DIRECTORY}batch/log/batch_exec.log"
CMD_MYSQL="mysql --defaults-extra-file=${ROOT_DIRECTORY}batch/mysql.conf -t --show-warnings $MYSQL_SCHEMA"
echo $(date "+%Y/%m/%d %H:%M:%S") >>$LOG 2>&1
echo "[INFO] 処理開始" >>$LOG 2>&1

startOfLastMonth=$(date --date="$(date +'%Y-%m-01') - 1 month" +"%Y-%m-%d %H:%M:%S");
endOfLastMonth=$(date --date="$(date +'%Y-%m-01') - 1 second" +"%Y-%m-%d %H:%M:%S");
yearMonth=$(date --date="$(date +'%Y-%m-01') - 1 month" +"%Y%m");
stop_flg=0;
delete_flg=0;
billed_flg=0;
echo $yearMonth

# SQLの実行
# 複数のクエリを発行する場合は、
# 複数行の文字列にクエリをセミコロン(;)で繋げて指定する
cat <<-EOF > ${ROOT_DIRECTORY}batch/query.sql
INSERT INTO t_teacher_lesson_fee
SELECT 
    t.teacher_id as teacher_id,
    '${yearMonth}',
    now() as create_datetime,
    'CRON BATCH' as create_user_id,
    now() as update_datetime,
    'CRON BATCH' as update_user_id,
    '${stop_flg}' as stop_flg,
    '${delete_flg}' as delete_flg,
    lfl.unit_price as lesson_fee,
    COUNT(t.teacher_id) as lesson_couont,
    (lfl.unit_price * COUNT(t.teacher_id)) as billing_amount,
    10 as tax,
    '${billed_flg}' as billed_flg,
    null as billed_datetime
FROM m_teacher as t 
LEFT JOIN t_lesson_teacher as lt ON t.teacher_id = lt.teacher_id
LEFT JOIN t_lesson as l ON l.lesson_id = lt.lesson_id
LEFT JOIN m_lesson_fee_list as lfl ON t.rank_id = lfl.rank_id
WHERE l.start_datetime BETWEEN '${startOfLastMonth}' AND '${endOfLastMonth}'
AND l.end_datetime BETWEEN '${startOfLastMonth}' AND '${endOfLastMonth}'
GROUP BY t.teacher_id,lfl.unit_price;

EOF
echo ${CMD_MYSQL}
VALUE=$(${CMD_MYSQL} < ${ROOT_DIRECTORY}batch/query.sql)

# 処理の終了コードを取得
RESULT=$?
echo $(date "+%Y/%m/%d %H:%M:%S") >>$LOG 2>&1
# 結果のチェック
if [ $RESULT -eq 0 ]; then
    echo "[INFO] 処理終了" >>$LOG 2>&1
    exit 0
else
    echo "[ERROR] 予期せぬエラーが発生 異常終了" >>$LOG 2>&1
    exit 1
fi


exit
