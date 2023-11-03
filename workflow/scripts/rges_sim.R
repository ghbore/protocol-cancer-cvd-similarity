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

#' simulation
#'
#' @export
rges_sim1 <- function (n_up, n_down, n_total,
        n_permutation = 10000L, seed = 1,
        method = c("ks", "ks_octad")){
    method <- match.fun(match.arg(method))
    set.seed(seed)
    L <- seq_len(n_total)
    vapply(seq_len(n_permutation), function (i){
        g <- sample(L, n_up + n_down)
        method(head(g, n_up), L) -
            method(tail(g, n_down), L)
    }, vector("numeric", 1))
}


(\ (counts, output, n_total){
    read_tsv(counts) |>
        filter(!(n_up == 0 & n_down == 0)) |>
        rowwise() |>
        mutate(
            rges = list(rges_sim1(n_up, n_down, n_total) |> sort()),
            model = list(mixsmsn::smsn.mix(rges, nu=1, g=3))
        ) |>
        ungroup() |>
        saveRDS(output)
})(
    snakemake@input[[1]],
    snakemake@output[[1]],
    n_total = snakemake@params[["landmark_gene_count"]]
)