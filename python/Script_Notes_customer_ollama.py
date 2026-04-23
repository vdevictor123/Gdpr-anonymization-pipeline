# -*- coding: utf-8 -*-
"""
Created on Mon Apr 13 18:55:50 2026

@author: victor
"""
#pip install tqdm
"""
02_generate_notes.py

Enriches the synthetic dataset by generating realistic customer service notes
using Ollama (llama3.2:3b). Notes are generated only for ~16% of orders 
(simulating the real proportion of orders that involve customer service).

Notes deliberately contain embedded PII (names, addresses, phone numbers, 
family references) — this is the raw material that Ollama will later 
anonymize via PII detection in the SQL pipeline.

Input:  data/raw/customers_orders.csv
Output: data/raw/customers_orders_with_notes.csv

Features:
- Incremental save (resilient to interruptions)
- Progress bar
- Skips rows that already have notes (allows resuming)
"""

import random
import pandas as pd
import ollama
from pathlib import Path
from tqdm import tqdm

# ---------- CONFIGURATION ----------
INPUT_PATH = Path(r"C:\Users\victor\Desktop\PORYECTOS-portfolio\GitHub_projects\Project_GDPR\data\raw\customers_orders.csv")
OUTPUT_PATH = Path("data/raw/customers_orders_with_notes.csv")
MODEL = "llama3.2:3b"
NOTE_PROBABILITY = 0.06   # ~16% of orders get a note
SAVE_EVERY = 50           # save progress every N notes
RANDOM_SEED = 42

random.seed(RANDOM_SEED)


# ---------- PROMPT TEMPLATE ----------
PROMPT_TEMPLATE = """You are a customer service agent at NovaShop, an international e-commerce company. 
Write a SHORT internal note (2-4 sentences) about an interaction with this customer.

Customer details:
- Name: {full_name}
- Email: {email}
- Phone: {phone}
- Address: {street_address}, {city}, {country}
- Order: {order_id} ({product_category}, €{order_value_eur})

The note must:
- Be written in English, professional tone
- Include the customer's name and at least 1-2 PII details naturally embedded in the text 
  (email, phone, address, or family member names if relevant)
- Describe a realistic situation: delivery issue, return request, complaint, gift inquiry, 
  size question, payment problem, etc.
- Mention the resolution or next step
- Sound like a real CS agent wrote it quickly

Output ONLY the note text. No headers, no explanations, no quotes."""


# ---------- CORE FUNCTIONS ----------
def generate_note(row: pd.Series) -> str:
    """Call Ollama to generate a customer service note for one order."""
    prompt = PROMPT_TEMPLATE.format(
        full_name=row['full_name'],
        email=row['email'],
        phone=row['phone'],
        street_address=row['street_address'],
        city=row['city'],
        country=row['country'],
        order_id=row['order_id'],
        product_category=row['product_category'],
        order_value_eur=row['order_value_eur'],
    )
    
    try:
        response = ollama.chat(
            model=MODEL,
            messages=[{'role': 'user', 'content': prompt}],
            options={'temperature': 0.8}  # creative but not chaotic
        )
        return response['message']['content'].strip()
    except Exception as e:
        print(f"\n⚠️ Error generating note for {row['order_id']}: {e}")
        return ""


def main():
    # Load: prefer the in-progress output if it exists (allows resuming)
    if OUTPUT_PATH.exists():
        print(f"📂 Resuming from existing file: {OUTPUT_PATH}")
        df = pd.read_csv(OUTPUT_PATH)
    else:
        print(f"📂 Loading raw dataset: {INPUT_PATH}")
        df = pd.read_csv(INPUT_PATH)
    
    # Ensure customer_notes column exists and is string-typed
    if 'customer_notes' not in df.columns:
        df['customer_notes'] = ''
    df['customer_notes'] = df['customer_notes'].fillna('').astype(str)
    
    # Decide which rows need notes
    # Mark rows for note-generation (only if they don't already have one)
    needs_note = (df['customer_notes'] == '') & (
        pd.Series([random.random() < NOTE_PROBABILITY for _ in range(len(df))])
    )
    
    rows_to_process = df[needs_note].index.tolist()
    print(f"📝 Will generate {len(rows_to_process)} notes "
          f"(~{NOTE_PROBABILITY*100:.0f}% of {len(df)} orders)")
    
    if not rows_to_process:
        print("✅ Nothing to do — all targeted notes already exist.")
        return
    
    # Generate with progress bar
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    
    for i, idx in enumerate(tqdm(rows_to_process, desc="Generating notes")):
        df.at[idx, 'customer_notes'] = generate_note(df.loc[idx])
        
        # Periodic save (resilient to crashes / Ctrl+C)
        if (i + 1) % SAVE_EVERY == 0:
            df.to_csv(OUTPUT_PATH, index=False)
            tqdm.write(f"💾 Saved checkpoint at note {i + 1}")
    
    # Final save
    df.to_csv(OUTPUT_PATH, index=False)
    
    # Sanity check
    notes_filled = (df['customer_notes'] != '').sum()
    print(f"\n✅ Done. Total orders with notes: {notes_filled}/{len(df)}")
    print(f"\n📋 Sample notes:")
    sample = df[df['customer_notes'] != ''].sample(3, random_state=RANDOM_SEED)
    for _, row in sample.iterrows():
        print(f"\n--- {row['order_id']} | {row['full_name']} | {row['country']} ---")
        print(row['customer_notes'])


if __name__ == "__main__":
    main()