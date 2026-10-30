#!/bin/bash
chcp 65001 

sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Устранить дубликаты, проверить отсутствие пар с самим собой. Для каждой пары должны быть указаны имена пользователей и название фильма, который они ценили. В списке оставить первые 100 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -header -echo "
SELECT u1.name AS user1, u2.name AS user2, m.title AS movie_title
FROM ratings r1
JOIN ratings r2 ON r1.movie_id = r2.movie_id AND r1.user_id < r2.user_id
JOIN users u1 ON r1.user_id = u1.id
JOIN users u2 ON r2.user_id = u2.id
JOIN movies m ON r1.movie_id = m.id
LIMIT 100;
"
echo " "

echo "2. Найти 10 самых старых оценок от разных пользователей, вывести названия фильмов, имена пользователей, оценку, дату отзыва в формате ГГГГ-ММ-ДД."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -header -echo "
WITH oldest AS (
  SELECT user_id, movie_id, rating, timestamp,
         ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY timestamp) AS rn
  FROM ratings
)
SELECT m.title, u.name, o.rating, strftime('%Y-%m-%d', o.timestamp, 'unixepoch') AS review_date
FROM oldest o
JOIN users u ON o.user_id = u.id
JOIN movies m ON o.movie_id = m.id
WHERE o.rn = 1
ORDER BY o.timestamp ASC
LIMIT 10;
"
echo " "

echo "3. Вывести в одном списке все фильмы с максимальным средним рейтингом и все фильмы с минимальным средним рейтингом. Общий список отсортировать по году выпуска и названию фильма. В зависимости от рейтинга в колонке "Рекомендуем" для фильмов должно быть написано "Да" или "Нет"."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -header -echo "
WITH avg_ratings AS (
  SELECT movie_id, AVG(rating) AS avg_rating
  FROM ratings
  GROUP BY movie_id
),
max_min AS (
  SELECT MAX(avg_rating) AS max_rating, MIN(avg_rating) AS min_rating
  FROM avg_ratings
)
SELECT m.title, m.year, ROUND(ar.avg_rating, 2) AS avg_rating,
       CASE WHEN ar.avg_rating = (SELECT max_rating FROM max_min) THEN 'Да' ELSE 'Нет' END AS 'Рекомендуем'
FROM avg_ratings ar
JOIN movies m ON m.id = ar.movie_id
JOIN max_min mm ON ar.avg_rating = mm.max_rating OR ar.avg_rating = mm.min_rating
WHERE m.year IS NOT NULL
ORDER BY m.year, m.title;
"
echo " "

echo "4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-мужчины в период с 2011 по 2014 год."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -header -echo "
SELECT COUNT(*) AS rating_count, ROUND(AVG(r.rating), 2) AS avg_rating
FROM ratings r
JOIN users u ON r.user_id = u.id
WHERE u.gender = 'male'
  AND strftime('%Y', r.timestamp, 'unixepoch') BETWEEN '2011' AND '2014';
"
echo " "

echo "5. Составить список фильмов с указанием средней оценки и количества пользователей, которые их оценили. Полученный список отсортировать по году выпуска и названиям фильмов. В списке оставить первые 20 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -header -echo "
SELECT m.title, m.year, ROUND(AVG(r.rating), 2) AS avg_rating, COUNT(DISTINCT r.user_id) AS user_count
FROM movies m
JOIN ratings r ON m.id = r.movie_id
WHERE m.year IS NOT NULL
GROUP BY m.id
ORDER BY m.year, m.title
LIMIT 20;
"
echo " "

echo "6. Определить самый распространенный жанр фильма и количество фильмов в этом жанре. Отдельную таблицу для жанров не использовать, жанры нужно извлекать из таблицы movies."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -header -echo "
WITH RECURSIVE split(movie_id, genre, rest) AS (
  SELECT id, '', genres || '|' FROM movies
  UNION ALL
  SELECT movie_id, substr(rest, 0, instr(rest, '|')), substr(rest, instr(rest, '|') + 1)
  FROM split WHERE rest != ''
)
SELECT genre, COUNT(DISTINCT movie_id) AS movie_count
FROM split
WHERE genre != ''
GROUP BY genre
ORDER BY movie_count DESC
LIMIT 1;
"
echo " "

echo "7. Вывести список из 10 последних зарегистрированных пользователей в формате "Фамилия Имя|Дата регистрации" (сначала фамилия, потом имя)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -header -echo "
SELECT substr(name, instr(name, ' ') + 1) || ' ' || substr(name, 1, instr(name, ' ') - 1) || '|' || register_date AS user_info
FROM users
ORDER BY register_date DESC
LIMIT 10;
"
echo " "

echo "8. С помощью рекурсивного CTE определить, на какие дни недели приходился ваш день рождения в каждом году."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -header -echo "
WITH RECURSIVE years(y) AS (
  SELECT 2000
  UNION ALL
  SELECT y + 1 FROM years WHERE y < 2026
)
SELECT y AS year,
       CASE CAST(strftime('%w', printf('%04d-05-08', y)) AS INTEGER)
         WHEN 0 THEN 'Sunday'
         WHEN 1 THEN 'Monday'
         WHEN 2 THEN 'Tuesday'
         WHEN 3 THEN 'Wednesday'
         WHEN 4 THEN 'Thursday'
         WHEN 5 THEN 'Friday'
         WHEN 6 THEN 'Saturday'
       END AS day_of_week
FROM years
ORDER BY y;
"
echo " "