rule Download:
    input:
        "resources/gencode.gff.gz",
        "resources/gencode.metadata.entrez",
        "resources/gsea/" + config.get("enrichment_analysis_database", "MSigDB").lower(),
        ancient("resources/bike/HG-U133_Plus_2-na36-annot-csv.zip"),
        "resources/bike/series.gz",
        "resources/lincs/GPL20573.tsv.gz",
        "resources/lincs/octad.db_0.99.0.tar.gz",
        ancient("resources/starnet/AOR_vs_MAM_DGElist.xlsm"),
        ancient("resources/starnet/AORsyntax_duke_Cor_P.xlsm"),
        "resources/tcga/all_indexed_clinical.rds",
        "resources/tcga/basic_pheno.tsv.gz",
        "resources/tcga/fpkm-uq.tsv.gz",


rule Compile:
    input:
        "resources/gencode.rds",
        "resources/bike/anno.rds",
        "resources/bike/data.rds",
        "resources/lincs/landmark.rds",
        "resources/lincs/lincs.rds",
        "resources/tcga/pheno.rds",


def list_all_gene_input(wildcards):
    datasets = set()
    for name, cfg in config["dataset_clustering"].items():
        datasets.update(cfg["datasets"])
    for name, cfg in config["dataset_grouping"].items():
        for k, v in cfg.items():
            datasets.update(v)
    negative = [name for name, cfg in config["datasets"].items() if "pathway" in cfg]
    return ["results/gene/" + name + ".rds" for name in datasets.difference(negative)]


rule Gene:
    input:
        list_all_gene_input,


def list_all_pathway_input(wildcards):
    datasets = set()
    for name, cfg in config["dataset_clustering"].items():
        datasets.update(cfg["datasets"])
    for name, cfg in config["dataset_grouping"].items():
        for k, v in cfg.items():
            datasets.update(v)
    return ["results/pathway/" + name + ".rds" for name in datasets]


rule Pathway:
    input:
        list_all_pathway_input,


rule Cluster:
    input:
        expand(
            "reports/{name}-clustering.html", name=config["dataset_clustering"].keys()
        ),


rule Common:
    input:
        expand(
            "reports/{name}-shared_risks.html", name=config["dataset_grouping"].keys()
        ),


rule Report:
    input:
        expand(
            "reports/{name}-clustering.html", name=config["dataset_clustering"].keys()
        ),
        expand(
            "reports/{name}-shared_risks.html", name=config["dataset_grouping"].keys()
        ),


rule Compound:
    input:
        "results/compound/rges.rds",


rule EHR_validation:
    input:
        "EHR-OMOP/fit/",
        "EHR-OMOP/plot/",
