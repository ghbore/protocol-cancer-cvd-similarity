#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
    library(lubridate)
    library(MatchIt)
    library(survival)
    library(rlang)
})

cohort_dir <- snakemake@input[[1]]
out_dir <- snakemake@output[[1]]
ratio <- snakemake@params[["ratio"]]

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
person <- readRDS(str_glue("{cohort_dir}/person.rds"))

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

# for each cohort, design matched cohorts
if (! dir.exists(out_dir)){
    dir.create(out_dir)
}
Sys.glob(str_glue("{cohort_dir}/*-cohort.rds")) %>%
    str_remove(., "^.*/") %>%
    str_remove("-cohort.rds$") %>%
    setNames(., .) %>%
    lapply(function (name){
        cohort <- readRDS(str_glue("{cohort_dir}/{name}-cohort.rds"))

        case_cohort <- arrange(cohort$drug_event, person_id, start_date) %>%
            distinct(person_id, .keep_all = TRUE) %>%
            left_join(
                cohort$indication_event,
                by = "person_id",
                suffix = c("_drug", "_ind")
            ) %>%
            filter(start_date_ind <= start_date_drug) %>%
            arrange(person_id, desc(start_date_ind)) %>%
            distinct(person_id, .keep_all = TRUE) %>%
            mutate(
                enroll_date = start_date_ind,
                indication = concept_id_ind
            )

        control_cohort <- filter(cohort$indication_event,
            ! person_id %in% case_cohort$person_id
        ) %>%
            arrange(person_id, start_date) %>%
            distinct(person_id, .keep_all = TRUE) %>%
            rename(
                concept_id_ind = concept_id,
                start_date_ind = start_date,
                end_date_ind = end_date
            ) %>%
            mutate(
                enroll_date = start_date_ind,
                indication = concept_id_ind
            )
        
        basal <- bind_rows(
            transmute(case_cohort, case = 1L, person_id, enroll_date, indication),
            transmute(control_cohort, case = 0L, person_id, enroll_date, indication)
        ) %>%
            left_join(person, by = "person_id") %>%
            filter(enroll_date < last_follow_up) %>%
            mutate(
                age = interval(birth, enroll_date) / years(1),
                smoker = ifelse(! is.na(smoking_date) & smoking_date <= enroll_date, 1L, 0L)
            ) %>%
            mutate(across(c(indication, gender, race), as.factor)) %>%
            select(case, person_id, age, gender, race, smoker, indication, enroll_date)
        
        # select informative indications to design match formula
        n_case <- sum(basal$case)
        n_control <- sum(1 - basal$case)
        thres <- tibble(k = 10:n_case, 
            low = qhyper(0.025, n_case, n_control, k),
            high = qhyper(0.975, n_case, n_control, k)
        )
        basal <- left_join(basal, cohort$covariate, by = "person_id") %>%
            filter(start_date < enroll_date, end_date >= enroll_date - days(180)) %>%
            select(case, person_id, concept_id) %>%
            distinct() %>%
            filter(concept_id %in% (group_by(., concept_id) %>%
                summarize(n = n(), m_case = sum(case), m_control = n - m_case) %>%
                ungroup() %>%
                filter(m_case >= 10 | m_control >= 10) %>%
                left_join(thres, by = c("n" = "k")) %>%
                filter(m_case < low | m_case > high) %>%
                pull(concept_id)
            )) %>%
            mutate(flag = 1L) %>%
            pivot_wider(names_from = concept_id, values_from = flag, values_fill = 0L) %>%
            right_join(select(basal, !enroll_date), by = c("case", "person_id")) %>%
            mutate(across(where(is.integer), ~ .x %|% 0L))

        fo <- paste("case ~ ", paste(
            "`",
            select(basal, !c(person_id, case)) %>% colnames(),
            "`",
            sep = "", collapse = " + "
        ), sep = "") %>%
            as.formula()
        m <- matchit(fo,
            data = basal, ratio = ratio,
            distance = "lasso"
        )
        df <- match.data(m) %>%
            select(case, person_id, age, gender, race, smoker, indication, weights) %>%
            left_join(select(person, person_id, last_follow_up), by = "person_id") %>%
            left_join(bind_rows(
                select(case_cohort, person_id, enroll_date, start_date_drug, end_date_drug),
                transmute(control_cohort, person_id, enroll_date, start_date_drug = NA, end_date_drug = NA)
            ), by = "person_id")
        
        saveRDS(m, str_glue("{out_dir}/{name}-match_object.rds"))
        saveRDS(df, str_glue("{out_dir}/{name}-matched_df.rds"))
    })
