from pathlib import Path


rule download_lincs_db:
    output:
        "resources/lincs/octad.db_0.99.0.tar.gz",
    shell:
        """
        wget -O {output} https://chenlab-data-public.s3.amazonaws.com/octad/octad.db_0.99.0.tar.gz
        """


rule dump_lincs_db:
    input:
        ancient("resources/lincs/octad.db_0.99.0.tar.gz"),
    output:
        "resources/lincs/lincs.rds",
    script:
        "../scripts/dump-lincs-db.R"


rule download_GPL20573:
    output:
        "resources/lincs/GPL20573.tsv.gz",
    shell:
        """
        wget -O- https://ftp.ncbi.nlm.nih.gov/geo/platforms/GPL20nnn/GPL20573/soft/GPL20573_family.soft.gz | \
            gzip -dc | \
            sed -n '/^!platform_table_begin/,/^!platform_table_end/p' | \
            sed '1d; $d' | \
            gzip -c \
            > {output}
        """


rule compile_landmark:
    input:
        rules.download_GPL20573.output,
        anno="resources/gencode.rds",
    output:
        "resources/lincs/landmark.rds",
    script:
        "../scripts/compile-lincs-landmark.R"


rule subset_landmark_deg:
    input:
        genes=[f for f in Path("results/gene/").glob("*.rds")],
        landmark="resources/lincs/landmark.rds",
    output:
        "results/compound/landmark_deg.rds",
    script:
        "../scripts/subset_landmark_deg.R"


rule calc_rges_score:
    input:
        deg="results/compound/landmark_deg.rds",
        db="resources/lincs/lincs.rds",
    output:
        counts="results/compound/up_down_count.tsv",
        score="results/compound/rges_score.rds",
    script:
        "../scripts/rges_score.R"


rule sim_rges_score:
    input:
        "results/compound/up_down_count.tsv",
    output:
        "results/compound/rges_sim.rds",
    params:
        landmark_gene_count=978,
    script:
        "../scripts/rges_sim.R"


rule add_rges_pval_anno:
    input:
        score="results/compound/rges_score.rds",
        sim="results/compound/rges_sim.rds",
        db="resources/lincs/lincs.rds",
        cell2tcga="resources/lincs/cell_line-tumor-map.xlsx",
    output:
        "results/compound/rges.rds",
    script:
        "../scripts/rges_add_pval_anno.R"
