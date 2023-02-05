INSERT INTO t_teacher_lesson_fee
SELECT 
    t.teacher_id as teacher_id,
    '202301',
    now() as create_datetime,
    'CRON BATCH' as create_user_id,
    now() as update_datetime,
    'CRON BATCH' as update_user_id,
    '0' as stop_flg,
    '0' as delete_flg,
    lfl.unit_price as lesson_fee,
    COUNT(t.teacher_id) as lesson_couont,
    (lfl.unit_price * COUNT(t.teacher_id)) as billing_amount,
    10 as tax,
    '0' as billed_flg,
    null as billed_datetime
FROM m_teacher as t 
LEFT JOIN t_lesson_teacher as lt ON t.teacher_id = lt.teacher_id
LEFT JOIN t_lesson as l ON l.lesson_id = lt.lesson_id
LEFT JOIN m_lesson_fee_list as lfl ON t.rank_id = lfl.rank_id
WHERE l.start_datetime BETWEEN '2023-01-01 00:00:00' AND '2023-01-31 23:59:59'
AND l.end_datetime BETWEEN '2023-01-01 00:00:00' AND '2023-01-31 23:59:59'
GROUP BY t.teacher_id,lfl.unit_price;