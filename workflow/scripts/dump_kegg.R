#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
})

(\ (output) {
    res <- clusterProfiler:::prepare_KEGG("hsa", keyType = "ncbi-geneid")
    enframe(res$PATHID2NAME, name = "ID", value = "description") |>
        left_join(
            enframe(res$PATHID2EXTID, name = "ID", value = "entrez") |>
                unnest(entrez)
        ) |>
        write_tsv(output)
})(
    snakemake@output[[1]]
)