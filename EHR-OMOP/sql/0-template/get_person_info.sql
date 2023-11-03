with P as (
    select distinct person_id
    from {{ work_project }}.{{ work_dataset }}.event
),
AD as (
    select person_id, death_date, cause_concept_id
    from {{ ref_project }}.{{ ref_dataset }}.death
    join P using (person_id)
),
OP as (
    select person_id, max(observation_period_end_DATE) as last_follow_up
    from {{ ref_project }}.{{ ref_dataset }}.observation_period
    join P using (person_id)
    group by person_id
),
AP as (
    select * from {{ ref_project }}.{{ ref_dataset }}.person
    join P using (person_id)
)
select AP.person_id, gender_concept_id,
    year_of_birth, month_of_birth, day_of_birth,
    race_concept_id, ethnicity_concept_id,
    AD.death_date,
    AD.cause_concept_id,
    OP.last_follow_up
    from AP
    left join AD using (person_id)
    left join OP using (person_id)
;