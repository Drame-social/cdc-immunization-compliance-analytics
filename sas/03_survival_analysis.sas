/*====================================================================
  03_survival_analysis.sas
  Purpose: Survival analysis — time to provider unenrollment
  Public health question: At what point do different provider types
  typically unenroll, and which groups unenroll earliest?
====================================================================*/

/* Merge unenrollment time data with provider attributes */
proc sql;
    create table immuno.survival_data as
    select p.provider_id,
           p.provider_type,
           p.urban_rural,
           p.practice_size,
           p.unenrolled_flag,
           case when u.months_to_unenrollment is not null
                then u.months_to_unenrollment
                else 36   /* administrative censoring at 36 months */
           end                              as time_months,
           case when p.unenrolled_flag='Y'  then 1
                else 0                      end as event_occurred
    from immuno.providers p
    left join immuno.unenrollments u
           on p.provider_id = u.provider_id;
quit;

/* Kaplan-Meier survival curves by provider type */
title "Kaplan-Meier Survival — Time to Unenrollment by Provider Type";
proc lifetest data=immuno.survival_data
    plots=survival(cb atrisk)
    outsurv=immuno.km_estimates;
    time time_months * event_occurred(0);
    strata provider_type;
run;

/* Kaplan-Meier by urban/rural classification */
title "Kaplan-Meier Survival — Time to Unenrollment by Urban/Rural";
proc lifetest data=immuno.survival_data
    plots=survival(cb);
    time time_months * event_occurred(0);
    strata urban_rural;
run;

/* Cox proportional hazards model */
title "Cox Proportional Hazards Model — Unenrollment";
proc phreg data=immuno.survival_data;
    class provider_type (ref='Family Medicine')
          urban_rural   (ref='Urban')
          practice_size (ref='6-10') / param=ref;
    model time_months * event_occurred(0) =
          provider_type
          urban_rural
          practice_size;
    hazardratio provider_type / cl=wald;
    hazardratio urban_rural   / cl=wald;
    ods output HazardRatios = immuno.hazard_ratios;
run;

proc print data=immuno.hazard_ratios noobs; run;
