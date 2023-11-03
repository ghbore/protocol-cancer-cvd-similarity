DROP TABLE if exists {{ work_project }}.{{ work_dataset }}.event;
CREATE TABLE {{ work_project }}.{{ work_dataset }}.event (
  event_id bigint not null,
  person_id bigint not null,
  concept_id bigint not null,
  start_date date,
  end_date date
);