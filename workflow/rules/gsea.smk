from pathlib import Path


rule prepare_msigdb:
    output:
        "resources/gsea/msigdb",
    params:
        version=config.get("msigdb_version", "7.2"),
    run:
        import requests

        url = (
            "https://data.broadinstitute.org/gsea-msigdb/msigdb/release/"
            + params.version
            + "/h.all.v"
            + params.version
            + ".entrez.gmt"
        )
        res = requests.get(url)
        lines = [ln for ln in res.text.split("\n") if ln != ""]
        outs = [None] * len(lines)
        for i, line in enumerate(lines):
            pathway, _, *genes = line.split("\t")
            pathway = pathway.removeprefix("HALLMARK_")
            outs[i] = "\n".join([pathway + "\t" + gene for gene in genes])
        outs.insert(0, "ID\tentrez")
        with open(output[0], "w") as O:
            print("\n".join(outs), file=O)


rule prepare_kegg:
    output:
        "resources/gsea/kegg",
    script:
        "../scripts/dump_kegg.R"


rule prepare_go_mf:
    output:
        "resources/gsea/go_mf",
    params:
        ont="MF",
    script:
        "../scripts/dump_go.R"


use rule prepare_go_mf as prepare_go_bp with:
    output:
        "resources/gsea/go_bp",
    params:
        ont="BP",


def choose_gene_input(wildcards):
    name = wildcards.dataset
    exts = ("rds", "tsv", "xlsx", "xls")
    candidates = ["results/gene/" + name + "." + ext for ext in exts]
    candidates = [f for f in candidates if Path(f).is_file()]
    if len(candidates) == 0:
        return "results/gene/" + name + ".rds"
    return candidates[0]


def choose_gsea_db(wildcards):
    db = config.get("enrichment_analysis_database", "MSigDB")
    if Path(db).is_file():
        return db
    return "resources/gsea/" + db.lower()


rule run_GSEA:
    input:
        gene=choose_gene_input,
        db=choose_gsea_db,
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
