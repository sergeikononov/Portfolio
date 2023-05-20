/* 
 * Danny's Diner
 * Case Study #1 Questions
 *  
*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT 
	S.CUSTOMER_ID AS C_ID,
	SUM(M.PRICE) AS TOTAL_SPENT
FROM SALES AS S
JOIN MENU AS M ON S.PRODUCT_ID = M.PRODUCT_ID
GROUP BY C_ID
ORDER BY TOTAL_SPENT DESC;

-- Results

c_id|total_spent|
----+-----------+
A   |         76|
B   |         74|
C   |         36|

-- 2. How many days has each customer visited the restaurant?

SELECT 
	CUSTOMER_ID AS C_ID,
	COUNT(DISTINCT ORDER_DATE) AS N_DAYS
FROM SALES
GROUP BY CUSTOMER_ID
ORDER BY N_DAYS DESC;

-- Results

c_id|n_days|
----+------+
B   |     6|
A   |     4|
C   |     2|

-- 3. What was the first item from the menu purchased by each customer?

WITH CTE_FIRST_ORDER AS
	(SELECT S.CUSTOMER_ID AS C_ID,
			M.PRODUCT_NAME,
			ROW_NUMBER() OVER (PARTITION BY S.CUSTOMER_ID ORDER BY S.ORDER_DATE, S.PRODUCT_ID) AS RN
		FROM SALES AS S
		JOIN MENU AS M ON S.PRODUCT_ID = M.PRODUCT_ID)
SELECT C_ID,
	PRODUCT_NAME
FROM CTE_FIRST_ORDER
WHERE RN = 1

-- Results

c_id|product_name|
----+------------+
A   |sushi       |
B   |curry       |
C   |ramen       |

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT M.PRODUCT_NAME,
	COUNT(S.PRODUCT_ID) AS N_PURCHASED
FROM MENU AS M
JOIN SALES AS S ON M.PRODUCT_ID = S.PRODUCT_ID
GROUP BY M.PRODUCT_NAME
ORDER BY N_PURCHASED DESC
LIMIT 1

-- Results

product_name|n_purchased|
------------+-----------+
ramen       |          8|

-- 5. Which item was the most popular for each customer?
WITH CTE_MOST_POPULAR AS
	(SELECT S.CUSTOMER_ID AS C_ID,
			M.PRODUCT_NAME AS P_NAME,
			RANK() OVER (PARTITION BY CUSTOMER_ID ORDER BY COUNT(M.PRODUCT_ID) DESC) AS RNK
		FROM SALES AS S
		JOIN MENU AS M ON S.PRODUCT_ID = M.PRODUCT_ID
		GROUP BY C_ID,
			P_NAME)
SELECT 
	*
FROM CTE_MOST_POPULAR
WHERE RNK = 1;

-- Results

c_id|p_name|rnk|
----+------+---+
A   |ramen |  1|
B   |sushi |  1|
B   |curry |  1|
B   |ramen |  1|
C   |ramen |  1|

-- 6. Which item was purchased first by the customer after they became a member?

WITH CTE_FIRST_MEMBER_PURCHASE AS
	(SELECT M.CUSTOMER_ID AS CUSTOMER,
			M2.PRODUCT_NAME AS PRODUCT,
			RANK() OVER (PARTITION BY M.CUSTOMER_ID ORDER BY S.ORDER_DATE) AS RNK
		FROM MEMBERS AS M
		JOIN SALES AS S ON S.CUSTOMER_ID = M.CUSTOMER_ID
		JOIN MENU AS M2 ON S.PRODUCT_ID = M2.PRODUCT_ID
		WHERE S.ORDER_DATE >= M.JOIN_DATE)
SELECT CUSTOMER,
	PRODUCT
FROM CTE_FIRST_MEMBER_PURCHASE
WHERE RNK = 1;

-- Results

customer|product|
--------+-------+
A       |curry  |
B       |sushi  |

-- 7. Which item was purchased just before the customer became a member?

WITH CTE_LAST_NONMEMBER_PURCHASE AS
	(SELECT M.CUSTOMER_ID AS CUSTOMER,
			M2.PRODUCT_NAME AS PRODUCT,
			RANK() OVER (PARTITION BY M.CUSTOMER_ID ORDER BY S.ORDER_DATE DESC) AS RNK
		FROM MEMBERS AS M
		JOIN SALES AS S ON S.CUSTOMER_ID = M.CUSTOMER_ID
		JOIN MENU AS M2 ON S.PRODUCT_ID = M2.PRODUCT_ID
		WHERE S.ORDER_DATE < M.JOIN_DATE)
SELECT CUSTOMER,
	PRODUCT
FROM CTE_LAST_NONMEMBER_PURCHASE
WHERE RNK = 1;

-- Results

customer|product|
--------+-------+
A       |sushi  |
A       |curry  |
B       |sushi  |

-- 8. What is the total items and amount spent for each member before they became a member?
	
WITH CTE_TOTAL_NONMEMBER_PURCHASE AS
	(SELECT M.CUSTOMER_ID AS CUSTOMER,
			COUNT(M2.PRODUCT_ID) AS TOTAL_ITEMS,
			SUM(M2.PRICE) AS TOTAL_SPENT
		FROM MEMBERS AS M
		JOIN SALES AS S ON S.CUSTOMER_ID = M.CUSTOMER_ID
		JOIN MENU AS M2 ON S.PRODUCT_ID = M2.PRODUCT_ID
		WHERE S.ORDER_DATE < M.JOIN_DATE
		GROUP BY CUSTOMER)
SELECT *
FROM CTE_TOTAL_NONMEMBER_PURCHASE
ORDER BY CUSTOMER;

-- Results

customer|total_items|total_spent|
--------+-----------+-----------+
A       |          2|         25|
B       |          3|         40|
	
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH CTE_TOTAL_MEMBER_POINTS AS
	(SELECT M.CUSTOMER_ID AS CUSTOMER,
			SUM(CASE
					WHEN M2.PRODUCT_NAME = 'sushi' THEN (M2.PRICE * 20)
					ELSE (M2.PRICE * 10)
				END) AS MEMBER_POINTS
		FROM MEMBERS AS M
		JOIN SALES AS S ON S.CUSTOMER_ID = M.CUSTOMER_ID
		JOIN MENU AS M2 ON S.PRODUCT_ID = M2.PRODUCT_ID
		GROUP BY CUSTOMER)
SELECT *
FROM CTE_TOTAL_MEMBER_POINTS

-- Results

customer|member_points|
--------+-------------+
A       |          860|
B       |          940|
	
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- - how many points do customer A and B have at the end of January?	

WITH CTE_JAN_MEMBER_POINTS AS
	(SELECT M.CUSTOMER_ID AS CUSTOMER,
			SUM(CASE
					WHEN s.order_date < m.join_date THEN
						CASE
							WHEN M2.PRODUCT_NAME = 'sushi' THEN (M2.PRICE * 20)
							ELSE (M2.PRICE * 10)
						END
					WHEN S.ORDER_DATE > (m.join_date + 6) THEN 
						CASE
							WHEN M2.PRODUCT_NAME = 'sushi' THEN (M2.PRICE * 20)
							ELSE (M2.PRICE * 10)
						END 
					ELSE (M2.PRICE * 20)	
				END) AS MEMBER_POINTS
		FROM MEMBERS AS M
		JOIN SALES AS S ON S.CUSTOMER_ID = M.CUSTOMER_ID
		JOIN MENU AS M2 ON S.PRODUCT_ID = M2.PRODUCT_ID
		WHERE S.ORDER_DATE <= '2021-01-31'
		GROUP BY CUSTOMER)
SELECT *
FROM CTE_JAN_MEMBER_POINTS
ORDER BY customer;

-- Results

customer|member_points|
--------+-------------+
A       |         1370|
B       |          820|

