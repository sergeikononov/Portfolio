### Формулировка задачи. 
---
Клиенты оставляют заявки на звонок, после чего менеджеры звонят и обсуждают все необходимые вопросы. 

Есть 2 таблицы с данными. В таблице tasks лежат заявки от клиентов, в таблице calls лежат звонки от менеджеров клиентам.

Таблица tasks
* client_id (идентификатор клиента)
* created_datetime (время клиентской заявки)
* title (тема обращения)

Таблица calls

* manager_id (идентификатор менеджера)
* client_id (идентификатор клиента, которому звонят)
* call_datetime (время менеджерского звонка)

### Логика работы с таблицами. 
---

Каждому клиенту присваивается уникальный идентификатор (client_id). Клиент может оставить одну или несколько заявок с разными темами, которые далее за один звонок обрабатываются менеджером. Строка в таблице «calls» появляется после или во время звонка менеджера клиенту, если звонка не было – строка не создается. 

### Таблицы и наполнение. 
___
```
CREATE TABLE tasks
(
	client_id int, 
	created_datetime timestamp,
	title text
);

CREATE TABLE calls
(
	manager_id int, 
	client_id int, 
	call_datetime timestamp
);
```
Для колонок со временем поступления заявки и звонка менеджера выбрал тип timestamp – дата + время без временной зоны. 

#### Задание 1. Сколько заявок приходило каждый день в июне 2022 года?
___
```
SELECT 
	TO_CHAR(created_datetime, 'YYYY-MM-DD') AS days, --забираем из столбца дату без времени
	COUNT(*)
FROM tasks
WHERE TO_CHAR(created_datetime, 'YYYY-MM') = '2022-06' --указываем интересующий нас месяц и год
GROUP BY days
ORDER BY days

```
#### Задание 2.  Список тем, для которых обращений было больше 10 в апреле 2022 года. 
___
```
SELECT 
	title,
	COUNT(*) AS amount_of_appeals
FROM tasks
WHERE TO_CHAR(created_datetime, 'YYYY-MM') = '2022-04' –указываем интересующий нас месяц и год
GROUP BY title
HAVING COUNT(*)>10
ORDER BY amount_of_appeals DESC

```
#### Задание 3.  Список клиентов, которые оставляли заявку, но ни одного звонка от менеджера по ним не было.  
---
В таблице calls нет информации по какой заявке клиента звонит менеджер. Будем считать, что при звонке менеджер выгружает все заявки по client_id и обрабатывает из все разом. Поэтому в запросе  нужно вывести клиентов, которым либо не звонили вовсе, либо последний звонок менеджера был раньше, чем последняя оставленная клиентом заявка. 

Например, клиент 1 оставил заявку 1 января и 2 января с ним связался менеджер– такой клиент не должен появиться в нашем списке. Клиент 2 оставил заявки 1 января и 3 января, с ним связывался менеджер  только 2 января – заявка от 3 января осталась необработанной – такой клиент должен появиться в списке. 
```
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

```
#### Задание 4.  Для каждого клиента выведите три его последних обращения и постройте распределение количества этих обращений по теме. 
---
```
WITH t1 AS --CTE для ранжирования заявок клиентов по дате их создания. 1 ранг -самое недавнее
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

```
#### Задание 5.  Для каждой темы обращения найдите среднее время, которое проходит между клиентскими обращениями. 
___
```
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
```