#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
})

(\ (input, anno, output, beta_col = "beta", pval_col = "pval"){
    df <- readxl::read_xlsx(input)
    colnames(df)[1] <- "ensembl"
    select(df, ensembl, beta = !!beta_col, pval = !!pval_col) |>
        mutate(across(c(beta, pval), as.numeric)) |>
        left_join(readRDS(anno)) |>
        select(ensembl, entrez, symbol, beta, pval) |>
        saveRDS(output)
})(
    snakemake@input[["source"]],
    snakemake@input[["anno"]],
    snakemake@output[[1]],
    beta_col = snakemake@params[["beta"]],
    pval_col = snakemake@params[["pval"]]
)