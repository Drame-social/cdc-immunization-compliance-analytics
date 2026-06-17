"""
02_compliance_analysis.py
Project: Immunization Compliance Analytics Dashboard
Author: Aly Drame, MD, MPH, MBA
Purpose: Epidemiologic analysis of immunization provider compliance.
Note: All data are synthetic.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os

os.makedirs('outputs', exist_ok=True)

# ── Load data ──────────────────────────────────────────────────────
providers     = pd.read_csv('data/synthetic/providers.csv')
visits        = pd.read_csv('data/synthetic/visits.csv')
unenrollments = pd.read_csv('data/synthetic/unenrollments.csv')

# Merge visits with provider characteristics
visits_enr = visits.merge(providers, on = 'provider_id', how='left')

print(f"Loaded: {len(providers):,} providers, {len(visits):,} visits, "
      f"{len(unenrollments):,} unenrollments")

# ──────────────────────────────────────────────────────────
# 1. OVERALL COMPLIANCE RATE
# ──────────────────────────────────────────────────────────
v_clean = visits_enr['visits_enr'['compliant_flag'].notna()]

overall_compliance = (v_clean['compliant_flag'] == 'Y').mean() * 100

print(f"\n[1] OVERALL COMPLIANCE RATE8={overall_compliance:.1f}%")
print(f"     Visits analyzed: {len(v_clean):,}")
print(f"     Compliant: {(v_clean['compliant_flag'] == 'Y').sum():,}")

# ──────────────────────────────────────────────────────────
# 2. COMPLIANCE BY POVIDER TYPE
# ──────────────────────────────────────────────────────────
compliance_by_type = (
    v_clean
    .groupby('provider_type')['compliant_flag']
    .agg( lambda x: (x == 'Y').mean() * 100)
    .reset_index()
    .rename(columns={'compliant_flag': 'compliance_pct'})
    .sort_values('compliance_pct', ascending=False)
)

print("\n[2] COMPLIANCE RATE BY PROVIDER TYPE")
print(compliance_by_type.to_string(index=False))

# Plot: compliance by provider type
fig, ax = plt.subplots(figsize=(10, 6))
bars = ax.barh(
    compliance_by_type['provider_type'],
    compliance_by_type['compliance_pct'],
    color=['#2A9D8F' if x >= overall_compliance
            else '#E76F51' for x in compliance_by_type['compliance_pct']]
)
ax.set_xlim(60, 100)
ax.set_xmajorlocator(plt.MultipleLocator(5))
ax.set_xtick_params(labelsize=11)
ax.set_ytick_params(labelsize=11)
ax.axvline(overall_compliance, color='gray', linestyle='--',
           label=f'Overall {overall_compliance:.1f}%')
for bar, val in zip(bars, compliance_by_type['compliance_pct']):
    ax.text(bar.get_width() + 0.2, bar.get_y() + bar.get_height()/2,
            f'{val:.1f}%', va='center', fontsize=10)
ax.set_xlabel('Compliance Rate (%)', fontsize=12)
ax.set_title('Immunization Compliance Rate by Provider Type\n'
             '(Synthetic Data -- Portfolio Demonstration)', fontsize=13)
ax.legend(fontsize=10)
plt.tight_layout()
plt.savefig('outputs/compliance_by_type.png', dpi=120)
plt.close()
print("  Saved → outputs/compliance_by_type.png")

# ──────────────────────────────────────────────────────────
# 3. YEAR-OVER-YEAR TREND
# ──────────────────────────────────────────────────────────
yearly_trend = (
    v_clean
    .groupby('visit_year')['compliant_flag']
    .agg(lambda x: (x == 'Y').mean() * 100)
    .reset_index()
    .rename(columns={'compliant_flag': 'compliance_pct'})
)
yearly_trend['prior_year'] = yearly_trend['compliance_pct'].shift(1)
yearly_trend['yoy_change']  = (yearly_trend['compliance_pct']
                                 - yearly_trend['prior_year']).round(1)

print("\n[3] YEAR-OVER-YEAR TREND")
print(yearly_trend.to_string(index=False))

# ──────────────────────────────────────────────────────────
# 4. DOMAIN-LEVEL FAILURE RATES
# ──────────────────────────────────────────────────────────
domain_cols = ['domain_storage', 'domain_temperature',
                'domain_documentation', 'domain_inventory',
                'domain_patient_eligibility']
domain_labels = ['Storage', 'Temperature', 'Documentation',
                 'Inventory', 'Patient Eligibility']

domain_failures = []
for col, label in zip(domain_cols, domain_labels):
    sub = visits[visits[col].notna()]
    fail_rate = (sub[col] == 'N').mean() * 100
    domain_failures.append({'domain': label, 'failure_rate': fail_rate})

domain_df = pd.DataFrame(domain_failures).sort_values(
    'failure_rate', ascending=False)

print("\n[4] DOMAIN-LEVEL FAILURE RATES")
print(domain_df.to_string(index=False))

# ──────────────────────────────────────────────────────────
# 5. RISK SCORING
# ──────────────────────────────────────────────────────────
provider_metrics = (
    visits.dropna(subset=['compliant_flag'])
    .groupby('provider_id')
    .agg(
        total_visits       =('visit_id',          'count'),
        noncompliant_visits=('compliant_flag',   lambda x: (x == 'N').sum()),
        total_tickets      =('helpdesk_tickets',  'sum'),
        corrective_actions=('corrective_action_issued', lambda x: (x == 'Y').sum())
    )
    .reset_index()
)
provider_metrics['noncompliance_rate'] = (
    provider_metrics['noncompliant_visits'] /
    provider_metrics['total_visits'] * 100
).round(1)

def risk_score(row):
    score = 0
    if row['noncompliance_rate'] > 30: score += 3
    elif row['noncompliance_rate'] > 15: score += 2
    elif row['noncompliance_rate'] > 5: score += 1
    if row['total_tickets'] > 5: score += 3
    elif row['total_tickets'] > 2: score += 2
    elif row['total_tickets'] > 0: score += 1
    if row['corrective_actions'] >= 2: score += 2
    elif row['corrective_actions'] >= 1: score += 1
    return score

provider_metrics['risk_score']      = provider_metrics.apply(risk_score, axis=1)
provider_metrics['risk_category']   = pd.cut(
    provider_metrics['risk_score'],
    bins=[-1, 2, 4, 10],
    labels=['Low', 'Moderate', 'High']
)

risk_summary = provider_metrics['risk_category'].value_counts()
print("\n[5] RISK SCORE SUMMARY")
print(risk_summary.to_string())

# Export risk scores
risk_data = provider_metrics.merge(
    providers[['provider_id', 'provider_type','jurisdiction_id',
                'urnban_rural', 'unenrolled_flag']],
    on='provider_id', how='left')
risk_data.to_csv('outputs/provider_risk_scores.csv', index=False)

compliance_by_type.to_csv(
    'outputs/compliance_summary.csv', index=False)

print("\nAnalysis complete. Outputs saved to outputs/")
