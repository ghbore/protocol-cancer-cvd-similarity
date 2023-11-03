declare TARGET_CONCEPT ARRAY<INT64>;
declare CS_NAME STRING;
declare CS_DOMAIN STRING DEFAULT "condition_era";
declare CS_DESC STRING DEFAULT "";

set TARGET_CONCEPT = {{ target_concept }};
set CS_NAME = "{{ codeset_name }}";
set CS_DOMAIN = "{{ codeset_domain }}";
set CS_DESC = "{{ codeset_desc }}";

insert into {{ work_project }}.{{ work_dataset }}.codeset_definition
    (codeset_id, codeset_name, domain, codeset_description)
select count(*) as codeset_id,
    CS_NAME as codeset_name,
    CS_DOMAIN as domain,
    CS_DESC as codeset_description
from {{ work_project }}.{{ work_dataset }}.codeset_definition
where not exists (
    select codeset_id from {{ work_project }}.{{ work_dataset }}.codeset_definition
    where codeset_name = CS_NAME
)
;

insert into {{ work_project }}.{{ work_dataset }}.codeset
    (codeset_id, concept_id)
with CS as (
    select codeset_id from {{ work_project }}.{{ work_dataset }}.codeset_definition
    where codeset_name = CS_NAME
),
CC as (
    with CD as (
        select * from UNNEST(TARGET_CONCEPT) as concept_id
        union distinct
        select distinct c.concept_id
        from {{ ref_project }}.{{ ref_dataset }}.concept c
        join (
            select ancestor_concept_id, descendant_concept_id
            from {{ ref_project }}.{{ ref_dataset }}.concept_ancestor
            where ancestor_concept_id in UNNEST(TARGET_CONCEPT)
        ) ca
        on c.concept_id = ca.descendant_concept_id
            and c.invalid_reason is null
    ),
    CM as (
        select distinct cr.concept_id_1 as concept_id
        from (
            select concept_id_1, concept_id_2
            from {{ ref_project }}.{{ ref_dataset }}.concept_relationship
            where relationship_id = "Maps to" and
                invalid_reason is null
        ) cr
        join CD
        on CD.concept_id = cr.concept_id_2
    )
    select concept_id from CD
    union distinct
    select concept_id from CM
)
select CS.codeset_id, CC.concept_id
from CS, CC
where not exists (
    select codeset_id from {{ work_project }}.{{ work_dataset }}.codeset
    join CS using (codeset_id)
)
;
