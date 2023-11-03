#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
})

(\ (gff, entrez, output){
    rtracklayer::import(gff, "GFF") |>
        GenomicRanges::mcols() |>
        as_tibble() |>
        filter(type == "transcript") |>
        select(transcript_id = ID,
            ensembl = gene_id,
            symbol = gene_name,
            type = gene_type
        ) |>
        left_join(
            read_tsv(entrez,
                col_names = c("transcript_id", "entrez"),
                col_types = "cc"
            )
        ) |>
        select(ensembl, symbol, entrez, type) |>
        distinct() |>
        mutate(
            ensembl = str_remove(ensembl, "\\.\\d+$"),
            entrez = as.character(entrez)
        ) |>
        saveRDS(output)
})(
    snakemake@input[["gff"]],
    snakemake@input[["entrez"]],
    snakemake@output[[1]]
)