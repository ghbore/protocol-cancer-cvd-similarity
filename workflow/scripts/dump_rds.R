#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
})

(\ (input, output, format = "tsv") {
    format <- match.arg(format, c("tsv", "txt", "csv", "xls", "xlsx"))
    funcs <- list(
        tsv = write_tsv,
        txt = write_tsv,
        csv = write_csv,
        xls = purrr::partial(openxlsx::write.xlsx, rowNames = FALSE),
        xlsx = purrr::partial(openxlsx::write.xlsx, rowNames = FALSE)
    )
    df <- readRDS(input)
    if (! is(df, "data.frame")){
        stop(str_glue("{input} does not contain a table\n"))
    }
    funcs[[format]](df, output)
})(
    snakemake@input[[1]],
    snakemake@output[[1]],
    format = tolower(snakemake@wildcards[["ext"]])
)