#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
    library(SummarizedExperiment)
})

(\ (input, anno, output, beta_col = "beta", pval_col = "pval"){
    df <- readxl::read_xlsx(input)
    colnames(df)[1] <- "ensembl"
    df <- select(df, ensembl, beta = !!beta_col, pval = !!pval_col) |>
        left_join(readRDS(anno)) |>
        select(ensembl, beta, pval, symbol, entrez)
    SummarizedExperiment(
        list(
            select(df, beta, pval) |>
                mutate(across(everything(), as.numeric))
        ),
        rowData = select(df, ensembl, symbol, entrez)
    ) |>
        saveRDS(output)
})(
    snakemake@input[["source"]],
    snakemake@input[["anno"]],
    snakemake@output[[1]],
    snakemake@params[["beta"]],
    snakemake@params[["pval"]]
)