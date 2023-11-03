#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
    library(SummarizedExperiment)
})

(\ (input, output){
    untar(input, files = paste("octad.db/data/", c(
            "lincs_signatures.rda", 
            "lincs_sig_info.rda", 
            "fda_drugs.rda"
        ), sep = "/"))
    load("octad.db/data/lincs_signatures.rda")
    load("octad.db/data/lincs_sig_info.rda")
    load("octad.db/data/fda_drugs.rda")
    Sys.glob("octad.db/data/*.rda") |> lapply(load)
    SummarizedExperiment(
        SimpleList(
            signature = lincs_signatures,
            decreasing_rank = Rfast::colRanks(lincs_signatures,
                descending = TRUE)
        ),
        colData = mutate(
                lincs_sig_info,
                across(where(function (.x) nlevels(.x) > 4), as.character)
            ) |>
            filter(id %in% colnames(lincs_signatures)) |>
            left_join(fda_drugs) |>
            distinct() |>
            left_join(
                tibble(id = colnames(lincs_signatures)),
                y = _
            ) |>
            column_to_rownames("id")
    ) |>
    saveRDS(output)
})(
    snakemake@input[[1]],
    snakemake@output[[1]]
)