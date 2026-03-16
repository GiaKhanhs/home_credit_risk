import psycopg2
from db_connection import get_connection

def create_database():
    conn = get_connection("postgres")
    conn.autocommit = True

    with conn.cursor() as cur:
        try:
            cur.execute("CREATE DATABASE home_credit;")
            print("Database is created.")
        except psycopg2.errors.DuplicateDatabase:
            print("Database already exists.")

    conn.close()

if __name__ == "__main__":
    create_database()