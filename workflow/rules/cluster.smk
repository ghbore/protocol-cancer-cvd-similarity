from pathlib import Path


def gather_clustering_input_files(wildcards):
    exts = ("rds", "tsv", "xlsx", "xls")
    res = list()
    for name in config["dataset_clustering"][wildcards.name]["datasets"]:
        candidates = ["results/pathway/" + name + "." + ext for ext in exts]
        candidates = [f for f in candidates if Path(f).is_file()]
        if len(candidates) == 0:
            raise Exception("no input file for dataset " + name)
        res.append(candidates[0])
    return res


rule clustering:
    input:
        gather_clustering_input_files,
    output:
        "reports/{name}-clustering.html",
    params:
        resolution=lambda wildcards: config["dataset_clustering"][wildcards.name][
            "resolution"
        ],
    script:
        "../notebooks/clustering.Rmd"


def gather_grouping_input_files(wildcards):
    exts = ("rds", "tsv", "xlsx", "xls")
    res = list()
    groups = config["dataset_grouping"][wildcards.name]
    datasets = [ds for lst in groups.values() for ds in lst]
    for name in datasets:
        candidates = ["results/pathway/" + name + "." + ext for ext in exts]
        candidates = [f for f in candidates if Path(f).is_file()]
        if len(candidates) == 0:
            raise Exception("no input file for dataset " + name)
        res.append(candidates[0])
    return res


rule shared_risks:
    input:
        gather_grouping_input_files,
    output:
        "reports/{name}-shared_risks.html",
    params:
        groups=lambda wildcards: config["dataset_grouping"][wildcards.name],
    script:
        "../notebooks/shared_risks.Rmd"
