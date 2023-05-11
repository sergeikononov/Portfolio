```
WITH first_payments AS --Первая дата успешной(со статусом "success") транзакции из таблицы "payments" для каждого студента
(SELECT user_id, 
        (min(TO_CHAR(transaction_datetime,'YYYY_MM_DD')))::date AS first_payment_date -- Дата первой успешной транзакции
FROM SKYENG_DB.payments
WHERE status_name='success'
GROUP BY user_id
ORDER BY user_id),


all_dates AS --Таблица, которая хранит все дни 2016 года
(SELECT DISTINCT(TO_CHAR(class_start_datetime, 'YYYY-MM-DD'))::date AS dt
FROM SKYENG_DB.classes
WHERE class_status = 'success' AND 
      class_start_datetime>= '2016-01-01' AND 
      class_start_datetime<= '2016-12-31'
ORDER BY 1),


payments_by_dates AS --Таблица со списком успешных транзакции для каждого студента
(SELECT user_id, 
        TO_CHAR(transaction_datetime, 'YYYY-MM-DD')::date AS payment_date, 
        SUM(classes) AS transaction_balance_change
FROM SKYENG_DB.payments
WHERE status_name='success'
GROUP BY user_id, transaction_datetime
ORDER BY 1,2),

all_dates_by_user AS --Таблица с датами жизни студента после первой транзакции
(select user_id, dt::date
from all_dates
join first_payments on all_dates.dt>=first_payments.first_payment_date),

classes_by_date AS --Таблица с изменением баланса из-за проохождения уроков
(SELECT user_id,
    to_char(class_start_datetime, 'YYYY-MM-DD')::date AS class_date,
    -COUNT(user_id) as classes
FROM SKYENG_DB.classes
WHERE class_status IN ('success', 'failed_by_student') AND
      class_type != 'trial'
GROUP BY user_id, to_char(class_start_datetime, 'YYYY-MM-DD') 
ORDER BY  user_id, to_char(class_start_datetime, 'YYYY-MM-DD')),

payments_by_dates_cumsum AS --Таблица с балансом студентов, сформированный только транзакциями
(SELECT  a.user_id,
        a.dt,
        p.transaction_balance_change,
        CASE WHEN SUM(transaction_balance_change) OVER(PARTITION BY a.user_id ORDER BY a.dt) IS NULL THEN 0
             ELSE SUM(transaction_balance_change) OVER(PARTITION BY a.user_id ORDER BY a.dt) END AS transaction_balance_change_cs
FROM all_dates_by_user AS a
LEFT JOIN payments_by_dates AS p ON a.user_id=p.user_id AND  a.dt=p.payment_date),


classes_by_dates_dates_cumsum AS --Таблица, хранящая кумулятивную сумму количества пройденных уроков
(SELECT a.user_id,
       a.dt,
       c.classes,
       CASE WHEN SUM(classes) OVER(PARTITION BY a.user_id ORDER BY a.dt) IS NULL THEN 0
            ELSE SUM(classes) OVER(PARTITION BY a.user_id ORDER BY a.dt) END AS classes_cs
FROM all_dates_by_user AS a
LEFT JOIN classes_by_date AS c ON a.user_id=c.user_id AND  a.dt=c.class_date
ORDER BY a.user_id),

balances AS --Таблица с балансами каждого студента
(SELECT p.user_id,
       p.dt,
       p.transaction_balance_change,
       p.transaction_balance_change_cs,
       c.classes,
       c.classes_cs,
       c.classes_cs+p.transaction_balance_change_cs AS balance
FROM payments_by_dates_cumsum AS p
JOIN classes_by_dates_dates_cumsum AS c ON p.dt=c.dt AND p.user_id=c.user_id
ORDER BY p.user_id)


SELECT --Итоговая таблица с общим количеством уроков на балансах студентов
      dt AS date,
      SUM(transaction_balance_change) AS transaction_balance_change_total,
      SUM(transaction_balance_change_cs) AS transaction_balance_change_cs_total,
      SUM(classes) AS classes_total,
      SUM(classes_cs) AS classes_cs_total,
      SUM(balance) AS balance_total
FROM balances
GROUP BY dt
ORDER BY dt


```