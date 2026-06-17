# DAX Measures — Immunization Compliance Dashboard
**Author:** Aly Drame, MD, MPH, MBA
**File:** cdc_immunization_dashboard.pbix

## Core Compliance Measures

### Total Providers
```dax
Total Providers = COUNTROWS(providers)
Counts all rows in the providers table. Used in Executive Summary card visuals.
Compliant Providers
Compliant Providers =
CALCULATE(
    COUNTROWS(visits),
    visits[compliant_flag] = "Y"
)
Counts visits where the overall compliance flag is Y.
Compliance Rate
Compliance Rate =
DIVIDE(
    [Compliant Providers],
    CALCULATE(COUNTROWS(visits),
              visits[compliant_flag] IN {"Y","N"}),
    0
)
Divides compliant visits by total non-missing visits. Formatted as percentage. Excludes records where compliant_flag is null.
Noncompliance Rate
Noncompliance Rate =
1 - [Compliance Rate]
High Risk Providers
High Risk Providers =
CALCULATE(
    COUNTROWS(providers),
    providers[unenrolled_flag] = "N",
    CALCULATE(
        SUM(visits[helpdesk_tickets]),
        visits[compliant_flag] = "N"
    ) >= 3
)
Counts active providers with 3 or more helpdesk tickets who are currently noncompliant. These are the providers most needing immediate outreach.
Unenrollment Rate
Unenrollment Rate =
DIVIDE(
    CALCULATE(COUNTROWS(providers),
              providers[unenrolled_flag] = "Y"),
    COUNTROWS(providers),
    0
)
Average Helpdesk Tickets
Avg Helpdesk Tickets =
AVERAGE(visits[helpdesk_tickets])
Corrective Action Rate
Corrective Action Rate =
DIVIDE(
    CALCULATE(COUNTROWS(visits),
              visits[corrective_action_issued] = "Y"),
    CALCULATE(COUNTROWS(visits),
              visits[corrective_action_issued] IN {"Y","N"}),
    0
)
YOY Compliance Change
YOY Compliance Change =
VAR CurrentYear =
    CALCULATE([Compliance Rate],
              YEAR(visits[visit_date]) = MAX(YEAR(visits[visit_date])))
VAR PriorYear =
    CALCULATE([Compliance Rate],
              YEAR(visits[visit_date]) = MAX(YEAR(visits[visit_date])) - 1)
RETURN
    CurrentYear - PriorYear
Shows year-over-year change in compliance rate. Used in trend indicators on the Executive Summary page.
Missing Data Rate
Missing Data Rate =
DIVIDE(
    CALCULATE(COUNTROWS(visits),
              ISBLANK(visits[compliant_flag])),
    COUNTROWS(visits),
    0
)
Used on the Data Quality page to flag jurisdictions or provider types with high missing data rates.

---

**File: powerbi/dashboard_design.md**

```markdown
# Dashboard Design — Immunization Compliance Dashboard
**Author:** Aly Drame, MD, MPH, MBA

## Page 1 — Executive Summary
**Purpose:** Give program leadership an immediate overview.

Visuals:
- Card: Total Providers (bold, large font)
- Card: Compliance Rate (percentage format, conditional color
  — green above 85%, yellow 75–85%, red below 75%)
- Card: High Risk Providers (count, red if > 0)
- Card: Unenrollment Rate (percentage)
- Card: Missing Data Rate
- Line chart: Compliance Rate by Year — with YOY annotation
- Bar chart: Compliance Rate by Provider Type — sorted descending
- KPI visual: YOY Compliance Change with up/down arrow

Slicers:
- Year (2022, 2023, 2024)
- Jurisdiction
- Urban/Rural

## Page 2 — Data Quality
**Purpose:** Monitor completeness — mirrors DCIPHER completeness dashboard.

Visuals:
- Stacked bar chart: Completeness % by field (each field = one bar)
- Table: Jurisdiction, total_visits, pct_missing_compliance,
  pct_missing_storage, pct_missing_docs, completeness_status
- Conditional formatting: red cells below 90% completeness

Slicers:
- Year
- Jurisdiction

## Page 3 — Compliance Trends
**Purpose:** Show change over time by provider segment.

Visuals:
- Line chart: Monthly compliance rate with 3-month rolling average
- Clustered bar: Compliant vs Noncompliant by provider_type and year
- Small multiples or matrix: Compliance rate by jurisdiction and year

Slicers:
- Provider Type
- Urban/Rural
- Practice Size

## Page 4 — Jurisdiction Map
**Purpose:** Geographic view of compliance variation.

Visuals:
- Filled map: US states colored by compliance rate
  (dark green = high compliance, dark red = low)
- Table: Jurisdiction, provider_count, compliance_rate,
  unenrollment_rate, avg_tickets, jurisdiction_rank
- Bar chart: Top 5 and bottom 5 jurisdictions by compliance rate

Slicers:
- Year
- Provider Type

## Page 5 — Provider Risk
**Purpose:** Flag individual providers needing immediate outreach.

Visuals:
- Table: provider_id, provider_type, jurisdiction, urban_rural,
  noncompliance_rate, total_tickets, corrective_actions,
  risk_score, risk_category
- Conditional formatting: HIGH RISK rows highlighted red,
  MODERATE RISK highlighted orange
- Drillthrough: click any row to see that provider's full
  visit history
- Bar chart: Risk category distribution

Slicers:
- Risk Category
- Jurisdiction
- Provider Type
