#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
    library(lubridate)
    library(survival)
    library(rlang)
})

theme_set(theme_classic(base_size = 14))

## start at 2021/11/07
fmt_df <- function (df, year = 5){
    mutate(df,
        outcome = ifelse(outcome_time > 365 * year, 0L, outcome),
        outcome_time = ifelse(outcome_time > 365 * year, 365 * year, outcome_time)
    ) %>%
        tmerge(., ., id = person_id, event = event(outcome_time, outcome)) %>%
        tmerge(., ., id = person_id, treat = tdc(drug_time, drug)) %>%
        mutate(treat = treat %|% 0L)
}
gen_fit <- function (df){
    tryCatch(survfit(Surv(tstart, tstop, event) ~ treat,
            data = df, id = person_id, weights = weights),
        error = function (cond){ return(NULL) }
    )
}
gen_cox <- function (df){
    tryCatch(coxph(Surv(tstart, tstop, event) ~ treat + gender + age + race + smoker,
            data = df, id = person_id, weights = weights),
        error = function (cond){ return(NULL) }
    )
}
surv_plot <- function (fit, cox, data, title = NULL){
    pval <- format(coef(summary(cox))[1, 6], digits = 3, nsmall = 3)
    list(survminer::ggsurvplot(fit, data,
            censor = FALSE, fun = "event", conf.int = TRUE,
            xlab = "days",
            legend = "none",
            # palette = c("lightgray", "black"),
            surv.scale = "percent",
            pval = str_glue("p = {pval}"),
            pval.coord = c(0, max(fit$cumhaz)),
            title = title, newpage = FALSE
        )$plot,
        survminer::ggforest(cox, data)
    ) %>%
        patchwork::wrap_plots(widths = c(3, 4))
}

### clopidogrel
in_dir <- snakemake@input[[1]]
out_dir <- snakemake@output[[1]]
if (! dir.exists(out_dir)){
    dir.create(out_dir)
}
Sys.glob(str_glue("{in_dir}/*-*.rds")) %>% 
    lapply(function (f){
        bsname <- basename(f) %>% str_remove(".rds$")
        data <- readRDS(f) %>% 
            fmt_df()
        pdf(str_glue("{out_dir}/{bsname}.pdf"), width = 12, height = 6)
        surv_plot(
            fit = gen_fit(data),
            cox = gen_cox(data),
            data = data,
            title = bsname
        ) %>% 
            print()
        dev.off()
    })