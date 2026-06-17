# Data Dictionary — CDC Immunization Compliance Analytics

## Table: providers.csv
| Column | Type | Description | Values |
|---|---|---|---|
| provider_id | string | Unique synthetic provider ID | PRV00001–PRV01000 |
| vfc_pin | string | Simulated VFC PIN | VFC-00001–VFC-01000 |
| provider_type | string | Clinical setting | Pediatrics, Family Medicine, Internal Medicine, Pharmacy, Community Health Center, Hospital Clinic, OB/GYN |
| jurisdiction_id | string | Jurisdiction/state code | GA, FL, TX, NY, CA, OH, PA, IL, NC, AZ, MI, WA, CO, MN, TN |
| urban_rural | string | Location classification | Urban, Suburban, Rural |
| practice_size | string | Practice size | 1-2, 3-5, 6-10, 11+ |
| enrollment_year | integer | Year enrolled | 2019–2023 |
| months_enrolled | integer | Months enrolled | 6–60 |
| active_flag | string | Currently active | Y, N |
| unenrolled_flag | string | Ever unenrolled during observation period | Y, N |

## Table: visits.csv
One record per synthetic compliance visit.

| Column | Type | Description |
|---|---|---|
| visit_id | string | Unique visit ID |
| provider_id | string | Foreign key to providers |
| visit_date | date | Compliance visit date |
| visit_year | integer | Year derived from visit_date |
| visit_quarter | integer | Quarter derived from visit_date |
| compliant_flag | string | Overall compliance result, Y/N with intentional missingness |
| domain_storage | string | Storage and handling compliance |
| domain_temperature | string | Temperature monitoring compliance |
| domain_documentation | string | Documentation compliance |
| domain_inventory | string | Inventory compliance |
| domain_patient_eligibility | string | Eligibility verification compliance |
| corrective_action_issued | string | Corrective action issued flag |
| corrective_action_type | string | Education, Warning Letter, Suspension, or blank |
| helpdesk_tickets | integer | Ticket count opened near visit |
| visit_type | string | Scheduled or Unannounced |
| staff_conducting | string | Staff type conducting visit |

## Table: unenrollments.csv
One record per provider who unenrolled.

| Column | Type | Description |
|---|---|---|
| unenrollment_id | string | Unique unenrollment ID |
| provider_id | string | Foreign key to providers |
| unenrollment_date | date | Formal unenrollment date |
| months_to_unenrollment | integer | Months from enrollment to unenrollment |
| unenrollment_reason | string | Reason for unenrollment, with intentional missingness |
| initiated_by | string | Provider, Program Staff, or Automated |
