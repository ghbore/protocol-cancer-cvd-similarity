rule download_hallmark:
    output:
        "resources/h.all.entrez.gmt",
    params:
        version=config["msigdb_version"] or "7.2",
    shell:
        """
        wget -qO {output} https://data.broadinstitute.org/gsea-msigdb/msigdb/release/{params.version}/h.all.v{params.version}.entrez.gmt
        """


rule compile_hallmark:
    input:
        rules.download_hallmark.output,
    output:
        "resources/hallmark.rds",
    script:
        "../scripts/compile-hallmark.R"


rule run_GSEA:
    input:
        gene="results/gene/{dataset}.rds",
        pathway="resources/hallmark.rds",
    output:
        "results/pathway/{dataset}.rds",
    params:
        pval=config.get("{wildcards.dataset}", config).get("pvalue_range", [0, 1]),
        beta=config.get("{wildcards.dataset}", config).get(
            "beta_range", ["-Inf", "Inf"]
        ),
    message:
        "To replicate the exact figures in the papers, use the provided intermediate results"
    script:
        "../scripts/gsea.R"
