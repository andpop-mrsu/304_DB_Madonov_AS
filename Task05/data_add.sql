PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

-- 1. Добавление профессии "Student"
INSERT OR IGNORE INTO occupations (name) VALUES ('Student');

-- 2. Добавление 5 новых пользователей (Дата регистрации подставится автоматически благодаря DEFAULT)
INSERT INTO users (name, email, gender, occupation_id)
SELECT 'Artur Madonov', 'arturmadonov@gmail.com', 'male', 
       (SELECT id FROM occupations WHERE name = 'Student')
UNION ALL SELECT 'Ivan Kryazhev', 'ivan.kryazhev@mail.ru', 'male', 
       (SELECT id FROM occupations WHERE name = 'Student')
UNION ALL SELECT 'Sergei Ksenofontov', 'ksenofontov@mail.ru', 'male', 
       (SELECT id FROM occupations WHERE name = 'Student')
UNION ALL SELECT 'Gleb Medvedev', 'gleb.medvedev@mail.ru', 'female', 
       (SELECT id FROM occupations WHERE name = 'Student')
UNION ALL SELECT 'Mena Vera Emir Samuel', 'samuel@mail.ru', 'female', 
       (SELECT id FROM occupations WHERE name = 'Student');

-- 3. Добавление 3 новых фильмов разных жанров
INSERT INTO movies (title, year) VALUES
('Parasite', 2019),
('Dune', 2021),
('Everything Everywhere All at Once', 2022);

-- Связывание фильмов с жанрами через подзапросы
-- Parasite — Drama
INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m, genres g WHERE m.title = 'Parasite' AND g.name = 'Drama';

-- Dune — Sci-Fi
INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m, genres g WHERE m.title = 'Dune' AND g.name = 'Sci-Fi';

-- Everything Everywhere All at Once — Action
INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m, genres g WHERE m.title = 'Everything Everywhere All at Once' AND g.name = 'Action';

-- 4. Добавление 3 новых отзывов от себя на эти фильмы
-- Используем подзапросы для получения ID пользователя и фильмов, чтобы не зависеть от конкретных чисел
INSERT INTO ratings (user_id, movie_id, rating, timestamp)
SELECT 
    (SELECT id FROM users WHERE email = 'arturmadonov@gmail.com'),
    (SELECT id FROM movies WHERE title = 'Parasite'),
    5.0,
    strftime('%s', 'now')
UNION ALL
SELECT 
    (SELECT id FROM users WHERE email = 'arturmadonov@gmail.com'),
    (SELECT id FROM movies WHERE title = 'Dune'),
    4.5,
    strftime('%s', 'now')
UNION ALL
SELECT 
    (SELECT id FROM users WHERE email = 'arturmadonov@gmail.com'),
    (SELECT id FROM movies WHERE title = 'Everything Everywhere All at Once'),
    5.0,
    strftime('%s', 'now');

COMMIT;