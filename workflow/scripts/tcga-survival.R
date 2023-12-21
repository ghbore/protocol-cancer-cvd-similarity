#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
    library(survival)
})

get_survival_stat <- function (df, ...){
    if (1 >= nrow(df) || 1 >= length(unique(df$gene))){
        return(tibble(logHR = NA_real_, pval = NA_real_))
    }
    if (1 == length(unique(df$gender))){
        m <- tryCatch(
            coxph(Surv(time, event) ~ gene + age_at_index, data = df),
            error = function (e){
                message(e)
                message(format_tsv(df))
                return(tibble(logHR = NA_real_, pval = NA_real_))
            }
        )
    } else {
        m <- tryCatch(
            coxph(Surv(time, event) ~ gene + gender + age_at_index, data = df),
            error = function (e){
                message(e)
                message(format_tsv(df))
                return(tibble(logHR = NA_real_, pval = NA_real_))
            }
        )
    }
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

(\ (expr, pheno, anno, output, target = "BRCA", threads = 8){
    pheno <- readRDS(pheno)
    expr <- data.table::fread(expr)
    colnames(expr)[1] <- "ensembl"
    expr <- select(expr, ensembl, any_of(pheno$sample)) |>
        mutate(ensembl = str_remove(ensembl, "\\.\\d+$"))
    pheno <- filter(pheno, sample %in% colnames(expr))

    stats <- parallel::mclapply(seq(nrow(expr)), function (i){
            expr[i, ] |>
                select(!ensembl) |>
                pivot_longer(everything(), names_to = "sample", values_to = "gene") |>
                left_join(pheno, by = "sample") |>
                filter(disease == target) |>
                group_by(disease) |>
                group_modify(get_survival_stat) |>
                ungroup() |>
                mutate(ensembl = expr$ensembl[i], .before = 0)
        }, mc.cores = threads) |>
        bind_rows()
    
    df <- inner_join(stats, readRDS(anno))
    select(df, ensembl, entrez, symbol, beta = logHR, pval) |>
        saveRDS(output)
})(
    snakemake@input[["expr"]],
    snakemake@input[["pheno"]],
    snakemake@input[["anno"]],
    snakemake@output[[1]],
    target = snakemake@wildcards[["tcga"]],
    threads = snakemake@threads
)