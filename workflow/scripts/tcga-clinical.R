#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
    library(TCGAbiolinks)
})

(\ (output){
    TCGAbiolinks:::getGDCprojects()$project_id |>
        str_subset("^TCGA") |>
        sort() |>
        plyr::alply(
            1, 
            function (proj){
                tryCatch(
                    GDCquery_clinic(proj),
                    error = function (e){
                        message(e)
                        return(NULL)
                    }
                )
            },
            .progress = "text"
        ) |>
        data.table::rbindlist(fill = TRUE) |>
        saveRDS(output)
})(
    snakemake@output[[1]]
)