"""
01_data_quality_check.py
Project: Immunization Compliance Analytics Dashboard
Author: Aly Drame, MD, MPH, MBA
Purpose: Automated data quality checks on all three tables.
Note: All data are synthetic.
"""

import pandas as pd
import numpy as np
import os

os.makedirs('outputs', exist_ok=True)

# ── Load data ──────────────────────────────────────────────────────
print("Loading datasets...")
providers     = pd.read_csv('data/synthetic/providers.csv')
visits        = pd.read_csv('data/synthetic/visits.csv')
unenrollments = pd.read_csv('data/synthetic/unenrollments.csv')

print(f"  providers:     {len(providers):,} rows")
print(f"  visits:        {len(visits):,} rows")
print(f"  unenrollments: {len(unenrollments):,} rows")

# ── Function: missingness report ───────────────────────────────────
def missingness_report(df: pd.DataFrame, table_name: str) -> pd.DataFrame:
    report = pd.DataFrame({
        'table':           table_name,
        'field':           df.columns,
        'total_records':   len(df),
        'missing_count':   df.isnull().sum().values,
        'pct_missing':     (df.isnull().sum().values / len(df) * 100).round(1),
        'completeness_pct':(
            (1 - df.isnull().sum().values / len(df)) * 100
        ).round(1)
    })
    return report.sort_values('pct_missing', ascending=False)

# ── Function: duplicate detection ─────────────────────────────────
def check_duplicates(df: pd.DataFrame, key_col: str,
                      table_name: str) -> None:
    dupes = df[df.duplicated(subset=[key_col], keep=False)]
    if len(dupes) > 0:
        print(f"  ⚠️  {table_name}: {len(dupes)} duplicate rows on {key_col}")
    else:
        print(f"  ✅ {table_name}: No duplicates on {key_col}")

# ── Function: referential integrity ───────────────────────────────
def check_referential_integrity(child_df: pd.DataFrame,
                                 parent_df: pd.DataFrame,
                                 child_key: str,
                                 parent_key: str,
                                 child_name: str,
                                 parent_name: str) -> None:
    orphans = child_df[
        ~child_df[child_key].isin(parent_df[parent_key])
    ]
    if len(orphans) > 0:
        print(f"  ⚠️  {child_name}.{child_key}: "
              f"{len(orphans)} records not found in {parent_name}")
    else:
        print(f"  ✅ {child_name}.{child_key} → {parent_name}: "
              f"Referential integrity OK")

# ── Function: coded value validation ──────────────────────────────
def check_coded_values(df: pd.DataFrame,
                        col: str,
                        valid_values: list,
                        table_name: str) -> None:
    if col not in df.columns:
        return
    invalid = df[
        df[col].notna() & ~df[col].isin(valid_values)
    ]
    if len(invalid) > 0:
        print(f"  ⚠️  {table_name}.{col}: "
              f"{len(invalid)} invalid values found")
        print(f"       Found: {df[col].dropna().unique()[:5]}")
        print(f"       Expected: {valid_values}")
    else:
        print(f"  ✅ {table_name}.{col}: All values valid")

# ══════════════════════════════════════════════════════════════════
# RUN ALL CHECKS
# ══════════════════════════════════════════════════════════════════

print("\n" + "="*60)
print("DATA QUALITY REPORT")
print("Immunization Provider Compliance Analytics")
print("All data are synthetic — portfolio demonstration")
print("="*60)

# 1. Missingness
print("\n[1] COMPLETENESS REPORT")
all_reports = pd.concat([
    missingness_report(providers,     'providers'),
    missingness_report(visits,        'visits'),
    missingness_report(unenrollments, 'unenrollments')
])
missing_summary = all_reports[all_reports['pct_missing'] > 0]
print(missing_summary[['table','field','missing_count',
                         'pct_missing','completeness_pct']].to_string(index=False))
all_reports.to_csv('outputs/missingness_report.csv', index=False)
print("\n  Saved → outputs/missingness_report.csv")

# 2. Duplicates
print("\n[2] DUPLICATE DETECTION")
check_duplicates(providers,     'provider_id',     'providers')
check_duplicates(visits,        'visit_id',        'visits')
check_duplicates(unenrollments, 'unenrollment_id', 'unenrollments')

# 3. Referential integrity
print("\n[3] REFERENTIAL INTEGRITY")
check_referential_integrity(visits,        providers, 'provider_id',
                             'provider_id', 'visits', 'providers')
check_referential_integrity(unenrollments, providers, 'provider_id',
                             'provider_id', 'unenrollments', 'providers')

# 4. Coded value validation
print("\n[4] CODED VALUE VALIDATION")
check_coded_values(providers, 'active_flag',     ['Y','N'], 'providers')
check_coded_values(providers, 'unenrolled_flag', ['Y','N'], 'providers')
check_coded_values(visits, 'compliant_flag',
                   ['Y','N'], 'visits')
check_coded_values(visits, 'domain_storage',
                   ['Y','N'], 'visits')
check_coded_values(visits, 'corrective_action_issued',
                   ['Y','N'], 'visits')
check_coded_values(visits, 'visit_type',
                   ['Scheduled','Unannounced'], 'visits')

# 5. Business logic checks
print("\n[5] BUSINESS LOGIC VALIDATION")

# Negative helpdesk tickets
neg_tickets = visits[visits['helpdesk_tickets'] < 0]
if len(neg_tickets) > 0:
    print(f"  ⚠️  {len(neg_tickets)} records with negative helpdesk tickets")
else:
    print("  ✅ helpdesk_tickets: No negative values")

# CA type should be null when CA not issued
ca_logic_error = visits[
    (visits['corrective_action_issued'] == 'N') &
    visits['corrective_action_type'].notna() &
    (visits['corrective_action_type'] != 'None')
]
if len(ca_logic_error) > 0:
    print(f"  ⚠️  {len(ca_logic_error)} records: CA type populated "
          f"when CA not issued")
else:
    print("  ✅ Corrective action logic: No violations")

# One unenrollment per provider max
dup_unenroll = unenrollments[
    unenrollments.duplicated(subset=['provider_id'], keep=False)
]
if len(dup_unenroll) > 0:
    print(f"  ⚠️  {len(dup_unenroll)} providers with multiple unenrollments")
else:
    print("  ✅ Unenrollments: One record per provider")

print("\n" + "="*60)
print("DATA QUALITY CHECK COMPLETE")
print("="*60)
