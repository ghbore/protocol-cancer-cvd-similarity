rule prepare_config:
    output:
        "conf/disase_concept.xlsx",
        "conf/drug_concept.xlsx",
        "conf/indication_concept.xlsx",
        "conf/disease_group.xlsx",
    message:
        "prepare the configuration files in advance"


rule dump_ehr:
    input:
        config_dir="conf/",
        sql_template_dir="sql/0-template/",
    output:
        sql_cache_dir=directory("sql/1-final/"),
        export_dir=directory("export"),
    params:
        ref_project_id="",
        ref_dataset_id="",
        work_project_id="",
        work_dataset_id="",
    script:
        "00-lite.py"


rule split_cohort:
    input:
        config_dir="conf/",
        export_dir="export/",
    output:
        directory("subtask"),
    params:
        release_group_only=1,
    script:
        "01-split.R"


rule match:
    input:
        "subtask/",
    output:
        directory("match/"),
    params:
        ratio=5,
    script:
        "02-match.R"


rule fit:
    input:
        cohort_dir="subtask/",
        match_dir="match/",
    output:
        directory("fit/"),
    script:
        "03-fit.R"


rule plot:
    input:
        "fit/",
    output:
        directory("plot/"),
    script:
        "99-inspect.R"
