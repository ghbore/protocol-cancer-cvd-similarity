#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
    library(lubridate)
    library(survival)
    library(rlang)
})

cohort_dir <- snakemake@input[["cohort_dir"]]
match_dir <- snakemake@input[["match_dir"]]
out_dir <- snakemake@output[[1]]

gen_coxph <- function (df){
    m <- tryCatch(
        coxph(Surv(tstart, tstop, event) ~ treat + gender + age + race + smoker,
            data = tmerge(df, df, id = person_id, event = event(outcome_time, outcome)) %>%
                tmerge(., ., id = person_id, treat = tdc(drug_time, drug)) %>%
                mutate(treat = treat %|% 0L),
            id = person_id, weights = weights
        ),
        error = function (cond){ return(NULL) }
    )
    return(m)
}
get_coef <- function (m){
    if (is.null(m)){ return(tibble(cov = "treat", 
        coef = NA_real_, 
        `exp(coef)` = NA_real_, 
        `se(coef)` = NA_real_, 
        z = NA_real_, 
        `Pr(>|z|)` = NA_real_
    )) }
    summary(m) %>%
        coef() %>%
        as.data.frame() %>%
        rownames_to_column("cov") %>%
        filter(str_starts(cov, "treat"))
}

# load
outcomes <- Sys.glob(str_glue("{cohort_dir}/*-event.rds")) %>%
    setNames(., str_remove(., "^.*/") %>% str_remove("-event.rds$")) %>% 
    lapply(function (f){
        readRDS(f) %>% 
            rename(
                concept_id_outcome = concept_id,
                start_date_outcome = start_date,
                end_date_outcome = end_date
            )
    }) %>%
    `[`(sapply(., nrow) >= 50) # only consider diseases with at least 50 event to increase power

# for each matched cohort,
#   1. iter each outcome
#     1a. fit survival models
if (! dir.exists(out_dir)){
    dir.create(out_dir)
}
Sys.glob(str_glue("{match_dir}/*-matched_df.rds")) %>%
    lapply(function (f){
        df <- readRDS(f)
        drug_name <- str_remove(f, "^.*/") %>% 
            str_remove("-matched_df.rds$")

        stats <- lapply(names(outcomes) %>% setNames(., .), function (oname){
            df <- left_join(df, outcomes[[oname]], by = "person_id") %>%
                mutate(
                    start_date_outcome = case_when(
                        start_date_outcome <= enroll_date ~ lubridate::date(NA),
                        TRUE ~ start_date_outcome
                    ),
                    end_date_outcome = case_when(
                        is.na(start_date_outcome) ~ lubridate::date(NA),
                        TRUE ~ end_date_outcome
                    )
                ) %>%
                arrange(person_id, start_date_outcome) %>%
                distinct(person_id, .keep_all = TRUE) %>%
                mutate(
                    outcome = ifelse(is.na(start_date_outcome), 0L, 1L),
                    outcome_time = interval(
                        enroll_date,
                        start_date_outcome %|% last_follow_up
                    ) / days(1),
                    drug = ifelse(is.na(start_date_drug), 0L, 1L),
                    drug_time = interval(enroll_date, start_date_drug) / days(1)
                ) %>%
                select(person_id, gender, race, age, smoker, indication, weights, drug, drug_time, outcome, outcome_time)
            saveRDS(df, str_glue("{out_dir}/{drug_name}-{oname}.rds"))

            lapply(1:5, function (i){
                df <- mutate(df,
                    outcome = ifelse(outcome_time > 365 * i, 0L, outcome),
                    outcome_time = ifelse(outcome_time > 365 * i, 365 * i, outcome_time)
                )
                top_indication <- distinct(df, person_id, indication) %>%
                    group_by(indication) %>%
                    summarize(n = n()) %>%
                    slice_max(n, n = 1) %>%
                    pull(indication)

                bind_rows(
                    gen_coxph(df) %>%
                        get_coef() %>%
                        mutate(indication = 0L, year = i, .before = 1),
                    gen_coxph(filter(df, indication == top_indication)) %>%
                        get_coef() %>%
                        mutate(indication = as.character(top_indication) %>% as.integer(),
                            year = i, .before = 1
                        )
                )
            }) %>%
                bind_rows()
        }) %>%
            bind_rows(.id = "outcome")
        saveRDS(stats, str_glue("{out_dir}/{drug_name}.rds"))
        write_csv(stats, str_glue("{out_dir}/{drug_name}.csv"))
    })
