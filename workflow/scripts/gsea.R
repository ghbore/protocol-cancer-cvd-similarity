#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
    library(SummarizedExperiment)
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

(\ (gene, db, output, pval_range, beta_range){
    gene_ids <- c("ensembl", "entrez", "symbol")
    db <- read_tsv(db) |>
        mutate(across(everything(), as.character))
    gene_col <- gene_ids[gene_ids %in% colnames(db)]
    if (length(gene_col) == 0){
        stop(str_glue(
            "At least one of `ensembl`, `entrez` and `symbol` ",
            "is required for enrichment DB {db}\n"
        ))
    }
    gene_col <- gene_col[1]
    term2gene <- bind_cols(
            select(db, any_of(c("ID", "description"))) |>
                select(1),
            select(db, all_of(gene_col))
        )
    term2name <- bind_cols(
            select(db, any_of(c("ID", "description"))) |>
                select(1),
            select(db, any_of(c("description", "ID"))) |>
                select(1)
        )
    df <- read_any(gene)

    core <- filter(df, !if_any(c(beta, pval), ~ is.na(.x))) |>
        filter(pval >= pval_range[1], pval <= pval_range[2]) |>
        filter(beta >= beta_range[1], beta <= beta_range[2])
    gls <- core[core[[gene_col]] %in% unique(db[[gene_col]]), ] |>
        arrange(across(all_of(gene_col)), pval) |>
        group_by(across(all_of(gene_col))) |>
        slice_head() |>
        ungroup() |>
        arrange(desc(beta)) |>
        pull(beta, all_of(gene_col))
    res <- tryCatch({
        set.seed(1)
        clusterProfiler::GSEA(
                gls, 
                pvalueCutoff = 1, 
                TERM2GENE = term2gene, 
                TERM2NAME = term2name,
                eps = 0, 
                seed = TRUE
            ) |>
            slot("result") |>
            as_tibble()
        },
        error = function (e){
            message(e)
            return(NULL)
        }
    )
    saveRDS(res, output)
})(
    snakemake@input[["gene"]],
    snakemake@input[["db"]],
    snakemake@output[[1]],
    pval_range = snakemake@params[["pval"]] |> as.numeric(),
    beta_range = snakemake@params[["beta"]] |> as.numeric()
)