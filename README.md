# CDC Immunization Compliance Analytics

**Author:** Aly Drame, MD, MPH, MBA  
**Tools:** Python, SQL, SAS, Power BI  
**Data:** Synthetic portfolio dataset. No confidential CDC records or real provider data are included.

## Public Health Question
Which immunization provider characteristics are associated with noncompliance and unenrollment from immunization programs, and how can program staff identify high-risk providers before unenrollment occurs?

## Dataset
This repository includes three synthetic relational tables:

- `data/synthetic/providers.csv` — 1,000 provider records
- `data/synthetic/visits.csv` — 4,037 compliance visit records
- `data/synthetic/unenrollments.csv` — 108 unenrollment records

## Methods
- **Python:** synthetic data generation, data quality checks, summaries, risk flags, visualizations
- **SQL:** schema validation, completeness checks, compliance trends, provider risk scoring
- **SAS:** descriptive analysis, logistic regression, survival analysis, ODS reporting templates
- **Power BI:** dashboard design with DAX measures for compliance rate, risk flags, and trends

## Key Outputs
- `outputs/missingness_report.csv`
- `outputs/compliance_summary.csv`
- `outputs/provider_risk_flags.csv`
- `outputs/compliance_by_type.png`
- `outputs/trend_by_year.png`

## How to Reproduce
```bash
pip install -r requirements.txt
python python/00_generate_synthetic_data.py
python python/01_data_quality_check.py
python python/02_compliance_analysis.py
```

## Data Disclaimer
All data are synthetic and generated for portfolio demonstration purposes. No real CDC data, provider-level program records, patient information, or restricted public health data are included.
