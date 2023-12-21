#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
})

read_any <- function(f) {
    funcs <- list(
        "rds" = readRDS,
        "tsv" = read_tsv,
        "csv" = read_csv,
        "xls" = readxl::read_excel,
        "xlsx" = readxl::read_excel
    )
    ext <- tools::file_ext(f)
    if (! ext %in% names(funcs)){
        stop(str_glue("Unrecognized file format: {f}\n"))
    }
    funcs[[ext]](f)
}

(\ (file, anno, output) {
    df <- read_any(file)
    if (! all(c("beta", "pval") %in% colnames(df))){
        stop(str_glue("Column `beta` and `pval` are required in file {file}\n"))
    }
    if (! any(c("ensembl", "entrez", "symbol") %in% colnames(df))){
        stop(str_glue("Column `ensembl` or `entrez` or `symbol` are required in file {file}\n"))
    }
    df <- mutate(
            df,
            across(c(beta, pval), as.numeric),
            across(any_of(c("ensembl", "entrez", "symbol")), as.character),
            .keep = "none"
        )
    if ("ensembl" %in% colnames(df)){
        df[["ensembl"]] <- str_remove(df[["ensembl"]], "\\.[0-9]+$")
    }
    if ("entrez" %in% colnames(df)){
        df[["entrez"]] <- as.character(df[["entrez"]])
    }
    if (! all(c("ensembl", "entrez", "symbol") %in% colnames(df))){
        anno <- readRDS(anno) |> dplyr::select(ensembl, entrez, symbol)
        df <- left_join(df, anno)
    }
    saveRDS(df, file = output)
})(
    snakemake@input[["custom"]],
    snakemake@input[["anno"]],
    snakemake@output[[1]]
)