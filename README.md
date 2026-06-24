# CDC Immunization Compliance Analytics

**Author:** Aly Drame, MD, MPH, MBA  
**Languages:** Python · SQL · SAS · Power BI  
**Domain:** Immunization program compliance, provider risk analytics  
**Data:** Synthetic portfolio dataset — no confidential CDC records or real provider data included

---

## Public Health Question

Which immunization provider characteristics are associated with noncompliance and unenrollment from immunization programs, and how can program staff identify high-risk providers before unenrollment occurs?

---

## Dataset

This repository uses three synthetic relational tables:

| File | Records | Description |
|------|---------|-------------|
| `data/synthetic/providers.csv` | 1,000 | Provider registry with enrollment and site characteristics |
| `data/synthetic/visits.csv` | 4,037 | Compliance visit records with findings and outcomes |
| `data/synthetic/unenrollments.csv` | 108 | Provider unenrollment events with reason codes |

---

## Methods

| Tool | Purpose |
|------|---------|
| **Python** | Synthetic data generation, data quality checks, compliance summaries, risk flags, visualizations |
| **SQL** | Schema validation, completeness checks, compliance trend queries, provider risk scoring |
| **SAS** | Descriptive analysis, logistic regression (unenrollment predictors), survival analysis, ODS report |
| **Power BI** | Compliance dashboard, regional heat maps, risk tier visualization |

---

## Repository Structure

```
cdc-immunization-compliance-analytics/
├── README.md
├── data/
│   └── synthetic/
│       ├── providers.csv
│       ├── visits.csv
│       └── unenrollments.csv
├── python/
│   ├── 00_generate_synthetic_data.py
│   ├── 01_data_quality_check.py
│   └── 02_compliance_analysis.py
├── sql/
├── sas/
└── powerbi/
```

---

## How to Run

```bash
pip install pandas numpy matplotlib seaborn
python python/00_generate_synthetic_data.py
python python/01_data_quality_check.py
python python/02_compliance_analysis.py
```

---

## Data Disclaimer

All data are synthetic and generated for portfolio demonstration purposes. No real CDC data, provider-level program records, patient information, or restricted public health data are included.
