#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(SummarizedExperiment)
    library(tidyverse)
})


#' OCTAD version to calculate Kolmogorov–Smirnov statistic.
#' Failed to count the ties.
#'
#' @export
#' @param tag The subset of names
#' @param signature_rank The rank of signature with names
#' @return Kolmogorov–Smirnov statistic
#' @example
#' set.seed(1)
#' R <- setNames(sample(1:26, 26), LETTERS)
#' O <- sample(LETTERS, 10)
#' ks_octad(O, R)
ks_octad <- function(tag, signature_rank) {
    num_signatures <- length(signature_rank)
    tag_position <- sort(signature_rank[tag])
    num_tags <- length(tag_position)
    if (num_tags <= 1){ return(0) }
    a <- max(sapply(seq_len(num_tags), function(j){
        j / num_tags - tag_position[j] / num_signatures
    }))
    b <- max(sapply(seq_len(num_tags), function(j){
        tag_position[j] / num_signatures - (j - 1) / num_tags
    }))
    ifelse(a > b, a, -b)
}

#' stats::ks.test version to calculate Kolmogorov–Smirnov statistic.
#' Modify to keep the sign.
#'
#' @export
#' @param x The values for sample
#' @param y The values for reference
#' @return Kolmogorov–Smirnov statistic
#' @example
#' set.seed(1)
#' R <- setNames(sample(1:26, 26), LETTERS)
#' O <- sample(LETTERS, 10)
#' ks(O, R)
ks <- function (x, y){
    if (length(x) < 1) return(0) # not same with `ks_octad`
    if (all(x %in% names(y))){
        # make arguments comparable with ks_octad
        x <- y[x]
    }
    x <- x[!is.na(x)]
    y <- y[!is.na(y)]
    n_x <- as.double(length(x))
    n_y <- as.double(length(y))
    w <- c(x, y)
    z <- cumsum(ifelse(order(w) <= n_x, 1 / n_x, - 1 / n_y))
    z <- z[c(which(diff(sort(w)) != 0), n_x + n_y)]
    z[which.max(abs(z))]
}

#' calculate the Reversal Gene Expression Score (RGES).
#'
#' @export
#' @param up The up subset of names
#' @param down The down subset of names
#' @param signature_rank The rank of signature with names
#' @return RGES
#' @example
#' set.seed(1)
#' R <- setNames(sample(1:26, 26), LETTERS)
#' O <- sample(LETTERS[1:10], 10)
#' ks(R[O], R)
rges <- function (up, down, signature_rank,
        method = c("ks", "ks_octad")){
    method <- match.fun(match.arg(method))
    method(up, signature_rank) -
        method(down, signature_rank)
}


(\ (deg, db, counts, score){
    df <- readRDS(deg)
    lincs <- readRDS(db)

    group_by(df, dataset) |>
        summarize(
            n_up = sum(beta > 0),
            n_down = sum(beta < 0)
        ) |>
        ungroup() |>
        write_tsv(counts)
    
    group_by(df, dataset) |>
        group_modify(function (.x, .y){
            up <- filter(.x, beta > 0)$symbol
            dw <- filter(.x, beta < 0)$symbol
            tibble(
                sid = colnames(lincs),
                score = vapply(seq_len(ncol(lincs)), function (i){
                        rges(up, dw, assay(lincs, 2)[, i])
                    }, vector("numeric", 1))
            )
        }) |>
        ungroup() |>
        saveRDS(score)
})(
    snakemake@input[["deg"]],
    snakemake@input[["db"]],
    snakemake@output[["counts"]],
    snakemake@output[["score"]]
)