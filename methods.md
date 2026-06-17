# Methods

This project uses synthetic data to demonstrate a provider-level immunization compliance analytics workflow.

## Data Quality Checks
- Primary-key uniqueness for providers, visits, and unenrollments
- Referential integrity across provider IDs
- Missingness by table and field
- Validity checks for coded fields
- Corrective-action logic checks

## Descriptive Analysis
- Compliance by provider type, jurisdiction, urbanicity, practice size, year, and quarter
- Domain failure rates for storage, temperature, documentation, inventory, and eligibility
- Helpdesk ticket distribution by compliance status
- Unenrollment rate by provider segment

## Risk Flagging
Providers are assigned points based on noncompliance rate, helpdesk burden, corrective actions, storage failures, and rural location. The score is designed for demonstration only and is not a validated predictive model.

## Statistical Analysis Templates
SAS scripts include templates for PROC FREQ, PROC LOGISTIC, PROC LIFETEST, and PROC PHREG.
