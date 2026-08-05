# UrbanCart Big Data Analytics

This repository contains a complete, reusable analytics workflow for the fictional UrbanCart online retailer. It covers SQL extraction, pandas cleaning and integration, NumPy analytical methods, business visualization, and management reporting.

## Run the project

```bash
python -m pip install -r requirements.txt
python main.py
```

The driver validates the raw inputs and executes `analysis.ipynb`. It regenerates the cleaned datasets in `data/processed`, SQL and audit tables in `outputs/tables`, numerical model outputs in `outputs/model_results`, and charts in `outputs/charts`.

## Main deliverables

- `queries.sql`: ten SQLite queries required for Phase 1
- `analysis.ipynb`: Phases 1-4 in clearly labeled sections
- `main.py` and `src/pipeline.py`: one-command Phase 5 pipeline
- `data/processed/`: reusable clean customer, order, product, review, session, and time-series files
- `report.pdf`: standalone analytical report of at least 30 pages
- `executive_summary.pdf`: one-page non-technical summary
- `outputs/`: SQL results, audit evidence, NumPy models, and eight business charts


## Team Contributions

- Member 1: Keo Samnang — Implemented SQL Queries 1–4, loaded the database and external files, standardized date formats, and handled missing values.
- Member 2: Teng Nyka — Implemented SQL Queries 5–10, removed duplicate records, handled product price outliers, and reconciled the supplier product catalog.
- Member 3: Yin Panharith — Implemented RFM segmentation and cosine-similarity recommendation, created the pivot table and time-series analysis, and exported the cleaned datasets.
- Member 4: Sue Theara - Implemented the Normal Equation regression and Monte Carlo simulation, created the eight business charts and interpretations, prepared the report and executive summary, and organized the reusable pipeline and GitHub repository. 