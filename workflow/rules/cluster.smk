from pathlib import Path


rule clustering:
    input:
        [f for f in Path("results/pathway/").glob("*.rds")],
    output:
        "reports/{name}-clustering.html",
    params:
        datasets=lambda wildcards: config["dataset_clustering"][wildcards.name][
            "datasets"
        ],
        resolution=lambda wildcards: config["dataset_clustering"][wildcards.name][
            "resolution"
        ],
    script:
        "../notebooks/clustering.Rmd"


rule shared_risks:
    input:
        [f for f in Path("results/pathway/").glob("*.rds")],
    output:
        "reports/{name}-shared_risks.html",
    params:
        groups=lambda wildcards: config["dataset_grouping"][wildcards.name],
    script:
        "../notebooks/shared_risks.Rmd"
