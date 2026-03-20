import psycopg2

from sqlalchemy import create_engine

DB_HOST = "localhost"
DB_PORT = 5432
DB_USER = "postgres"
DB_PASSWORD = "209202"
DB_NAME = "postgres"

def get_connection(database = "postgres"):
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=database,
        user=DB_USER,
        password=DB_PASSWORD
    )

def get_engine(database = "postgres"):
    return create_engine(
        f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{database}"
    )

if __name__ == "__main__":
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT version();")
            print(cur.fetchone())