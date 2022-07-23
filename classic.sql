SHOW DATABASES;
USE classicmodels;
SHOW TABLES;


/*---JOIN TABLES TO GET THE TOP BUYERS NAMES AND USE OF ROW_NUMBER WINDOW FUNCTION---*/

SELECT ROW_NUMBER() OVER(ORDER BY SUM(payments.amount) DESC) AS rank_,
	   customers.customerName, customers.contactLastName, customers.contactFirstName, customers.city,
       customers.country,
	   SUM(payments.amount) AS sumAmount
FROM customers
    JOIN payments ON payments.customerNumber = customers.customerNumber
GROUP BY customers.customerName
ORDER BY sumAmount DESC;


/*---MULTIPLE JOINS TO GET THE MAX QUANTITY ORDERED PRODUCT BY COUNTRY BY PURCHASE---*/

SELECT country,
       productName,
       maxQuantitySales
FROM
(SELECT customers.country,
       products.productName,
       MAX(orderdetails.quantityOrdered) AS maxQuantitySales,
       ROW_NUMBER() OVER(PARTITION BY country ORDER BY MAX(orderdetails.quantityOrdered) DESC)
       AS rank_
FROM orders
    JOIN customers ON customers.customerNumber = orders.customerNumber
    JOIN orderdetails ON orderdetails.orderNumber = orders.orderNumber
    JOIN products ON products.productCode = orderdetails.productCode
GROUP BY customers.country,
         products.productName) AS tab
WHERE rank_ = 1
ORDER BY maxQuantitySales DESC;


/*---CTE TABLE WITH MULTIPLE JOINS AND USE OF DENSE_RANK() WINDOW FUNCTION TO GET THE TOP 3
     TOTAL QUANTITY ORDERED PRODUCT NAMES BY COUNTRY---*/
     
WITH CTE (prodName, cntry, sumQtity)
AS
(SELECT products.productName,
	   customers.country, 
       SUM(orderdetails.quantityOrdered) AS sumQuantity
FROM orders
    JOIN orderdetails ON orderdetails.orderNumber = orders.orderNumber
    JOIN products ON products.productCode = orderdetails.productCode
    JOIN customers ON customers.customerNumber = orders.customerNumber
GROUP BY customers.country,
         products.productName
ORDER BY customers.country,
         sumQuantity DESC)
SELECT *
FROM (SELECT CTE.*, DENSE_RANK() OVER(PARTITION BY CTE.cntry ORDER BY CTE.sumQtity DESC) AS rank_
      FROM CTE
      GROUP BY CTE.prodName,
               CTE.cntry,
               CTE.sumQtity) AS alias1
GROUP BY prodName,
         cntry,
		 sumQtity
HAVING rank_ <= 3;


/*---LIST OF CUSTOMERS FROM THE DATASET WHO DON'T MAKE ANY PURCHASE---*/

SELECT customerName
FROM customers
WHERE customerNumber NOT IN (
SELECT customerNumber
FROM orders )
ORDER BY customerName ASC;


/*---QUERY TO SEE THE PURCHASES QUANTITY BY MONTH---*/

SELECT MONTHNAME(STR_TO_DATE(monthNumber, "%m")) AS month_,
       numberOfPayments
FROM
    (SELECT DISTINCT(MONTH(paymentDate)) AS monthNumber,
            COUNT(MONTH(paymentDate)) AS numberOfPayments
	 FROM payments
     GROUP BY monthNumber
     ORDER BY numberOfPayments DESC) AS tab_;


/*---QUERY TO SEE THE AVERAGE PURCHASE AMOUNT BY COUNTRY---*/

SELECT country,
       FLOOR(averageAmount) as averageAmount_
FROM
	(SELECT customers.country AS country, 
	        AVG(payments.amount) OVER(ORDER BY customers.country) AS averageAmount
     FROM customers
          INNER JOIN payments ON payments.customerNumber = customers.customerNumber
     GROUP BY customers.country
     ORDER BY 2 DESC) AS tab_;


/*---QUERY TO GET THE AVERAGE PAYMENT AMOUNT FOR FRANCE COUNTRY---*/

SELECT ROUND(AVG(avg_amount), 2) AS `avg_payment_amount_France($)`
FROM
     (SELECT customers.country, 
             payments.amount AS avg_amount
      FROM customers INNER JOIN payments ON payments.customerNumber = customers.customerNumber
      WHERE customers.country = "France") AS tab_;


