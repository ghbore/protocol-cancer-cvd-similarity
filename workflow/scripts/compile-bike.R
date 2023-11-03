#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
    library(SummarizedExperiment)
})

# inverse-normal transformation
## FIXME
inv_norm_trans <- function (x){
    # ref. https://www.biostars.org/p/80597/
    qnorm( (rank(x,na.last="keep")-0.5) / sum(!is.na(x)) )
}

(\ (input, output){
    colData <- pipe(str_glue("gzip -dc {input} |sed -n '/^!Sample_title\t/p'")) |>
        scan(what = character()) |>
        {\(x) x[-1]}() |>
        str_split_fixed(' ', n=2) |>
        `colnames<-`(c('patient', 'source')) |>
        as_tibble() |>
        mutate(
            age = pipe(str_glue("gzip -dc {input} |sed -n '/^!Sample_characteristics_ch1\t\"age (y)/p'")) |>
                scan(what = character()) |>
                {\(x) x[-1]}() |>
                str_remove('^.+: ') |>
                as.integer(),
            event = pipe(str_glue("gzip -dc {input} |sed -n '/^!Sample_characteristics_ch1\t\"ischemic event/p'")) |>
                scan(what = character()) |>
                {\(x) x[-1]}() |>
                str_remove('^.+: ') |>
                as.logical(), 
            time = pipe(str_glue("gzip -dc {input} |sed -n '/^!Sample_characteristics_ch1\t\"ischemic time/p'")) |>
                scan(what = character()) |>
                unlist() |>
                {\(x) x[-1]}() |>
                str_remove('^.+: ') |>
                as.integer()
        )

    data <- pipe(str_glue("gzip -dc {input} |grep -v '^!'")) |>
        read_tsv() |>
        column_to_rownames('ID_REF') |>
        as.matrix() |>
        apply(1, inv_norm_trans) |>
        t()

    SummarizedExperiment(
        list(as_tibble(data)),
        colData = colData,
        rowData = tibble(probe = rownames(data))
    ) |>
        saveRDS(output)
})(
    snakemake@input[[1]],
    snakemake@output[[1]]
)