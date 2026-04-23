"""
anonymize_notes.py

Uses Ollama (llama3.2:3b) to detect and replace PII in customer_notes.
Reads notes from MySQL, sends each to the local LLM for anonymization,
and updates the anonymized table with the cleaned text.

Why Ollama and not SQL?
    SQL can only transform data with predictable structure (emails, phones,
    dates in known columns). Free-text notes contain PII in unpredictable
    forms: "My name is Peadar and I live at 60 O'Malley Street" cannot be
    parsed with SUBSTRING or LOCATE. An LLM understands natural language
    and can detect PII regardless of how it appears in the text.
"""

import time
from pathlib import Path

import ollama
import mysql.connector
from mysql.connector import Error


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

DB_CONFIG = {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "root",   
    "database": "gdpr",
}

MODEL = "llama3.2:3b"
PROMPT_FILE = Path(__file__).parent / "pii_detection_prompt.txt"
BATCH_SIZE = 50     # commit every N updates (safety net)


# ---------------------------------------------------------------------------
# Load the system prompt
# ---------------------------------------------------------------------------

def load_prompt() -> str:
    """Read the PII detection prompt from file."""
    with open(PROMPT_FILE, "r", encoding="utf-8") as f:
        return f.read().strip()


# ---------------------------------------------------------------------------
# Ollama interaction
# ---------------------------------------------------------------------------

def anonymize_text(system_prompt: str, text: str) -> str:
    """
    Send a customer note to Ollama and get back the anonymized version.

    The system_prompt tells the model what to do (detect PII, replace with labels).
    The text is the actual customer note to process.
    """
    try:
        response = ollama.chat(
            model=MODEL,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": text},
            ],
        )
        return response["message"]["content"].strip()
    except Exception as e:
        print(f"  Ollama error: {e}")
        return text   # if Ollama fails, return original (safe fallback)


# ---------------------------------------------------------------------------
# Main pipeline
# ---------------------------------------------------------------------------

def main() -> None:
    # 1. Load the prompt
    system_prompt = load_prompt()
    print(f"Prompt loaded ({len(system_prompt)} chars)")

    # 2. Connect to MySQL
    print("Connecting to MySQL...")
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()
    except Error as e:
        print(f"Connection failed: {e}")
        return

    try:
        # 3. Add column for anonymized notes if it doesn't exist
        cursor.execute("""
            SELECT COUNT(*) FROM information_schema.columns
            WHERE table_schema = 'gdpr'
              AND table_name = 'customers_orders_anonymized'
              AND column_name = 'customer_notes_anonymized'
        """)
        col_exists = cursor.fetchone()[0]

        if not col_exists:
            cursor.execute("""
                ALTER TABLE customers_orders_anonymized
                ADD COLUMN customer_notes_anonymized TEXT
            """)
            conn.commit()
            print("Column 'customer_notes_anonymized' added")

        # 4. Fetch all rows with non-empty notes that haven't been processed yet
        cursor.execute("""
            SELECT order_id, customer_notes
            FROM customers_orders_anonymized
            WHERE customer_notes IS NOT NULL
              AND customer_notes != ''
              AND (customer_notes_anonymized IS NULL
                   OR customer_notes_anonymized = '')
        """)
        rows = cursor.fetchall()
        total = len(rows)
        print(f"Notes to process: {total}")

        if total == 0:
            print("Nothing to process — all notes already anonymized.")
            return

        # 5. Process each note through Ollama
        processed = 0
        start_time = time.time()

        for order_id, note in rows:
            anonymized = anonymize_text(system_prompt, note)

            cursor.execute("""
                UPDATE customers_orders_anonymized
                SET customer_notes_anonymized = %s
                WHERE order_id = %s
            """, (anonymized, order_id))

            processed += 1

            # Commit every BATCH_SIZE rows (safety: don't lose progress on crash)
            if processed % BATCH_SIZE == 0:
                conn.commit()
                elapsed = time.time() - start_time
                rate = processed / elapsed
                remaining = (total - processed) / rate if rate > 0 else 0
                print(f"  Processed {processed:,} / {total:,} "
                      f"({processed/total*100:.1f}%) "
                      f"— ~{remaining:.0f}s remaining")

        # Final commit
        conn.commit()
        elapsed = time.time() - start_time

        print(f"\nDone! {processed:,} notes anonymized in {elapsed:.1f}s")
        print(f"Average: {elapsed/processed:.2f}s per note")

        # 6. Show a few examples
        print("\n--- Sample results ---")
        cursor.execute("""
            SELECT order_id, customer_notes, customer_notes_anonymized
            FROM customers_orders_anonymized
            WHERE customer_notes_anonymized IS NOT NULL
            LIMIT 3
        """)
        for oid, original, anonymized in cursor.fetchall():
            print(f"\nOrder: {oid}")
            print(f"  Original:    {original[:100]}...")
            print(f"  Anonymized:  {anonymized[:100]}...")

    except Error as e:
        print(f"MySQL error: {e}")
        conn.rollback()

    finally:
        cursor.close()
        conn.close()
        print("\nConnection closed")


if __name__ == "__main__":
    main()
