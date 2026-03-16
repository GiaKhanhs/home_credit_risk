import os
from db_connection import get_connection


DATA_FOLDER = "/Users/giakhanh/Desktop/AIDE/Projects/home_credit_risk/data/raw"


def load_data():

    with get_connection(database = "home_credit") as conn:
        with conn.cursor() as cur:

            for file in os.listdir(DATA_FOLDER):

                if not file.endswith(".csv"):
                    continue

                table_name = file.replace(".csv", "")
                path = os.path.join(DATA_FOLDER, file)

                print(f"Ingesting {table_name}")

                with open(path, "r") as f:

                    cur.copy_expert(
                        f"""
                        COPY raw.{table_name}
                        FROM STDIN
                        WITH CSV HEADER
                        """,
                        f,
                    )

        conn.commit()


if __name__ == "__main__":
    load_data()