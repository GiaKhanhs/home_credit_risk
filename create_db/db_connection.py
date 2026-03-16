import psycopg2

def get_connection(database = "postgres"):
    return psycopg2.connect(
        host = "localhost",
        port = 5432,
        database = database,
        user = "postgres",
        password = "209202"
    )

if __name__ == "__main__":
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT version();")
            print(cur.fetchone())