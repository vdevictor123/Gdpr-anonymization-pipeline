# Privacy-Preserving E-commerce Data Pipeline

## What This Project Does

This project builds a GDPR-compliant anonymization pipeline for an e-commerce company (NovaShop). It takes a database of 5,000 synthetic customer records containing real-looking PII and transforms it into a fully anonymized dataset safe for export to cloud analytics tools — without losing analytical value.

## Tech Stack

- **MySQL 8.0** — database and anonymization logic (8 SQL techniques)
- **Python 3.x** — data loading and pipeline orchestration
- **Ollama + llama3.2:3b** — local LLM for PII detection in free-text fields
- **Faker** — synthetic dataset generation

## Project Structure

```
Project_GDPR_GitHub/
│
├── README.md
├── README_ES.md
├── .gitignore
│
├── sql/
│   ├── 01_import_schema.sql
│   ├── 02_masking_email.sql
│   ├── 03_masking_phone.sql
│   ├── 04_hashing_customer_id.sql
│   ├── 05_generalize_birthdate.sql
│   ├── 06_generalize_postal_code.sql
│   ├── 07_noise_injection_order_value.sql
│   ├── 08_truncate_ip.sql
│   ├── 09_k_anonymity_check.sql
│   ├── 10_full_anonymization_pipeline.sql
│   └── PART_2_PURPOSE_LIMITED_ANALYTICAL_VIEWS.sql
│
├── python/
│   ├── 02_load_to_mysql.py
│   ├── Script_faker_data.py
│   ├── Script_Notes_customer_ollama.py
│   ├── anonymize_notes.py
│   └── pii_detection_prompt.txt
│
└── docs/
    ├── Road_map_project_GDPP.pdf
    ├── 02_load_to_mysql_conceptos.pdf
    └── Explicacion_script_faker_data.pdf
```

## Pipeline Overview

1. **Data generation** — 5,000 synthetic customer records with realistic PII across 6 European countries (ES, DE, FR, NL, IE, UK)
2. **Schema creation & import** — load raw CSV into MySQL using Python connector
3. **SQL anonymization** — apply 8 anonymization techniques to structured columns
4. **K-anonymity validation** — verify re-identification risk using quasi-identifier analysis
5. **Purpose-limited views** — create analytical views with minimal quasi-identifiers
6. **LLM text anonymization** — detect and replace PII in 272 free-text customer notes using Ollama

## Anonymization Techniques

| Technique | Column | What It Protects |
|-----------|--------|------------------|
| Partial masking | email | Direct identity |
| Suffix masking | phone | Direct contact |
| SHA2 hashing | customer_id | Cross-table linkage |
| Age range generalization | birth_date | Quasi-identifier |
| Postal prefix generalization | postal_code | Precise geolocation |
| ±5% noise injection | order_value_eur | Exact-value matching |
| IP truncation (last 2 octets) | ip_address | Device fingerprinting |
| K-anonymity validation | multiple | Re-identification risk |

## Results

| Metric | Value |
|--------|-------|
| Customer records anonymized | 5,000 |
| Anonymization techniques applied | 8 |
| Free-text notes processed (Ollama) | 272 |
| K-anonymity violations — 2 quasi-ids | 0 |
| K-anonymity violations — 3 quasi-ids | 18 |
| K-anonymity violations — 4 quasi-ids | 1,085 (resolved with purpose-limited views) |
| Ollama PII detection accuracy | ~95% |
| Cloud API calls | 0 |

## Problems Encountered & Solutions

1. **MySQL Table Data Import Wizard truncated at 121 rows** — The GUI import tool silently stopped at row 121. Solved by writing a custom Python script (`02_load_to_mysql.py`) using `mysql-connector-python` to load the full 5,000-row CSV programmatically.

2. **LOAD DATA LOCAL INFILE blocked (Error 2068)** — MySQL's native file-load command was disabled by server configuration. Solved by switching entirely to `mysql-connector-python`, which handles inserts via Python without needing file-system permissions on the server.

3. **K-anonymity violations with 4 quasi-identifiers** — Combining gender, country, age range, and postal prefix produced 1,085 groups of size < 5. Solved by implementing purpose-limited analytical views: each view exposes only the columns needed for its specific analysis (2–3 quasi-ids max), bringing violations to zero for all practical use cases.

4. **Ollama ~95% PII detection accuracy** — The llama3.2:3b model misses edge cases such as misspellings, non-standard phone formats, and ambiguous names. Documented as a known limitation. In production, this would be combined with regex-based rule patterns for high-confidence PII types.

## How to Run

**Prerequisites:**
- MySQL 8.0+
- Python 3.8+ with `mysql-connector-python` and `ollama` packages
- Ollama installed locally with `llama3.2:3b` model pulled

```bash
pip install mysql-connector-python ollama
ollama pull llama3.2:3b
```

**Run the pipeline:**
```bash
# 1. Generate synthetic data
python python/Script_faker_data.py

# 2. Load data into MySQL
python python/02_load_to_mysql.py

# 3. Run SQL scripts 01–10 in order via MySQL Workbench or CLI
# 4. Anonymize free-text notes
ollama serve  # in a separate terminal
python python/anonymize_notes.py
```

## Author

Victor Toret Marin
LinkedIn: www.linkedin.com/in/victor-toret-marin-458674321
GitHub: https://github.com/vdevictor123
