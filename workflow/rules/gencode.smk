rule download_gencode:
    output:
        gff="resources/gencode.gff.gz",
        entrez="resources/gencode.metadata.entrez",
    params:
        version=config.get("gencode_version", "36"),
    shell:
        """
        wget -qO {output.gff} https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_{params.version}/gencode.v{params.version}.primary_assembly.annotation.gff3.gz
        wget -qO {output.entrez} https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_{params.version}/gencode.v{params.version}.metadata.EntrezGene.gz
        """


rule compile_genecode:
    input:
        gff=rules.download_gencode.output.gff,
        entrez=rules.download_gencode.output.entrez,
    output:
        "resources/gencode.rda",
    script:
        "../scripts/gencode.R"
