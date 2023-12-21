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

(\ (file, output) {
    df <- read_any(file)
    if (! all(c("ID", "NES") %in% colnames(df))){
        stop(str_glue("Column `ID` and `NES` are required in file {file}\n"))
    }
    df <- mutate(
            df,
            ID = as.character(ID),
            NES = as.numeric(NES),
            .keep = "none"
        )
    saveRDS(df, file = output)
})(
    snakemake@input[[1]],
    snakemake@output[[1]]
)