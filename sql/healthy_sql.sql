SHOW DATABASES;
CREATE DATABASE health;
USE health;


/* ---CONVERT CSV FILES INTO SQL TABLES--- */

CREATE TABLE IF NOT EXISTS healthy_lifestyle (
  City VARCHAR(255) NOT NULL,
  Rank_ INTEGER NOT NULL,
  Sunshine_Hour INTEGER NOT NULL,
  Cost_of_a_bottle_of_water VARCHAR(255) NOT NULL,
  Obesity_levels_Country VARCHAR(255) NOT NULL,
  Life_Expectancy_Country DECIMAL(10, 2) NOT NULL,
  Pollution_Index_Score_City DECIMAL(10, 2) NOT NULL,
  Annual_Avg_Hours_Worked INTEGER NOT NULL,
  Happiness DECIMAL(10, 2) NOT NULL,
  Outdoor_Activities_City INTEGER NOT NULL,
  Number_Of_Take_Out_Places_City_ INTEGER NOT NULL,
  Cost_Of_A_Monthly_Gym_Membership_City VARCHAR(255) NOT NULL
  );
  
SHOW VARIABLES LIKE 'secure_file_priv';
  
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/healthy_lifestyle_city_2021.csv' IGNORE
INTO TABLE healthy_lifestyle
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

ALTER TABLE healthy_lifestyle ADD id INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT;

CREATE TABLE IF NOT EXISTS arrivals (
  Rank_ INTEGER NOT NULL,
  City VARCHAR(255) NOT NULL,
  Country VARCHAR(255) NOT NULL,
  Tourist_Arrivals_2018 DECIMAL(10, 2) NOT NULL
  );

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/arrivals_.csv'
INTO TABLE arrivals
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

ALTER TABLE arrivals ADD id INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT;


/* ---CLEANING THE DATASET ( REPLACE VALUES, CAST TO CONVERT TO NUMERIC VALUES, CREATE VIEW )--- */

CREATE VIEW v1
AS
SELECT id, City, Rank_, Sunshine_Hour, CAST(REPLACE(Cost_of_a_bottle_of_water, '£', '') AS FLOAT)
                                       AS 'Cost_Of_A_Bottle_Of_Water(£)',
                                       CAST(REPLACE(Obesity_levels_Country, '%', '') AS FLOAT)
                                       AS 'Obesity_Levels_Country(%)',
	   Life_Expectancy_Country, Pollution_Index_Score_City, Happiness,
       Outdoor_Activities_City, Number_Of_Take_Out_Places_City_,
                                       CAST(REPLACE(Cost_Of_A_Monthly_Gym_Membership_City, '£', '') AS FLOAT)
                                       AS 'Cost_Of_A_Monthly_Gym_Membership_City(£)'
FROM healthy_lifestyle;


/* ---REPLACE NA OR NOT COHERENT VALUES--- */

SET SQL_SAFE_UPDATES = 0;

UPDATE healthy_lifestyle
SET Pollution_Index_Score_City = 43
WHERE Pollution_Index_Score_City = 0.00;

UPDATE arrivals
SET City = "New York"
WHERE City = "New York City";


/* --- JOIN TWO TABLES --- */

CREATE VIEW full_data
AS
SELECT v1.*, arrivals.Country, 
       CAST(arrivals.Tourist_Arrivals_2018 AS UNSIGNED) AS "Tourist_Arrivals_2018"
FROM v1
INNER JOIN arrivals
ON arrivals.City = v1.City;


/* ---CITIES WITH MORE THAN 2500 HOURS OF SUN BY YEAR--- */

SELECT Country, City, Sunshine_Hour
FROM full_data
WHERE Sunshine_Hour >= 2500
ORDER BY Sunshine_Hour DESC;


/* ---AVERAGE OBESITY LEVEL OF THE TOP 10 MOST OBESE--- */

SELECT ROUND(AVG(`Obesity_Levels_Country(%)`), 2) AS AVG_TOP10_Obesity_Percent
FROM (SELECT Country, City, `Obesity_Levels_Country(%)`, Life_Expectancy_Country
      FROM full_data
      ORDER BY `Obesity_Levels_Country(%)` DESC
      LIMIT 10) AS avg_top_10;


/* ---RANK WINDOW FUNCTION TO GET RANK BY SUNNIEST PLACES--- */

SELECT Country, City, Sunshine_Hour, Tourist_Arrivals_2018, 
       RANK() OVER(ORDER BY Sunshine_Hour DESC) AS Rank_By_Sunshine_Hours
FROM full_data;


/* ---AVERAGE LIFE EXPECTANCY OF THE LEAST AND MOST POLLUTED CITIES--- */

SELECT CONCAT(ROUND(AVG(Pollution_Ordered_Asc.Life_Expectancy_Country), 1), " ", "years") AS Life_Expec_Of_Least_Polluted_Cities,
       CONCAT(ROUND(AVG(Pollution_Ordered_Desc.Life_Expectancy_Country), 1), " ", "years") AS Life_Expec_Of_Most_Polluted_Cities
FROM (SELECT City, Pollution_Index_Score_City, Life_Expectancy_Country 
      FROM full_data
	  ORDER BY Pollution_Index_Score_City ASC
      LIMIT 5) AS Pollution_Ordered_Asc
CROSS JOIN (SELECT City, Pollution_Index_Score_City, Life_Expectancy_Country 
            FROM full_data
	        ORDER BY Pollution_Index_Score_City DESC
			LIMIT 5) AS Pollution_Ordered_Desc;
      
      
/* ---HIGHESTS POLUTION INDEX SCORE CITIES--- */

SELECT City, MAX(Pollution_Index_Score_City) AS "Most_Polluted_Cities"
FROM full_data
GROUP BY City
HAVING Most_Polluted_Cities >= 70
ORDER BY 2 DESC;


/* ---RELATION BETWEEN HAPPINESS AND AVERAGE PRICE OF A BOTTLE OF WATER--- */
/* ---WE CAN SEE THAT HAPPIESTS CITIES HAVE A HIGH PRICE BOTTLE
	  AND UNHAPPIEST CITIES HAVE A LOW PRICE BOTTLE--- */
      
SELECT ROUND(AVG(Top5_Happiest_Cities.`Cost_Of_A_Bottle_Of_Water(£)`), 2) AS `Avg_Price_Happ_Bottle(£)`,
       ROUND(AVG(Top5_Unhappiest_Cities.`Cost_Of_A_Bottle_Of_Water(£)`), 2) AS `Avg_Price_Unhapp_Bottle(£)`
FROM (SELECT * 
      FROM full_data
	  ORDER BY Happiness DESC
      LIMIT 5) AS Top5_Happiest_Cities
CROSS JOIN (SELECT *
            FROM full_data
            ORDER BY Happiness ASC
            LIMIT 5) AS Top5_Unhappiest_Cities;
            
            
/* ---GET THE TOURIST ARRIVALS PERCENTAGE FOR EACH CITY--- */

SELECT City, Tourist_Arrivals_2018, 
       ROUND(Tourist_Arrivals_2018 * 100 / (SELECT SUM(Tourist_Arrivals_2018) FROM full_data), 2)
       AS `Tourist_Arrivals(%)`
FROM full_data
ORDER BY 3 DESC;


/* --- USE CASE WHEN FUNCTION TO SORT DATA --- */

SELECT City, Number_Of_Take_Out_Places_City_,
       CASE WHEN Number_Of_Take_Out_Places_City_ >= 2000 THEN "High"
            WHEN Number_Of_Take_Out_Places_City_ < 2000 THEN "Low"
			END AS "High/Low_Number_Of_Take_Out_Places" 
FROM full_data;