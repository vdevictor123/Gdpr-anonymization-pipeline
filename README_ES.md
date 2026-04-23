# Pipeline de Datos E-commerce con Preservación de Privacidad

## Qué hace este proyecto

Este proyecto construye un pipeline de anonimización conforme al RGPD para una empresa de e-commerce (NovaShop). Toma una base de datos de 5.000 registros sintéticos de clientes con datos personales realistas y los transforma en un dataset completamente anonimizado, apto para exportar a herramientas de analítica en la nube, sin perder valor analítico.

## Stack tecnológico

- **MySQL 8.0** — base de datos y lógica de anonimización (8 técnicas SQL)
- **Python 3.x** — carga de datos y orquestación del pipeline
- **Ollama + llama3.2:3b** — LLM local para detección de datos personales en texto libre
- **Faker** — generación del dataset sintético

## Estructura del proyecto

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

## Fases del pipeline

1. **Generación de datos** — 5.000 registros sintéticos de clientes con datos personales realistas de 6 países europeos (ES, DE, FR, NL, IE, UK)
2. **Creación del esquema e importación** — carga del CSV en MySQL mediante conector Python
3. **Anonimización SQL** — aplicación de 8 técnicas de anonimización a columnas estructuradas
4. **Validación de k-anonimidad** — verificación del riesgo de re-identificación mediante análisis de quasi-identificadores
5. **Vistas de propósito limitado** — creación de vistas analíticas con el mínimo número de quasi-identificadores
6. **Anonimización de texto con LLM** — detección y sustitución de datos personales en 272 notas de texto libre usando Ollama

## Técnicas de anonimización

| Técnica | Columna | Qué protege |
|---------|---------|-------------|
| Enmascaramiento parcial | email | Identidad directa |
| Enmascaramiento de sufijo | phone | Contacto directo |
| Hash SHA2 | customer_id | Vinculación entre tablas |
| Generalización por rango de edad | birth_date | Quasi-identificador |
| Generalización de prefijo postal | postal_code | Geolocalización precisa |
| Inyección de ruido ±5% | order_value_eur | Coincidencia de valor exacto |
| Truncamiento de IP (últimos 2 octetos) | ip_address | Huella digital del dispositivo |
| Validación de k-anonimidad | múltiples | Riesgo de re-identificación |

## Resultados

| Métrica | Valor |
|---------|-------|
| Registros de clientes anonimizados | 5.000 |
| Técnicas de anonimización aplicadas | 8 |
| Notas de texto procesadas (Ollama) | 272 |
| Violaciones de k-anonimidad — 2 quasi-ids | 0 |
| Violaciones de k-anonimidad — 3 quasi-ids | 18 |
| Violaciones de k-anonimidad — 4 quasi-ids | 1.085 (resueltas con vistas de propósito limitado) |
| Precisión de detección de PII con Ollama | ~95% |
| Llamadas a APIs en la nube | 0 |

## Problemas encontrados y soluciones

1. **El asistente de importación de MySQL truncaba los datos a 121 filas** — La herramienta gráfica de importación se detenía silenciosamente en la fila 121. Se resolvió escribiendo un script Python personalizado (`02_load_to_mysql.py`) con `mysql-connector-python` para cargar el CSV completo de 5.000 filas de forma programática.

2. **LOAD DATA LOCAL INFILE bloqueado (Error 2068)** — El comando nativo de carga de ficheros de MySQL estaba deshabilitado por la configuración del servidor. Se resolvió usando exclusivamente `mysql-connector-python`, que gestiona las inserciones desde Python sin necesitar permisos de sistema de ficheros en el servidor.

3. **Violaciones de k-anonimidad con 4 quasi-identificadores** — La combinación de género, país, rango de edad y prefijo postal generaba 1.085 grupos de tamaño menor que 5. Se resolvió implementando vistas analíticas de propósito limitado: cada vista expone únicamente las columnas necesarias para su análisis específico (máximo 2–3 quasi-ids), reduciendo las violaciones a cero en todos los casos de uso prácticos.

4. **Precisión de Ollama ~95% en detección de PII** — El modelo llama3.2:3b no detecta casos límite como erratas, formatos de teléfono no estándar y nombres ambiguos. Documentado como limitación conocida. En producción, se combinaría con patrones de expresiones regulares para los tipos de PII de alta confianza.

## Cómo ejecutarlo

**Requisitos previos:**
- MySQL 8.0+
- Python 3.8+ con los paquetes `mysql-connector-python` y `ollama`
- Ollama instalado localmente con el modelo `llama3.2:3b` descargado

```bash
pip install mysql-connector-python ollama
ollama pull llama3.2:3b
```

**Ejecutar el pipeline:**
```bash
# 1. Generar datos sintéticos
python python/Script_faker_data.py

# 2. Cargar datos en MySQL
python python/02_load_to_mysql.py

# 3. Ejecutar los scripts SQL 01–10 en orden (MySQL Workbench o CLI)
# 4. Anonimizar las notas de texto libre
ollama serve  # en un terminal separado
python python/anonymize_notes.py
```

## Autor

Victor Toret Marin
LinkedIn: www.linkedin.com/in/victor-toret-marin-458674321
GitHub: https://github.com/vdevictor123
