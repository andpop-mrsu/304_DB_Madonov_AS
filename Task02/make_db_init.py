import csv
import os
import sys


def escape_sql(value):
    """Экранирует строки для безопасной вставки в SQL"""
    if value is None:
        return 'NULL'

    return "'" + str(value).replace("'", "''") + "'"


def parse_movies(filename):
    """Парсит movies.csv. Возвращает список кортежей (id, title, year, genres)."""
    data = []
    with open(filename, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        next(reader)  # Пропускаем заголовок
        for row in reader:
            if len(row) < 3: continue

            movie_id = int(row[0])
            title_full = row[1]
            genres = row[2]

            # Извлекаем год из названия
            year = None
            if '(' in title_full and ')' in title_full:
                # Ищем последнюю пару скобок
                start = title_full.rfind('(')
                end = title_full.rfind(')')
                if start != -1 and end != -1 and end > start:
                    year_str = title_full[start + 1:end].strip()
                    if year_str.isdigit() and len(year_str) == 4:
                        year = int(year_str)

            data.append((movie_id, title_full, year, genres))
    return data


def parse_ratings(filename):
    """Парсит ratings.csv."""
    data = []
    with open(filename, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        next(reader)
        for row in reader:
            if len(row) < 4: continue
            user_id = int(row[0])
            movie_id = int(row[1])
            rating = float(row[2])
            timestamp = int(row[3])
            data.append((user_id, movie_id, rating, timestamp))
    return data


def parse_tags(filename):
    """Парсит tags.csv."""
    data = []
    with open(filename, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        next(reader)
        for row in reader:
            if len(row) < 4: continue
            user_id = int(row[0])
            movie_id = int(row[1])
            tag = row[2]
            timestamp = int(row[3])
            data.append((user_id, movie_id, tag, timestamp))
    return data


def parse_users(filename):
    """Парсит users.txt"""
    data = []
    with open(filename, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            parts = line.split('|')
            if len(parts) < 6: continue

            user_id = int(parts[0])
            name = parts[1]
            email = parts[2]
            gender = parts[3]
            register_date = parts[4]
            occupation = parts[5]

            data.append((user_id, name, email, gender, register_date, occupation))
    return data


def generate_sql(output_file):
    print("Чтение данных...")

    base_dir = os.path.dirname(os.path.abspath(__file__))

    files = {
        'movies': os.path.join(base_dir, 'movies.csv'),
        'ratings': os.path.join(base_dir, 'ratings.csv'),
        'tags': os.path.join(base_dir, 'tags.csv'),
        'users': os.path.join(base_dir, 'users.txt')
    }

    # Проверка наличия файлов
    for key, path in files.items():
        if not os.path.exists(path):
            print(f"Ошибка: Файл {path} не найден. Убедитесь, что данные лежат в папке Task02.")
            sys.exit(1)

    movies = parse_movies(files['movies'])
    ratings = parse_ratings(files['ratings'])
    tags = parse_tags(files['tags'])
    users = parse_users(files['users'])

    print(f"Загружено: Movies={len(movies)}, Ratings={len(ratings)}, Tags={len(tags)}, Users={len(users)}")
    print("Генерация SQL скрипта...")

    with open(output_file, 'w', encoding='utf-8') as f:
        # Начало транзакции для скорости
        f.write("BEGIN TRANSACTION;\n\n")

        # Удаление старых таблиц
        f.write("DROP TABLE IF EXISTS movies;\n")
        f.write("DROP TABLE IF EXISTS ratings;\n")
        f.write("DROP TABLE IF EXISTS tags;\n")
        f.write("DROP TABLE IF EXISTS users;\n\n")

        # Создание таблиц
        f.write("""CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT,
    year INTEGER,
    genres TEXT
);

CREATE TABLE ratings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    movie_id INTEGER,
    rating REAL,
    timestamp INTEGER
);

CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    movie_id INTEGER,
    tag TEXT,
    timestamp INTEGER
);

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT,
    email TEXT,
    gender TEXT,
    register_date TEXT,
    occupation TEXT
);

""")

        # Вставка данных
        f.write("-- Inserting Movies\n")
        for m in movies:
            mid, title, year, genres = m
            year_val = year if year is not None else 'NULL'
            f.write(f"INSERT INTO movies VALUES ({mid}, {escape_sql(title)}, {year_val}, {escape_sql(genres)});\n")

        f.write("\n-- Inserting Ratings\n")
        for r in ratings:
            uid, mid, rat, ts = r
            f.write(f"INSERT INTO ratings (user_id, movie_id, rating, timestamp) VALUES ({uid}, {mid}, {rat}, {ts});\n")

        f.write("\n-- Inserting Tags\n")
        for t in tags:
            uid, mid, tag, ts = t
            f.write(
                f"INSERT INTO tags (user_id, movie_id, tag, timestamp) VALUES ({uid}, {mid}, {escape_sql(tag)}, {ts});\n")

        f.write("\n-- Inserting Users\n")
        for u in users:
            uid, name, email, gender, reg, occ = u
            f.write(
                f"INSERT INTO users VALUES ({uid}, {escape_sql(name)}, {escape_sql(email)}, {escape_sql(gender)}, {escape_sql(reg)}, {escape_sql(occ)});\n")

        f.write("\nCOMMIT;\n")

    print(f"SQL скрипт успешно создан: {output_file}")


if __name__ == "__main__":
    output_filename = "db_init.sql"
    generate_sql(output_filename)