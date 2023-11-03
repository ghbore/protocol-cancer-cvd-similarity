#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(SummarizedExperiment)
    library(tidyverse)
})

(\ (inputs, landmark, output){
    landmark <- readRDS(landmark) |>
        select(ensembl, symbol = old_symbol)
    lapply(inputs, function (f){
        se <- readRDS(f)
        setNames(
            se@assays@data,
            names(se@assays@data) %||% 
                str_remove(basename(f), "\\.[^.]+$")
        ) |>
            lapply(function (d){
                bind_cols(
                    se@elementMetadata |> 
                        as_tibble() |>
                        select(ensembl),
                    d
                )
            }) |>
            bind_rows(.id = "dataset") |>
            dplyr::rename(any_of(c(
                beta = "logHR"
            ))) |>
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