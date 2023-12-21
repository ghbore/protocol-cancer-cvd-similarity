#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
    library(survival)
    library(SummarizedExperiment)
})

get_survival_stat <- function (df, ...){
    if (1 >= nrow(df) ||
        1 >= length(unique(df$gene)) ||
        1 >= length(unique(df$event))){
        return(tibble(logHR = NA_real_, pval = NA_real_))
    }
    m <- tryCatch(
        coxph(Surv(time, event) ~ gene + age, data = df),
        error = function (e){
            message(e)
            message(format_tsv(df))
            return(tibble(logHR = NA_real_, pval = NA_real_))
        }
    )
    if (is(m, "data.frame")){
        return(m)
    }
    summary(m) %>%
        coef() %>%
        `[`(1, c(1, 5)) %>%
        setNames(c('logHR', 'pval')) %>%
        t() %>%
        as_tibble()
}

(\ (dat, anno, output, source = "plaque", threads = 8){
    target_source = match.arg(source, c("plaque", "pbmc"))
    se <- readRDS(dat)
    stats <- parallel::mclapply(seq(nrow(se)), function (i){
            colData(se) |>
                as_tibble() |>
                mutate(gene = assay(se)[i, ] |> unlist()) |>
                dplyr::filter(source == target_source) |>
                group_by(source) |>
                group_modify(get_survival_stat) |>
                ungroup() |>
                mutate(probe = rowData(se)[i, "probe"], .before = 0)
        }, mc.cores = threads) |>
        bind_rows()

    df <- left_join(stats, readRDS(anno)) |>
        dplyr::filter(!is.na(ensembl)) |>
        arrange(source, ensembl, pval) |>
        group_by(source, ensembl) |>
        slice_head() |>
        ungroup()
    
    dplyr::select(df, ensembl, entrez, symbol, beta = logHR, pval) |>
        saveRDS(output)
})(
    snakemake@input[["data"]],
    snakemake@input[["anno"]],
    snakemake@output[[1]],
    source = snakemake@params[["source"]],
    threads = snakemake@threads
)