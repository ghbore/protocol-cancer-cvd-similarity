rule compile_starnet_aor_vs_mam:
    input:
        source="resources/starnet/AOR_vs_MAM_DGElist.xlsm",
        anno="resources/gencode.rds",
    output:
        "results/gene/AOR_vs_MAM.rds",
    params:
        beta="logFC",
        pval="P.Value",
    script:
        "../scripts/compile-starnet.R"


rule compile_starnet_aor_syntax:
    input:
        source="resources/starnet/AORsyntax_duke_Cor_P.xlsm",
        anno="resources/gencode.rds",
    output:
        "results/gene/AOR_syntax.rds",
    params:
        beta="syntax_cor",
        pval="syntax_p",
    script:
        "../scripts/compile-starnet.R"


rule compile_starnet_aor_duke:
    input:
        source="resources/starnet/AORsyntax_duke_Cor_P.xlsm",
        anno="resources/gencode.rds",
    output:
        "results/gene/AOR_duke.rds",
    params:
        beta="Duke_cor",
        pval="Duke_p",
    script:
        "../scripts/compile-starnet.R"
