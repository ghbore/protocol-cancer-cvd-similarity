#! /bin/env bash

echo Must switch to the 'env.yaml' environment first >&2

R -e '
    options(repos = c(
        CRAN = "http://cran.r-project.org"
    ))

    install.packages(c(
        "renv",
        "yulab.utils",
        "BiocManager"
    ))

    renv::install(c(
        "ggplot2@3.3.6", "tidyverse",
        "data.table", "Rfast",
        "survival", "survminer",
        "ggsci", "gridExtra", "GGally",
        "spatstat@1.64-1", "Seurat@4.0.0",
        "extrafont",
        "pheatmap", "ggbeeswarm",
        "DT", "mixsmsn",
        "MatchIt"
    ), prompt = TRUE)

    BiocManager::install(c(
        "clusterProfiler",
        "rtracklayer",
        "GenomicRanges",
        "DOSE",
        "org.Hs.eg.db",
        "octad.db"
    ), 
        version = "3.14",
        update = FALSE,
        ask = FALSE
    )
'