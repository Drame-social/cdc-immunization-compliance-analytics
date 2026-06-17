/*====================================================================
  02_logistic_regression.sas
  Purpose: Logistic regression — predictors of provider unenrollment
  Public health question: Which characteristics independently predict
  unenrollment after adjusting for other factors?
====================================================================*/

/* Aggregate visit-level metrics to provider level for modeling */
proc sql;
    create table immuno.provider_model as
    select p.provider_id,
           p.provider_type,
           p.jurisdiction_id,
           p.urban_rural,
           p.practice_size,
           p.enrollment_year,
           p.months_enrolled,
           p.unenrolled_flag,
           count(v.visit_id)                            as total_visits,
           sum(case when v.compliant_flag='N' then 1
                    else 0 end)                         as noncompliant_visits,
           round(sum(case when v.compliant_flag='N'
                     then 1.0 else 0 end)
                 / count(v.visit_id) * 100, 1)          as noncompliance_rate,
           sum(v.helpdesk_tickets)                      as total_tickets,
           sum(case when v.corrective_action_issued='Y'
                    then 1 else 0 end)                  as corrective_actions,
           sum(case when v.domain_storage='N'
                    then 1 else 0 end)                  as storage_failures
    from immuno.providers p
    join immuno.visits v on p.provider_id = v.provider_id
    where v.compliant_flag is not null
    group by p.provider_id, p.provider_type, p.jurisdiction_id,
             p.urban_rural, p.practice_size, p.enrollment_year,
             p.months_enrolled, p.unenrolled_flag;
quit;

/* Create binary outcome variable */
data immuno.provider_model;
    set immuno.provider_model;
    unenrolled_binary = (unenrolled_flag = 'Y');
    high_tickets      = (total_tickets > 3);
    rural             = (urban_rural = 'Rural');
    small_practice    = (practice_size in ('1-2','3-5'));
run;

/* Logistic regression — multivariable model */
title "Logistic Regression — Predictors of Provider Unenrollment";
proc logistic data=immuno.provider_model descending;
    class provider_type (ref='Family Medicine')
          urban_rural   (ref='Urban')
          practice_size (ref='6-10') / param=ref;
    model unenrolled_binary =
          provider_type
          urban_rural
          practice_size
          noncompliance_rate
          total_tickets
          corrective_actions
          storage_failures
          months_enrolled;
    oddsratio provider_type / cl=wald;
    oddsratio urban_rural   / cl=wald;
    oddsratio practice_size / cl=wald;
    output out=immuno.logistic_pred p=predicted_prob;
    ods output ParameterEstimates = immuno.logistic_estimates;
    ods output OddsRatios         = immuno.odds_ratios;
run;

/* Export odds ratios for reporting */
proc export data=immuno.odds_ratios
    outfile="/home/yourusername/immunization/outputs/odds_ratios.csv"
    dbms=csv replace;
run;

/* Model summary */
title "Logistic Regression — Odds Ratios Summary";
proc print data=immuno.odds_ratios noobs; run;
