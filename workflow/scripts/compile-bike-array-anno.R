#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
})

(\ (gencode, anno, output){
    gencode <- readRDS(gencode)
    anno <- pipe(str_glue("unzip -p {anno} \\*.csv |grep -v '^#'")) |>
        read_csv() |>
        transmute(
            probe = `Probe Set ID`, 
            ensembl = Ensembl,
            symbol = `Gene Symbol`,
            entrez = `Entrez Gene`
        ) |>
        separate_longer_delim(ensembl, " /// ") |>
        separate_longer_delim(symbol, " /// ") |>
        separate_longer_delim(entrez, " /// ") |>
        mutate(across(c(ensembl, symbol, entrez), 
            ~ ifelse(.x == "---", NA_character_, .x)
        )) |>
        distinct()
    bind_rows(
        select(anno, probe, ensembl) |>
            filter(!is.na(ensembl)) |>
            inner_join(gencode),
        select(anno, probe, symbol) |>
            filter(!is.na(symbol)) |>
            inner_join(gencode),
        select(anno, probe, entrez) |>
            filter(!is.na(entrez)) |>
            inner_join(gencode)
    ) |>
        filter(!is.na(ensembl)) |>
        distinct() |>
        saveRDS(output)
})(
    snakemake@input[["gencode"]],
    snakemake@input[["anno"]],
    snakemake@output[[1]]
)