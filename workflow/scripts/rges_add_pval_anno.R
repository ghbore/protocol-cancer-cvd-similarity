#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(SummarizedExperiment)
    library(tidyverse)
})

(\ (score, sim, db, cell2tcga, output){
    sim <- readRDS(sim)

    readRDS(score) |>
        filter(dataset %in% sim$dataset) |>
        group_by(dataset) |>
        group_modify(function (.x, .y){
            v <- sim$rges[[which(sim$dataset == .y$dataset[1])]]
            uv <- unique(v)
            ecdf <- approxfun(uv, cumsum(tabulate(match(v, uv))) / length(v))
            p <- ecdf(.x$score)
            p[is.na(p) & .x$score >= max(v)] <- 1
            ileft <- which(is.na(p) | p <= 0.01)
            p[is.na(p)] <- 0
            p_empirical <- p
            if (length(ileft) > 0){
                m <- sim$model[[which(sim$dataset == .y$dataset[1])]]
                pdf <- purrr::partial(mixsmsn:::d.mixedSN,
                    pi1 = m$pii,
                    mu = m$mu,
                    sigma2 = m$sigma2,
                    shape = m$shape
                )
                p[ileft] <- vapply(.x$score[ileft],
                    function (s) integrate(pdf, -2, s)$value,
                    vector("numeric", 1)
                )
            }
            mutate(.x, pval = p, pemp = p_empirical)
        }) |>
        ungroup() |>
        left_join(
            readRDS(db) |>
                colData() |>
                as.data.frame() |>
                rownames_to_column("sid") |>
                select(any_of(c(
                    "sid", "cell_id", 
                    "pert_iname", "pert_dose", "pert_time", 
                    "moa", "target", "clinical_phase"
                )))
        ) |>
        left_join(
            readxl::read_xlsx(cell2tcga, skip = 4) |>
                filter(exact == 1) |>
                select(cell_id, tcga)
        ) |>
        saveRDS(output)
})(
    snakemake@input[["score"]],
    snakemake@input[["sim"]],
    snakemake@input[["db"]],
    snakemake@input[["cell2tcga"]],
    snakemake@output[[1]]
)