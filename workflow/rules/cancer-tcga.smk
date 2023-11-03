rule download_gene_expression:
    output:
        "resources/tcga/fpkm-uq.tsv.gz",
    shell:
        """
        wget -O {output} https://gdc-hub.s3.us-east-1.amazonaws.com/download/GDC-PANCAN.htseq_fpkm-uq.tsv.gz
        """


rule download_basic_pheno:
    output:
        "resources/tcga/basic_pheno.tsv.gz",
    shell:
        """
        wget -qO {output} https://gdc-hub.s3.us-east-1.amazonaws.com/download/GDC-PANCAN.basic_phenotype.tsv.gz
        """


rule download_clinical_info:
    output:
        "resources/tcga/all_indexed_clinical.rds",
    script:
        "../scripts/tcga-clinical.R"


rule compile_pheno:
    input:
        basic=rules.download_basic_pheno.output,
        clinical=rules.download_clinical_info.output,
    output:
        "resources/tcga/pheno.rds",
    script:
        "../scripts/compile-tcga-pheno.R"


rule run_survival_tcga:
    input:
        expr=rules.download_gene_expression.output,
        pheno=rules.compile_pheno.output,
        anno=rules.compile_genecode.output,
    output:
        "results/gene/tcga.rds",
    threads: 8
    script:
        "../scripts/tcga-survival.R"
