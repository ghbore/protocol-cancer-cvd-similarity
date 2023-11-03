rule Download:
    input:
        "resources/gencode.gff.gz",
        "resources/gencode.metadata.entrez",
        "resources/h.all.entrez.gmt",
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
        "resources/hallmark.rds",
        "resources/bike/anno.rds",
        "resources/bike/data.rds",
        "resources/lincs/landmark.rds",
        "resources/lincs/lincs.rds",
        "resources/tcga/pheno.rds",


rule Gene:
    input:
        "results/gene/AOR_duke.rds",
        "results/gene/AOR_syntax.rds",
        "results/gene/AOR_vs_MAM.rds",
        "results/gene/bike_plaque.rds",
        "results/gene/tcga.rds",


rule Pathway:
    input:
        "results/pathway/AOR_duke.rds",
        "results/pathway/AOR_syntax.rds",
        "results/pathway/AOR_vs_MAM.rds",
        "results/pathway/bike_plaque.rds",
        "results/pathway/tcga.rds",


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


rule Compound:
    input:
        "results/compound/rges.rds",


rule EHR_validation:
    input:
        "EHR-OMOP/fit/",
        "EHR-OMOP/plot/",
