##### Поставить каждой покупке свой ранг, который покажет, какой по счету являетсяданная покупка в рамках всей таблицы 

```
SELECT 
      purchase_id, 
      ROW_NUMBER() OVER(ORDER BY date_purchase)
FROM skycinema.client_sign_up

```
##### Поставить каждой покупке свой ранг, который покажет, какой по счету является данная покупка в рамках покупок клиента

```
SELECT user_id,
      purchase_id, 
      date_purchase,
      ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY date_purchase)
FROM skycinema.client_sign_up

```
##### Рассмотрите только первые покупки для каждого клиента:постройте распределение количества первых покупок клиента по полям is_trial и name_partner

```
WITH t1 AS 
(SELECT *,
      ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY date_purchase) AS serial_number
FROM skycinema.client_sign_up)

SELECT is_trial,
       partner,
       COUNT(purchase_id)
FROM t1
WHERE serial_number=1
GROUP by is_trial, partner
```

##### Проставьте ранги покупок в рамках каждого клиента по времени и сгруппируйте полученные результаты

```
WITH t1 AS 
(SELECT *,
      ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY date_purchase) AS serial_number
FROM skycinema.client_sign_up)

SELECT is_trial,
       partner,
       serial_number,
       COUNT(purchase_id)
FROM t1
GROUP by is_trial, partner, serial_number
ORDER BY is_trial DESC, partner, serial_number

```
##### Дополните код таким образом, чтобы у вас получились винтажные доходимости

```
WITH t1 AS 
(SELECT *,
      ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY date_purchase) AS serial_number
FROM skycinema.client_sign_up),

t2 AS 
(SELECT is_trial,
       partner,
       serial_number,
       COUNT(purchase_id) AS amount
FROM t1
GROUP by is_trial, partner, serial_number
ORDER BY is_trial DESC, partner, serial_number)

SELECT partner, 
       SUM(CASE WHEN serial_number=1 THEN amount ELSE 0 END) AS num_1,
       SUM(CASE WHEN serial_number=2 THEN amount ELSE 0 END) AS num_2,
       SUM(CASE WHEN serial_number=3 THEN amount ELSE 0 END) AS num_3,
       SUM(CASE WHEN serial_number=4 THEN amount ELSE 0 END) AS num_4,
       SUM(CASE WHEN serial_number=5 THEN amount ELSE 0 END) AS num_5,
       SUM(CASE WHEN serial_number=6 THEN amount ELSE 0 END) AS num_6
FROM t2
GROUP BY partner
ORDER BY partner
```