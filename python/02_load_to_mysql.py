"""
02_load_to_mysql.py

Loads the synthetic NovaShop dataset (CSV with embedded newlines in
customer_notes) into the MySQL table `customers_orders_with_notes`.

Why this script exists:
    The MySQL Workbench Table Data Import Wizard misinterprets newlines
    inside quoted fields and silently truncates the import. LOAD DATA LOCAL
    INFILE works but is blocked by client-side restrictions on some Workbench
    versions. Loading via Python with pandas + mysql-connector avoids both
    problems and is reproducible from any machine.
"""

from pathlib import Path

import pandas as pd
import mysql.connector
from mysql.connector import Error


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

CSV_PATH = Path(
    "C:/Users/victor/Desktop/PORYECTOS-portfolio/GitHub_projects/"
    "Project_GDPR/data/data_notas/customers_orders_with_notes.csv"
)

DB_CONFIG = {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "root",  
    "database": "gdpr",
}

TABLE_NAME = "customers_orders_with_notes"
BATCH_SIZE = 1000   # rows inserted per transaction


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    # 1. Load the CSV into a pandas DataFrame
    print(f"Reading CSV: {CSV_PATH.name}")
    df = pd.read_csv(CSV_PATH)
    print(f"  Loaded {len(df):,} rows, {len(df.columns)} columns")

    # 2. Replace pandas NaN with None so MySQL stores them as NULL
    df = df.astype(object).where(pd.notna(df), None)

    # 3. Connect to MySQL
    print("Connecting to MySQL...")
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()
    except Error as e:
        print(f"Connection failed: {e}")
        return

    try:
        # 4. Empty the table before loading (safe re-runs)
        cursor.execute(f"TRUNCATE TABLE {TABLE_NAME}")
        conn.commit()
        print(f"  Table {TABLE_NAME} truncated")

        # 5. Build the INSERT statement dynamically from CSV columns
        cols = ", ".join(f"`{c}`" for c in df.columns)
        placeholders = ", ".join(["%s"] * len(df.columns))
        insert_sql = f"INSERT INTO {TABLE_NAME} ({cols}) VALUES ({placeholders})"

        # 6. Insert in batches (much faster than one row at a time)
        rows = [tuple(r) for r in df.itertuples(index=False, name=None)]
        total = len(rows)
        inserted = 0

        for start in range(0, total, BATCH_SIZE):
            batch = rows[start:start + BATCH_SIZE]
            cursor.executemany(insert_sql, batch)
            conn.commit()
            inserted += len(batch)
            print(f"  Inserted {inserted:,} / {total:,}")

        # 7. Verify
        cursor.execute(f"SELECT COUNT(*) FROM {TABLE_NAME}")
        count = cursor.fetchone()[0]
        print(f"\nFinal row count in {TABLE_NAME}: {count:,}")

    except Error as e:
        print(f"MySQL error: {e}")
        conn.rollback()

    finally:
        cursor.close()
        conn.close()
        print("Connection closed")


if __name__ == "__main__":
    main()
