#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(SummarizedExperiment)
    library(tidyverse)
})

(\ (inputs, landmark, output){
    landmark <- readRDS(landmark) |>
        select(ensembl, symbol = old_symbol)
    lapply(inputs, function (f){
        readRDS(f) |>
            mutate(
                dataset = str_remove(basename(f), "\\.[^.]+$"),
                ensembl,
                beta,
                pval,
                .keep = "none"
            ) |>
            filter(abs(beta) <= 10, abs(beta) >= 0.1, pval <= 0.05) |>
            inner_join(landmark)
    }) |>
        bind_rows() |>
        arrange(dataset) |>
        saveRDS(output)
})(
    snakemake@input[["genes"]],
    snakemake@input[["landmark"]],
    snakemake@output[[1]]
)