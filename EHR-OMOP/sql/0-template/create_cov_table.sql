DROP TABLE if exists {{ work_project }}.{{ work_dataset }}.cov;
CREATE TABLE {{ work_project }}.{{ work_dataset }}.cov (
  event_id bigint not null,
  person_id bigint not null,
  concept_id bigint not null,
  start_date date,
  end_date date
);