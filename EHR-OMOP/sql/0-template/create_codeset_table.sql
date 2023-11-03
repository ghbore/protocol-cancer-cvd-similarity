DROP TABLE if exists {{ work_project }}.{{ work_dataset }}.codeset_definition;
CREATE TABLE {{ work_project }}.{{ work_dataset }}.codeset_definition (
	codeset_id INT NOT NULL,
	codeset_name STRING NOT NULL,
	domain STRING NOT NULL,
	codeset_description STRING
);

DROP TABLE if exists {{ work_project }}.{{ work_dataset }}.codeset;
CREATE TABLE {{ work_project }}.{{ work_dataset }}.codeset (
  codeset_id INT NOT NULL,
  concept_id BIGINT NOT NULL
);