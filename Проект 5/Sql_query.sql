--Задача 1. 

SELECT 
	TO_CHAR(created_datetime, 'YYYY-MM-DD') AS days, --забираем из столбца дату без времени
	COUNT(*)
FROM tasks
WHERE TO_CHAR(created_datetime, 'YYYY-MM') = '2022-06' --указываем интересующий нас месяц и год
GROUP BY days
ORDER BY days

--Задача 2. 

SELECT 
	title,
	COUNT(*) AS amount_of_appeals
FROM tasks
WHERE TO_CHAR(created_datetime, 'YYYY-MM') = '2022-04' –указываем интересующий нас месяц и год
GROUP BY title
HAVING COUNT(*)>10
ORDER BY amount_of_appeals DESC

--Задача 3. 

WITH t1 AS --CTE для того, чтобы вытащить дату последнего обращения каждого клиента
(
SELECT
	client_id,
	max(created_datetime) AS last_appeal_time
FROM tasks
GROUP BY client_id
ORDER BY client_id
)
SELECT 
	t1.client_id
FROM t1
LEFT JOIN calls ON 
	t1.client_id = calls.client_id AND 
	calls.call_datetime> t1.last_appeal_time --звонок менеджера был позже, чем была оставлена заявка
WHERE call_datetime IS NULL

Задача 4. 

WITH t1 AS --CTE для ранжирования заявок клиентов по дате их создания. 1 ранг – самое недавнее
(                    --обращение 
SELECT 
	client_id,
	created_datetime,
	title,
	ROW_NUMBER() OVER(
		PARTITION BY client_id 
		ORDER BY created_datetime DESC) AS rang
FROM tasks
)

SELECT
	title,
	COUNT(*)
FROM t1
WHERE rang BETWEEN 1 AND 3 --условие для вывода последних обращений
GROUP BY title
ORDER BY title

-- Задача 5. 

WITH t1 AS --CTE для определения интервала времени между клиентскими обращениями по темам
(
SELECT
	title,
	created_datetime,
	LEAD(created_datetime) OVER(PARTITION BY title ORDER BY created_datetime) AS lead,
	LEAD(created_datetime) OVER(PARTITION BY title ORDER BY created_datetime) - created_datetime AS delta
FROM tasks
)

SELECT --находим среднее из всех интервалов по темам, предварительно переведя их в часы
	title,
	ROUND(AVG(EXTRACT(epoch FROM delta)/3600)) AS avg_time_between_appeals_hours
FROM t1
GROUP BY title
ORDER BY title

