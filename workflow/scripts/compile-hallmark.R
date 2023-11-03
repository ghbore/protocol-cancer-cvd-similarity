#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
})

(\ (input, output){
    clusterProfiler::read.gmt(input) |>
        mutate(term = str_remove(term, "^HALLMARK_")) |>
        saveRDS(output)
})(
    snakemake@input[[1]],
    snakemake@output[[1]]
)