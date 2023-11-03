with P as (
    select distinct person_id
    from {{ work_project }}.{{ work_dataset }}.event
),
SC as (
    with SD as (
        select 4298794 as concept_id
        union distinct
        select distinct c.concept_id
        from {{ ref_project }}.{{ ref_dataset }}.concept c
        join (
            select ancestor_concept_id, descendant_concept_id
            from {{ ref_project }}.{{ ref_dataset }}.concept_ancestor
            where ancestor_concept_id = 4298794
        ) ca
        on c.concept_id = ca.descendant_concept_id
            and c.invalid_reason is null
    ),
    SM as (
        select distinct cr.concept_id_1 as concept_id
        from (
            select concept_id_1, concept_id_2
            from {{ ref_project }}.{{ ref_dataset }}.concept_relationship
            where relationship_id = "Maps to" and
                invalid_reason is null
        ) cr
        join SD
        on SD.concept_id = cr.concept_id_2
    )
    select concept_id from SD
    union distinct
    select concept_id from SM
)
select observation_id, ob.person_id, observation_concept_id, observation_date
from {{ ref_project }}.{{ ref_dataset }}.observation ob
join P using (person_id)
join SC on ob.observation_concept_id = SC.concept_id
;