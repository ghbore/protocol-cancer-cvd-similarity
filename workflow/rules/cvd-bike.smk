rule download_bike_series:
    output:
        "resources/bike/series.gz",
    shell:
        """
        wget -qO {output} https://ftp.ncbi.nlm.nih.gov/geo/series/GSE21nnn/GSE21545/matrix/GSE21545_series_matrix.txt.gz
        """


rule download_bike_array_anno:
    output:
        "resources/bike/HG-U133_Plus_2-na36-annot-csv.zip",
    message:
        "please manually download HG-U133_Plus_2 Annotations from Thermofisher (https://sec-assets.thermofisher.com/TFS-Assets/LSG/Support-Files/HG-U133_Plus_2-na36-annot-csv.zip)"


rule compile_bike_array_anno:
    input:
        gencode="resources/gencode.rds",
        anno=ancient("resources/bike/HG-U133_Plus_2-na36-annot-csv.zip"),
    output:
        "resources/bike/anno.rds",
    script:
        "../scripts/compile-bike-array-anno.R"


rule compile_bike:
    input:
        rules.download_bike_series.output,
    output:
        "resources/bike/data.rds",
    script:
        "../scripts/compile-bike.R"


rule run_survival_bike:
    input:
        data=rules.compile_bike.output,
        anno=rules.compile_bike_array_anno.output,
    output:
        pbmc="results/gene/bike_pbmc.rds",
        plaque="results/gene/bike_plaque.rds",
    threads: 8
    script:
        "../scripts/bike-survival.R"
