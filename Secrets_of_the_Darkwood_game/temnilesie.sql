/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Ковтун М.И.
 * Дата: 15.11.2026
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
-- Напишите ваш запрос здесь

SELECT COUNT(*) AS number_of_users, 
SUM(payer) AS number_of_payers, 
ROUND(AVG(payer) * 100, 1) AS  persentage_payers
FROM fantasy.users;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь
SELECT race,
SUM(payer) AS number_of_payers,
COUNT(*) AS number_of_users,
ROUND(AVG(payer)* 100, 1) AS persentage_payers
FROM fantasy.users
JOIN fantasy.race USING(race_id)
GROUP BY race
ORDER BY persentage_payers DESC;

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь
WITH data_for_stat AS (
SELECT 'with zero amount' AS type_of_stat, amount
FROM fantasy.events
UNION ALL
SELECT 'without zero amount', amount
FROM fantasy.events
WHERE amount > 0
)
SELECT type_of_stat,
COUNT(amount) AS number_of_purchases,
SUM(amount) AS total_cost,
MIN(amount) AS min_cost,
MAX(amount) AS max_cost,
ROUND(AVG(amount)::NUMERIC, 3) AS avg_cost,
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount) AS median_cost,
ROUND(STDDEV(amount)::NUMERIC, 3) AS costs_stddev
FROM data_for_stat
GROUP BY type_of_stat
ORDER BY type_of_stat; 
-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь
WITH 
prepare_calcul AS (SELECT
	PERCENTILE_DISC(0.99)	WITHIN GROUP (ORDER BY amount) AS pecentile,
	ROUND(AVG(amount)::NUMERIC, 3) + 3 * ROUND(STDDEV(amount)::NUMERIC, 3) AS three_sigm,
	COUNT(*) AS total_purchases
	FROM fantasy.events
)
SELECT 'zero cost anomaly' AS anomaly_type,
COUNT(*) FILTER (WHERE amount = 0) AS anomaly_amount_purchases,
(SELECT total_purchases FROM prepare_calcul),
0 AS anomaly_value,
ROUND(COUNT(*) FILTER (WHERE amount = 0)::numeric / COUNT(*) * 100, 2) AS parcentage_of_zero_amount
FROM fantasy.events
UNION ALL 
SELECT 'big cost anomaly 3 sigm' AS anomaly_type,
COUNT(*) FILTER (WHERE amount > (SELECT three_sigm FROM prepare_calcul)) AS anomaly_amount_purchases,
(SELECT total_purchases FROM prepare_calcul),
(SELECT three_sigm FROM prepare_calcul) AS anomaly_value,
ROUND(COUNT(*) FILTER (WHERE amount > (SELECT three_sigm FROM prepare_calcul))::NUMERIC / COUNT(*) * 100, 2) AS parcentage_of_zero_amount
FROM fantasy.events
UNION ALL 
SELECT 'big cost anomaly 99 percentile' AS anomaly_type,
COUNT(*) FILTER (WHERE amount > (SELECT pecentile FROM prepare_calcul)) AS anomaly_amount_purchases,
(SELECT total_purchases FROM prepare_calcul),
(SELECT pecentile FROM prepare_calcul) AS anomaly_value,
ROUND(COUNT(*) FILTER (WHERE amount > (SELECT pecentile FROM prepare_calcul))::NUMERIC / COUNT(*) * 100, 2) AS parcentage_of_zero_amount
FROM fantasy.events;

--Вывод предметов с нулевой стоимостью покупок
SELECT game_items, COUNT(game_items) AS numb_of_zero_cost
FROM fantasy.events
LEFT JOIN fantasy.items USING(item_code)
WHERE amount = 0
GROUP BY game_items;


-- 2.3: Популярные эпические предметы:
-- Напишите ваш запрос здесь

WITH 
calcul_total_values AS (
	SELECT COUNT(*)::NUMERIC AS all_transaction,
	COUNT(DISTINCT id) AS all_payers
	FROM fantasy.events
	WHERE amount > 0
)
SELECT i.game_items, 
COUNT(*) AS count_of_transaction,
ROUND(COUNT(*) / (SELECT all_transaction FROM calcul_total_values)::NUMERIC * 100, 4) AS parcentage_of_all_transaction,
ROUND(COUNT(DISTINCT id) / (SELECT all_payers FROM calcul_total_values)::NUMERIC * 100, 3) AS parcentage_of_all_payers,
(SELECT COUNT(item_code) FROM fantasy.items) AS total_numb_of_items,
(SELECT COUNT(item_code) FROM fantasy.items) - (SELECT COUNT(DISTINCT item_code) FROM fantasy.events) AS numb_of_non_purchasable_items
FROM fantasy.events AS e
JOIN fantasy.items AS i USING(item_code)
WHERE amount > 0
GROUP BY i.game_items
ORDER BY count_of_transaction DESC;


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
	WHERE payer = 1 AND id IN (SELECT DISTINCT id FROM fantasy.events WHERE amount > 0)
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
	WHERE amount > 0
	GROUP BY race_id, id
),
calc_action AS(
	SELECT COUNT(id) AS numb_of_payers,
	ROUND(AVG(numb_of_purchase_for_payer)::NUMERIC, 3) AS avg_numb_of_purchase_for_payer,
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
avg_numb_of_purchase_for_payer,
avg_cost_purchase_for_payers, 
avg_sum_cast_all_purchase_for_payers
FROM tot_usr
JOIN real_payers USING(race_id)
JOIN calc_action USING(race_id)
JOIN fantasy.race USING(race_id)