rule standardize_gene_profile:
    input:
        custom=lambda wildcards: config["datasets"]
        .get(wildcards.dataset, dict())
        .get("gene", "_file_never_exists_"),
        anno="resources/gencode.rds",
    output:
        "results/gene/{dataset}.rds",
    script:
        "../scripts/standardize_gene_profile.R"


rule standardize_pathway_profile:
    input:
        lambda wildcards: config["datasets"]
        .get(wildcards.dataset, dict())
        .get("pathway", "_file_never_exists_"),
    output:
        "results/pathway/{dataset}.rds",
    script:
        "../scripts/standardize_pathway_profile.R"
