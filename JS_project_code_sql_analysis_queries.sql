-- funcations used -count,distinct,sum, max,between, having, joins, group by, order by,case when statements,CTE, create view

-- created a summary table for KPI i.e (number of customer, number of cards, total spend, number of transactions at a monthly level for checking the month on month trend.
SELECT TO_CHAR(transaction_date,'YYYYMM') AS billing_month,COUNT(DISTINCT cust_id) AS num_cust,COUNT(DISTINCT card_10digit) AS num_cards, SUM(transaction_amount) AS spend, COUNT(transaction_id) AS num_transactions 
FROM transactions
GROUP BY 1
ORDER BY 1;

-- I want to analyse the customers who hold more than one card with this credit card company  
SELECT cust_id,first_name,last_name,DOB,count(distinct card_10digit) as num_cards_per_cust
FROM (SELECT a.*,b.card_10digit FROM  customer_pii a
LEFT JOIN transactions b 
ON a.cust_id=b.cust_id) combine
GROUP BY 1,2,3,4
HAVING count(distinct card_10digit)>1
ORDER BY 1;

-- I want to focus on customers who have spent quite less (<=$20) in the last two years(2020,2021). These customers can be used in the marketing campaign to boost spending.
SELECT cust.cust_id,email_id,phone_no, sum(transaction_amount) 
FROM transactions trnx
LEFT JOIN customer_pii cust
ON trnx.cust_id=cust.cust_id
WHERE (transaction_amount BETWEEN 0 and 20) and cast(to_char(transaction_date,'YYYY') as numeric) >=2020 
GROUP by 1,2,3;

-- creted a query to analyze the top merchants basis their spend in each year. 
SELECT merchant_name, TO_CHAR(transaction_date,'YYYY') AS billing_year,
	COUNT(DISTINCT cust_id) AS num_cust,COUNT(DISTINCT card_10digit) AS num_cards,
	SUM(transaction_amount) AS spend, COUNT(transaction_id) AS num_transactions 
FROM (SELECT a.*,b.merchant_name,b.merchant_type 
      FROM transactions A 
	  INNER JOIN merchant B
	  ON A.merchant_ID=B.merchant_ID) a
GROUP BY 1,2
ORDER BY billing_year,spend DESC;

-- creted a query to analyze the total spend bifurcated by online and offline spend in the year 2021.
SELECT merchant_name, SUM(CASE WHEN merchant_type='Online' THEN transaction_amount ELSE 0 END) AS spend_online,
	SUM(CASE WHEN merchant_type='Offline' THEN transaction_amount ELSE 0 END) AS spend_offline
FROM (SELECT a.*,b.merchant_name,b.merchant_type 
      FROM transactions A 
	  INNER JOIN merchant B
	  ON A.merchant_ID=B.merchant_ID) a
WHERE to_char(transaction_date,'YYYY')='2021'
GROUP BY 1
ORDER BY 1;

-- summarised transaction of customers basis their last transaction date.
SELECT b.latest_date,a.cust_id,SUM(transaction_amount) AS spend, 
	COUNT(transaction_id) AS num_transactions
FROM transactions a
INNER JOIN (SELECT cust_id,MAX(transaction_date) AS latest_date FROM transactions GROUP BY 1) b
ON a.cust_id=b.cust_id
GROUP BY 1,2;

-- created a product level summary including number of customer, number of cards, total spend, number of transactions in 2021
-- created a new column "product name" using the following product_tagging
-- product_code	 product_type	product_name
-- ABC	         Charge	         Gold Charge
-- EFG	         Lending	     Platinum Reserve 
-- IJK	         Lending	     Platinum Travel
-- MNO	         Charge	         Centurian Charge
-- QRS	         Lending	     MRCC
-- UVW	         Lending	     SECC
-- XYZ	         Charge	         Platium Charge

SELECT product_name,COUNT(DISTINCT cust_id) AS num_cust,COUNT(DISTINCT card_10digit) AS num_cards,
	COUNT(DISTINCT transaction_id) AS num_of_trans,SUM(transaction_amount) AS spend_2021
FROM transactions A
LEFT JOIN (SELECT *,CASE WHEN product_code='ABC' AND product_type='Charge' THEN 'Gold Charge'
		   				WHEN product_code='EFG' AND product_type='Lending' THEN 'Platinum Reserve'
		   				WHEN product_code='IJK' AND product_type='Lending' THEN 'Platinum Travel'
		   				WHEN product_code='MNO' AND product_type='Charge'  THEN 'Centurian Charge'
		   				WHEN product_code='QRS' AND product_type='Lending' THEN 'MRCC'
		   				WHEN product_code='UVW' AND product_type='Lending' THEN 'SECC'
		   				WHEN product_code='XYZ' AND product_type='Charge'  THEN 'Platinum Charge'
		   				ELSE 'Other' END AS product_name
		   FROM product) B
ON A.product_code=B.product_code
WHERE TO_CHAR(transaction_date,'YYYY')='2021'
GROUP BY 1
ORDER BY spend_2021 DESC;

--Created created a CTE (Common Table Expressions) for identifying the top two online spenders based on the merchant’s name “IKEA” in the year 2021.
WITH IKEA_top2_online_pend_winner_2021 AS (
	SELECT cust_id,merchant_name, SUM(transaction_amount) AS total_spend
	FROM (SELECT a.*,b.merchant_name,b.merchant_type 
      FROM transactions A 
	  INNER JOIN merchant B
	  ON A.merchant_ID=B.merchant_ID) c
	WHERE merchant_name='Ikea' and merchant_type='Online' and to_char(transaction_date,'YYYY')='2021'
	GROUP BY 1,2
)
SELECT a.*, b.first_name,b.last_name,b.email_id,b.phone_no, b.DOB
FROM IKEA_top2_online_pend_winner_2021 a
LEFT JOIN customer_pii b
ON a.cust_id = b.cust_id
ORDER BY total_spend DESC limit 2;


--I created a view for identifying the top five spenders based on the merchant’s name “Walmart” in the year 2021.
CREATE OR REPLACE VIEW walmart_top5_spend_winner_2021 AS
SELECT total_spend.*, cust.first_name,cust.last_name,cust.email_id,cust.phone_no, cust.DOB
FROM (SELECT cust_id,merchant_name, SUM(transaction_amount) AS total_spend 
      FROM transactions A 
	  INNER JOIN merchant B
	  ON A.merchant_ID=B.merchant_ID
	WHERE merchant_name='Walmart' and to_char(transaction_date,'YYYY')='2021'
	GROUP BY 1,2) total_spend
LEFT JOIN customer_pii cust
ON total_spend.cust_id = cust.cust_id
ORDER BY total_spend DESC limit 5;

SELECT * FROM walmart_top5_spend_winner_2021;