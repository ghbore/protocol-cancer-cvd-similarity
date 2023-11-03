declare CS_NAME STRING;
declare PRE_DAY int64 default 180;

merge {{ work_project }}.{{ work_dataset }}.cov
using (
    with CC as (
        select distinct concept_id
        from {{ work_project }}.{{ work_dataset }}.codeset c
        join {{ work_project }}.{{ work_dataset }}.codeset_definition cd
        on c.codeset_id = cd.codeset_id
            and ends_with(cd.codeset_name, ", ind")
    ),
    WD as (
        select person_id,
            date_sub(start_date, interval PRE_DAY day) as start_date,
            start_date as end_date
        from {{ work_project }}.{{ work_dataset }}.event
        join CC
        using (concept_id)
    ),
    WE as (
        select person_id,
            min(start_date) as start_date,
            max(end_date) as end_date
        from (
            select *, sum(no_overlap) over (
                partition by person_id
                order by start_date
                rows between unbounded preceding and current row
            ) as part_id
            from (
                select *,
                    case when start_date > min(end_date) over (
                        partition by person_id
                        order by start_date
                        rows between 1 preceding and current row
                    ) then 1 else 0
                    end as no_overlap
                from WD
            )
        )
        group by person_id, part_id
    )
    (
        --- condition_era
        select condition_era_id as event_id, ce.person_id, 
            condition_concept_id as concept_id,
            condition_era_start_DATE as start_date,
            condition_era_end_DATE as end_date
        from {{ ref_project }}.{{ ref_dataset }}.condition_era ce
        join WE on ce.person_id = WE.person_id
            and not (
                ce.condition_era_start_DATE > WE.end_date or
                ce.condition_era_end_DATE < WE.start_date
            )
    )
    union distinct
    (
        --- drug_era
        select drug_era_id as event_id, de.person_id,
            drug_concept_id as concept_id,
            drug_era_start_DATE as start_date,
            drug_era_end_DATE as end_date
        from {{ ref_project }}.{{ ref_dataset }}.drug_era de
        join WE on de.person_id = WE.person_id
            and not (
                de.drug_era_start_DATE > WE.end_date or
                de.drug_era_end_DATE < WE.start_date
            )
    )
    union distinct
    (
        --- drug_era
        select procedure_occurrence_id as event_id, po.person_id,
            procedure_concept_id as concept_id,
            procedure_DATE as start_date,
            procedure_DATE as end_date
        from {{ ref_project }}.{{ ref_dataset }}.procedure_occurrence po
        join WE on po.person_id = WE.person_id
            and not (
                po.procedure_DATE > WE.end_date or
                po.procedure_DATE < WE.start_date
            )
    )
)
on FALSE
when not matched then
    insert (event_id, person_id, concept_id, start_date, end_date)
    values (event_id, person_id, concept_id, start_date, end_date)
;