import psycopg2
import os
import pandas as pd


from db_connection import get_connection

DATA_FOLDER = "/Users/giakhanh/Desktop/AIDE/Projects/home_credit_risk/data/raw"

def generate_create_table(table_name, columns):

    cols = []

    for col in columns:
        col = col.lower()
        cols.append(f"{col} TEXT")

    cols_sql = ",\n".join(cols)

    return f"""
    CREATE TABLE IF NOT EXISTS raw.{table_name} (
        {cols_sql}
    );
    """


def create_tables():

    with get_connection(database = "home_credit") as conn:
        with conn.cursor() as cur:

            for file in os.listdir(DATA_FOLDER):

                if not file.endswith(".csv"):
                    continue

                table_name = file.replace(".csv", "")
                path = os.path.join(DATA_FOLDER, file)

                print(f"Creating table raw.{table_name}")

                df = pd.read_csv(path, nrows=0)

                create_sql = generate_create_table(
                    table_name,
                    df.columns
                )

                cur.execute(create_sql)

        conn.commit()


if __name__ == "__main__":
    create_tables()