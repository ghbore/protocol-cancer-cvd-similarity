declare CS_NAME STRING;
declare PRE_DAY int64 default 180;

set CS_NAME = "{{ codeset_name }}";

merge {{ work_project }}.{{ work_dataset }}.event
using (
    with CD as (
        select * from {{ work_project }}.{{ work_dataset }}.codeset_definition
        where codeset_name = CS_NAME
    ),
    CC as (
        select distinct concept_id
        from {{ work_project }}.{{ work_dataset }}.codeset
        join CD
        using (codeset_id)
    )
    (
        --- condition_era
        select ce.* from (
            select condition_era_id as event_id, person_id, 
                condition_concept_id as concept_id,
                condition_era_start_DATE as start_date,
                condition_era_end_DATE as end_date
            from {{ ref_project }}.{{ ref_dataset }}.condition_era ce
            join CC on ce.condition_concept_id = CC.concept_id
            where exists (select * from CD where domain = "condition_era")
        ) ce
        join {{ ref_project }}.{{ ref_dataset }}.observation_period op
        on op.person_id = ce.person_id
            and date_sub(ce.start_date, interval PRE_DAY day)
                >= op.observation_period_start_DATE
    )
    union distinct
    (
        --- drug_era
        select de.* from (
            select drug_era_id as event_id, person_id,
                drug_concept_id as concept_id,
                drug_era_start_DATE as start_date,
                drug_era_end_DATE as end_date
            from {{ ref_project }}.{{ ref_dataset }}.drug_era de
            join CC on de.drug_concept_id = CC.concept_id
            where exists (select * from CD where domain = "drug_era")
        ) de
        join {{ ref_project }}.{{ ref_dataset }}.observation_period op 
        on op.person_id = de.person_id
            and date_sub(de.start_date, interval PRE_DAY day)
                >= op.observation_period_start_DATE
    )
)
on FALSE
when not matched then
    insert (event_id, person_id, concept_id, start_date, end_date)
    values (event_id, person_id, concept_id, start_date, end_date)
;