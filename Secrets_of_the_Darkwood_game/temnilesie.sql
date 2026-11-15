/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: 
 * Дата: 
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
-- Напишите ваш запрос здесь

SELECT COUNT(*) AS number_of_users, 
SUM(payer) AS number_of_payers, 
ROUND(AVG(payer), 3) AS  percentage_of_payers
FROM fantasy.users

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь
SELECT race,
SUM(payer) AS number_of_payers,
COUNT(*) AS number_of_users,
ROUND(AVG(payer), 3) AS percentage_of_payers
FROM fantasy.users
JOIN fantasy.race USING(race_id)
GROUP BY race

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь
SELECT COUNT(amount) AS number_of_purchases, 
SUM(amount) AS total_cost,
MIN(amount) AS min_cost,
MAX(amount)AS max_cost,
ROUND(AVG(amount)::NUMERIC, 3) AS avg_cost,
PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY amount) AS median_cost,
ROUND(STDDEV(amount)::NUMERIC, 3) AS costs_stddev
FROM fantasy.events

-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь
SELECT  COUNT(amount) AS total_count_with_zero_cost
FROM fantasy.events
WHERE amount = 0

SELECT (SELECT  COUNT(amount)
FROM fantasy.events
WHERE amount = 0) / COUNT(amount)::NUMERIC AS percentage_of_total_count_with_zero_cost
FROM fantasy.events


-- 2.3: Популярные эпические предметы:
-- Напишите ваш запрос здесь

SELECT i.game_items, 
COUNT(*) AS count_of_transaction,
ROUND(COUNT(*) / (SELECT COUNT(*) FROM fantasy.events)::NUMERIC,6) AS percentage_of_all_transaction,
ROUND(COUNT(DISTINCT id) / (SELECT COUNT(DISTINCT id) FROM fantasy.events)::NUMERIC, 5) AS percentage_of_all_payers
FROM fantasy.events AS e
JOIN fantasy.items AS i USING(item_code)
GROUP BY i.game_items
ORDER BY count_of_transaction DESC

-- Часть 2. Решение ad hoc-задачbи
-- Задача: Зависимость активности игроков от расы персонажа:
-- Напишите ваш запрос здесь

WITH 
tot_usr AS(
	SELECT COUNT(id) AS numb_of_users,
	race_id
	FROM fantasy.users
	GROUP BY race_id
),
real_payers AS(
	SELECT COUNT(id) AS numb_of_real_payers,
	race_id
	FROM fantasy.users
	WHERE payer = 1
	GROUP BY race_id
),
total_payers AS(
	SELECT COUNT(DISTINCT id) AS numb_of_payers,
	race_id
	FROM fantasy.users
	JOIN fantasy.events USING(id)
	GROUP BY race_id
),
prepar_for_action AS (
	SELECT
	COUNT(id) AS numb_of_purchase_for_payer,
	AVG(amount) AS avg_cost_purchase_for_payer,
	SUM(amount) AS sum_cast_all_purchase_for_payers,
	id,
	race_id
	FROM fantasy.events
	JOIN fantasy.users USING(id)
	GROUP BY race_id, id
),
calc_action AS(
	SELECT ROUND(AVG(numb_of_purchase_for_payer)::NUMERIC, 3) AS avg_numb_of_purchase_for_payer,
	ROUND(AVG(avg_cost_purchase_for_payer)::NUMERIC, 3) AS avg_cost_purchase_for_payers,
	ROUND(AVG(sum_cast_all_purchase_for_payers)::NUMERIC, 3) AS avg_sum_cast_all_purchase_for_payers,
	race_id
	FROM prepar_for_action
	GROUP BY race_id
)
SELECT race,
numb_of_users,
numb_of_payers,
ROUND(numb_of_payers::NUMERIC / numb_of_users, 3) AS percentage_of_payers,
ROUND(numb_of_real_payers::NUMERIC / numb_of_payers, 3) AS percentage_of_real_payers,
avg_numb_of_purchase_for_payer
avg_cost_purchase_for_payers, 
avg_sum_cast_all_purchase_for_payers
FROM tot_usr
JOIN real_payers USING(race_id)
JOIN total_payers USING(race_id)
JOIN calc_action USING(race_id)
JOIN fantasy.race USING(race_id)