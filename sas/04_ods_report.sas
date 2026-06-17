/*====================================================================
  04_ods_report.sas
  Purpose: Produce formatted PDF summary report using ODS
  Output: outputs/immunization_compliance_report.pdf
====================================================================*/

ods pdf file="/home/yourusername/immunization/outputs/immunization_compliance_report.pdf"
    style=journal
    author="Aly Drame MD MPH MBA"
    title="Immunization Provider Compliance Report";

ods pdf text="^S;{font_size=18pt font_weight=bold just=c}
              Immunization Provider Compliance Analytics Report";
ods pdf text="^S={font_size=11pt just=c}
              Synthetic Data — Portfolio Demonstration";
ods pdf text="^S={font_size=10pt just=c}
              Analysis Date: &sysdate9";

/* Section 1 — Compliance by Provider Type */
ods pdf startpage=now;
title "Section 1 — Overall Compliance Rate by Provider Type";
proc freq data=immuno.visits_full;
    where compliant_flag in ('Y','N');
    tables provider_type * compliant_flag / nocum norow;
run;

/* Section 2 — Annual Trend */
ods pdf startpage=now;
title "Section 2 — Compliance Rate Trend by Year";
proc freq data=immuno.visits_full;
    where compliant_flag in ('Y','N');
    tables visit_year * compliant_flag / nocum norow;
run;

/* Section 3 — Domain Failure Rates */
ods pdf startpage=now;
title "Section 3 — Compliance Domain Failure Rates";
proc freq data=immuno.visits_full;
    tables domain_storage domain_temperature domain_documentation
           domain_inventory domain_patient_eligibility;
run;

/* Section 4 — Logistic Regression Results */
ods pdf startpage=now;
title "Section 4 — Predictors of Unenrollment (Odds Ratios)";
proc print data=immuno.odds_ratios noobs label; run;

ods pdf close;

title;
%put NOTE: Report saved to outputs/immunization_compliance_report.pdf;
