/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT  s.customer_id,
		SUM(m.price) total_amount_spend
FROM dannys_diner.menu m
JOIN dannys_diner.sales s
	ON m.product_id = s.product_id
GROUP BY 1
ORDER BY 1;

-- 2. How many days has each customer visited the restaurant?

SELECT  customer_id,
		COUNT(DISTINCT order_date) days_visited
FROM dannys_diner.sales 
GROUP BY 1
ORDER BY 1;

-- 3. What was the first item from the menu purchased by each customer?

WITH CTE as 
			(SELECT  s.customer_id,
				     m.product_name,
             		 ROW_NUMBER() OVER (PARTITION BY s.customer_id order by s.order_date) rolling_sum
			 FROM dannys_diner.menu m
			 JOIN dannys_diner.sales s
				ON m.product_id = s.product_id)
Select customer_id,
	   product_name
From CTE
WHERE rolling_sum = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT  m.product_name,
		COUNT(s.product_id) no_of_time_purchased
FROM dannys_diner.menu m
JOIN dannys_diner.sales s
	ON m.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?

WITH CTE AS 
(SELECT  s.customer_id,
		m.product_name,
		COUNT(m.product_id) no_of_time_purchased,
        DENSE_RANK() OVER(PARTITION BY s.customer_id
        ORDER BY COUNT(s.customer_id) DESC) rolling_count
FROM dannys_diner.menu m
JOIN dannys_diner.sales s
	ON m.product_id = s.product_id
GROUP BY 1,2)
SELECT customer_id,
		product_name,
		no_of_time_purchased
FROM CTE
WHERE rolling_count = 1;


-- 6. Which item was purchased first by the customer after they became a member?

WITH CTE as 
			(SELECT  s.customer_id,
					 m.product_name,
                     ms.join_date,
                     s.order_date,
             		 ROW_NUMBER() OVER (PARTITION BY s.customer_id order by s.order_date) rolling_sum
			 FROM dannys_diner.menu m
			 JOIN dannys_diner.sales s
				ON m.product_id = s.product_id
			JOIN dannys_diner.members ms
				ON s.customer_id = ms.customer_id
			WHERE s.order_date >= ms.join_date) -- limit orders to the ones on the day customer joined or after they joined
Select customer_id,
	   product_name,
       join_date,
	   order_date
From CTE
WHERE rolling_sum = 1;

-- 7. Which item was purchased just before the customer became a member?

WITH CTE as 
			(SELECT  s.customer_id,
					 m.product_name,
                     ms.join_date,
                     s.order_date,
             		 ROW_NUMBER() OVER (PARTITION BY s.customer_id order by s.order_date DESC) rolling_count
			 FROM dannys_diner.menu m
			 JOIN dannys_diner.sales s
				ON m.product_id = s.product_id
			JOIN dannys_diner.members ms
				ON s.customer_id = ms.customer_id
			WHERE s.order_date < ms.join_date) -- limit orders to the ones customer made before they became a member
Select customer_id,
	   product_name,
       join_date,
	   order_date
From CTE
WHERE rolling_count = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT  s.customer_id,
					 COUNT(s.product_id) total_items,
                     SUM(m.price) total_spent
			 FROM dannys_diner.menu m
			 JOIN dannys_diner.sales s
				ON m.product_id = s.product_id
			JOIN dannys_diner.members ms
				ON s.customer_id = ms.customer_id
			WHERE s.order_date < ms.join_date -- limit orders to the ones on the day customer joined or after they joined
			GROUP BY 1
            ORDER BY 1;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT customer_id,
	   SUM(cuisine_point) total_point
FROM
       (SELECT  s.customer_id,
					 m.product_name,
					 CASE 
						WHEN m.product_name = 'sushi' THEN 20 * m.price
                        ELSE 10 * m.price END cuisine_point
			 FROM dannys_diner.menu m
			 JOIN dannys_diner.sales s
				ON m.product_id = s.product_id
			) tt
GROUP BY 1
ORDER BY 1;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


 WITH CTE AS      
			(SELECT  s.customer_id,
					 m.product_name,
                     CASE
						WHEN s.order_date >= ms.join_date AND DAY(s.order_date) < DAY(ms.join_date) + 7 THEN 20*m.price
                        WHEN s.order_date < ms.join_date AND  m.product_name = 'sushi' THEN 20*m.price
					    ELSE 10*m.price END cuisine_point
			 FROM dannys_diner.menu m
			 JOIN dannys_diner.sales s
				ON m.product_id = s.product_id
			 JOIN dannys_diner.members ms
				ON s.customer_id = ms.customer_id
			 WHERE MONTH(s.order_date) <= 1
			)
SELECT customer_id,
	   SUM(cuisine_point) total_point
FROM CTE
GROUP BY 1
ORDER BY 1;