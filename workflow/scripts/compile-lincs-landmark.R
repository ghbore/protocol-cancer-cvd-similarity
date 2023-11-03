#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
})

(\ (input, anno, output){
    read_tsv(input) |>
        transmute(old_symbol = pr_gene_symbol, entrez = as.character(ID)) |>
        left_join(readRDS(anno)) |>
        select(!type) |>
        saveRDS(output)
})(
    snakemake@input[[1]],
    snakemake@input[["anno"]],
    snakemake@output[[1]]
)