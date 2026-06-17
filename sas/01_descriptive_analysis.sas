/*====================================================================
  01_descriptive_analysis.sas
  Project: Immunization Compliance Analytics Dashboard
  Author:  Aly Drame, MD, MPH, MBA
  Purpose: Descriptive analysis of provider compliance patterns
  Note:    All data are synthetic — generated for portfolio use
====================================================================*/

/* ── Set library ─────────────────────────────────────────────────── */
libname immuno "/home/yourusername/immunization";

/* ── Import data ─────────────────────────────────────────────────── */
proc import
    datafile="/home/yourusername/immunization/providers.csv"
    out=immuno.providers dbms=csv replace;
    guessingrows=1000;
run;

proc import
    datafile="/home/yourusername/immunization/visits.csv"
    out=immuno.visits dbms=csv replace;
    guessingrows=1000;
run;

proc import
    datafile="/home/yourusername/immunization/unenrollments.csv"
    out=immuno.unenrollments dbms=csv replace;
    guessingrows=1000;
run;

/* ── Verify import ───────────────────────────────────────────────── */
proc contents data=immuno.providers; run;
proc contents data=immuno.visits;    run;
proc print data=immuno.providers(obs=5); run;

/* ── Overall compliance rate ─────────────────────────────────────── */
title "Overall Compliance Rate";
proc freq data=immuno.visits;
    tables compliant_flag / missing;
run;

/* ── Compliance by provider type ─────────────────────────────────── */
title "Compliance Rate by Provider Type — Chi-Square Test";
proc freq data=immuno.visits;
    tables provider_type * compliant_flag / chisq nocol norow;
    /* Join provider_type in first */
run;

/* Create merged dataset for analyses requiring provider attributes */
proc sql;
    create table immuno.visits_full as
    select v.*, p.provider_type, p.jurisdiction_id,
                p.urban_rural, p.practice_size,
                p.enrollment_year, p.months_enrolled,
                p.unenrolled_flag
    from immuno.visits v
    join immuno.providers p on v.provider_id = p.provider_id;
quit;

/* Compliance by provider type */
title "Compliance by Provider Type";
proc freq data=immuno.visits_full;
    where compliant_flag in ('Y','N');
    tables provider_type * compliant_flag / chisq expected;
run;

/* Compliance by urban/rural */
title "Compliance by Urban/Rural Classification";
proc freq data=immuno.visits_full;
    where compliant_flag in ('Y','N');
    tables urban_rural * compliant_flag / chisq;
run;

/* Compliance by practice size */
title "Compliance by Practice Size";
proc freq data=immuno.visits_full;
    where compliant_flag in ('Y','N');
    tables practice_size * compliant_flag / chisq;
run;

/* Descriptive statistics on helpdesk tickets */
title "Helpdesk Tickets by Compliance Status";
proc means data=immuno.visits_full n mean median std min max p25 p75;
    var helpdesk_tickets;
    class compliant_flag;
run;

/* Domain failure rates */
title "Compliance Domain Failure Rates";
proc freq data=immuno.visits_full;
    tables domain_storage domain_temperature domain_documentation
           domain_inventory domain_patient_eligibility;
run;

/* Annual trend */
title "Compliance Rate by Year";
proc freq data=immuno.visits_full;
    where compliant_flag in ('Y','N');
    tables visit_year * compliant_flag / norow nocol;
run;

/* Unenrollment rate by provider type */
title "Unenrollment Rate by Provider Type";
proc freq data=immuno.providers;
    tables provider_type * unenrolled_flag / chisq;
run;
