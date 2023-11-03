#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
    library(SummarizedExperiment)
})

(\ (gene, pathway, output, pval_range, beta_range){
    pathway <- readRDS(pathway)
    se <- readRDS(gene)
    colnames(se) <- ifelse(colnames(se) == "pval", "pval", "beta")
    res <- lapply(assays(se), function (a){
        gls <- bind_cols(rowData(se) |> as_tibble(), a) |>
            filter(!if_any(c(beta, pval), ~ is.na(.x))) |>
            filter(entrez %in% unique(pathway$gene)) |>
            filter(pval >= pval_range[1], pval <= pval_range[2]) |>
            filter(beta >= beta_range[1], beta <= beta_range[2]) |>
            arrange(entrez, pval) |>
            group_by(entrez) |>
            slice_head() |>
            ungroup() |>
            arrange(desc(beta)) |>
            pull(beta, entrez)
        tryCatch({
            set.seed(1)
            clusterProfiler::GSEA(gls, pvalueCutoff = 1, TERM2GENE = pathway, eps = 0, seed = TRUE) |>
                DOSE::setReadable("org.Hs.eg.db", "ENTREZID") |>
                slot("result") |>
                as_tibble()
            },
            error = function (e){
                message(e)
                return(NULL)
            }
        )
    })
    
    if (length(res) == 1){
        saveRDS(res[[1]], output)
    }else {
        saveRDS(bind_rows(res, .id = "dataset"), output)
    }
})(
    snakemake@input[["gene"]],
    snakemake@input[["pathway"]],
    snakemake@output[[1]],
    pval_range = snakemake@params[["pval"]] |> as.numeric(),
    beta_range = snakemake@params[["beta"]] |> as.numeric()
)