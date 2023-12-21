#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
})

(\ (output, ont = "MF") {
    ont <- match.arg(ont, c("BP", "MF"))
    res <- clusterProfiler:::get_GO_data("org.Hs.eg.db", ont, "ENTREZID")
    enframe(res$PATHID2NAME, name = "ID", value = "description") |>
        left_join(
            enframe(res$PATHID2EXTID, name = "ID", value = "entrez") |>
                unnest(entrez)
        ) |>
        write_tsv(output)
})(
    snakemake@output[[1]],
    ont = snakemake@params[["ont"]]
)