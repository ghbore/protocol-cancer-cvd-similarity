rule dump_rds:
    input:
        "results/{folder}/{prefix}.rds",
    output:
        "results/{folder,gene|pathway}/{prefix}.{ext,tsv|txt|csv|xls|xlsx}",
    script:
        "../scripts/dump_rds.R"


rule Dump:
    input:
        expand(
            "results/gene/{name}.{ext}",
            name=list(
                set(
                    ds
                    for v in config["dataset_clustering"].values()
                    for ds in v["datasets"]
                )
            ),
            ext=["xlsx"],
        ),
        expand(
            "results/pathway/{name}.{ext}",
            name=list(
                set(
                    ds
                    for v in config["dataset_grouping"].values()
                    for vv in v.values()
                    for ds in vv
                )
            ),
            ext=["xlsx"],
        ),
