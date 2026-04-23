# -*- coding: utf-8 -*-
"""
Created on Mon Apr 13 18:52:40 2026

@author: victor
"""

"""
01_generate_dataset.py

Generates a synthetic e-commerce dataset for the privacy-preserving pipeline project.
- Multi-locale customers (UK, IE, DE, FR, ES, NL)
- Customers can have multiple orders (realistic distribution)
- Includes PII fields that will be anonymized in later stages
- Customer notes column is left empty here; populated by Ollama in 02_generate_notes.py

Output: data/raw/customers_orders.csv
"""
#pip install faker pandas mysql-connector-python ollama python-dotenv


import random
import pandas as pd
from faker import Faker
from datetime import datetime, timedelta
from pathlib import Path

# ---------- CONFIGURATION ----------
NUM_CUSTOMERS = 1500
NUM_ORDERS = 5000
OUTPUT_PATH = Path("data/raw/customers_orders.csv")
RANDOM_SEED = 42  # reproducibility

LOCALES = ['en_GB', 'en_IE', 'de_DE', 'fr_FR', 'es_ES', 'nl_NL']
LOCALE_TO_COUNTRY = {
    'en_GB': 'United Kingdom',
    'en_IE': 'Ireland',
    'de_DE': 'Germany',
    'fr_FR': 'France',
    'es_ES': 'Spain',
    'nl_NL': 'Netherlands',
}

PRODUCT_CATEGORIES = [
    'Apparel', 'Home & Living', 'Electronics', 'Beauty', 
    'Sports', 'Books', 'Toys', 'Accessories'
]
PAYMENT_METHODS = ['Visa', 'Mastercard', 'PayPal', 'Apple Pay', 'Klarna']
DEVICE_TYPES = ['mobile', 'desktop', 'tablet']
CUSTOMER_SEGMENTS = ['New', 'Regular', 'VIP']

# ---------- INIT ----------
random.seed(RANDOM_SEED)
Faker.seed(RANDOM_SEED)

# A Faker instance per locale, so we can pick names/addresses by country
fakers = {locale: Faker(locale) for locale in LOCALES}


# ---------- CUSTOMER GENERATION ----------
def generate_customer(customer_index: int) -> dict:
    """Generate a single customer with consistent locale-based PII."""
    locale = random.choice(LOCALES)
    fake = fakers[locale]
    
    return {
        'customer_id': f'CUST-{customer_index:06d}',
        'full_name': fake.name(),
        'email': fake.email(),
        'phone': fake.phone_number(),
        'birth_date': fake.date_of_birth(minimum_age=18, maximum_age=75),
        'gender': random.choice(['M', 'F', 'Other']),
        'country': LOCALE_TO_COUNTRY[locale],
        'city': fake.city(),
        'postal_code': fake.postcode(),
        'street_address': fake.street_address(),
        'customer_segment': random.choices(
            CUSTOMER_SEGMENTS, 
            weights=[0.5, 0.4, 0.1],  # most are New/Regular, few VIP
            k=1
        )[0],
    }


# ---------- ORDER GENERATION ----------
def generate_order(order_index: int, customer: dict) -> dict:
    """Generate a single order tied to an existing customer."""
    fake = fakers['en_GB']  # neutral fake for non-PII fields
    
    # Random datetime in the last 2 years
    days_ago = random.randint(1, 730)
    order_date = datetime.now() - timedelta(days=days_ago, hours=random.randint(0, 23))
    
    # VIP customers spend more on average
    if customer['customer_segment'] == 'VIP':
        order_value = round(random.uniform(80, 500), 2)
    elif customer['customer_segment'] == 'Regular':
        order_value = round(random.uniform(25, 200), 2)
    else:
        order_value = round(random.uniform(10, 80), 2)
    
    return {
        'order_id': f'ORD-{order_index:07d}',
        'customer_id': customer['customer_id'],
        'full_name': customer['full_name'],
        'email': customer['email'],
        'phone': customer['phone'],
        'birth_date': customer['birth_date'],
        'gender': customer['gender'],
        'country': customer['country'],
        'city': customer['city'],
        'postal_code': customer['postal_code'],
        'street_address': customer['street_address'],
        'card_last4': f'{random.randint(1000, 9999)}',
        'payment_method': random.choice(PAYMENT_METHODS),
        'order_date': order_date,
        'product_category': random.choice(PRODUCT_CATEGORIES),
        'order_value_eur': order_value,
        'device_type': random.choices(DEVICE_TYPES, weights=[0.6, 0.3, 0.1], k=1)[0],
        'ip_address': fake.ipv4_public(),
        'customer_segment': customer['customer_segment'],
        'customer_notes': '',  # placeholder, filled by Ollama later
    }


# ---------- MAIN ----------
def main():
    print(f"Generating {NUM_CUSTOMERS} customers...")
    customers = [generate_customer(i + 1) for i in range(NUM_CUSTOMERS)]
    
    print(f"Generating {NUM_ORDERS} orders distributed across customers...")
    
    # Realistic order distribution: 80/20 rule (some customers order more often)
    # Use weighted random so a small set of customers gets many orders
    customer_weights = [random.expovariate(1.0) for _ in customers]
    
    orders = []
    for i in range(NUM_ORDERS):
        chosen_customer = random.choices(customers, weights=customer_weights, k=1)[0]
        orders.append(generate_order(i + 1, chosen_customer))
    
    df = pd.DataFrame(orders)
    
    # Sanity check
    print(f"\nDataset shape: {df.shape}")
    print(f"Unique customers in dataset: {df['customer_id'].nunique()}")
    print(f"Orders per customer (top 5):")
    print(df['customer_id'].value_counts().head())
    print(f"\nCountry distribution:")
    print(df['country'].value_counts())
    print(f"\nFirst 3 rows preview:")
    print(df.head(3).to_string())
    
    # Save
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(OUTPUT_PATH, index=False)
    print(f"\n✅ Saved to: {OUTPUT_PATH}")


if __name__ == "__main__":
    main()