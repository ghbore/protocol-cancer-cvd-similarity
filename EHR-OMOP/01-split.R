#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
})

config_dir <- snakemake@input[["config_dir"]]
export_dir <- snakemake@input[["export_dir"]]
out_dir <- snakemake@output[[1]]

disease_group <- readxl::read_xlsx(str_glue("{config_dir}/disease_group.xlsx")) %>%
    filter(! if_any(everything(), ~ is.na(.)))

codeset <- read_csv(str_glue("{export_dir}/codeset.csv.gz"), col_types = "ii") %>%
    left_join(
        read_csv(str_glue("{export_dir}/codeset_definition.csv.gz"), col_types = "ic--"),
        by = "codeset_id"
    )

## 519612
person <- read_csv(str_glue("{export_dir}/person.csv.gz"), col_types = "iiiiiiiDiD") %>%
    filter(
        gender_concept_id != 0,
        race_concept_id %in% c(8515, 8516, 8527, 8557, 8657)
    ) %>%
    transmute(
        person_id, gender = gender_concept_id, 
        birth = lubridate::date(
            paste(year_of_birth, month_of_birth, day_of_birth, sep = "-")
        ),
        race = race_concept_id,
        death = death_date,
        cause = cause_concept_id,
        last_follow_up = case_when(
            is.na(death) ~ last_follow_up,
            TRUE ~ death
        )
    ) %>%
    left_join(
        read_csv(str_glue("{export_dir}/smoker.csv.gz"), col_type = "-iiD") %>%
            group_by(person_id) %>%
            summarize(smoking_date = min(observation_date)) %>%
            ungroup(),
        by = "person_id"
    )

## 56158970
covariate <- read_csv(str_glue("{export_dir}/cov.csv.gz"), col_types = "-iiDD") %>%
    filter(concept_id != 0, person_id %in% person$person_id) %>%
    distinct()

## 6506032
event <- read_csv(str_glue("{export_dir}/event.csv.gz"), col_types = "-iiDD") %>%
    filter(person_id %in% person$person_id) %>%
    distinct()

# dump into pieces
if (! dir.exists(out_dir)){
    dir.create(out_dir)
}
saveRDS(codeset, str_glue("{out_dir}/codeset.rds"))
saveRDS(person, str_glue("{out_dir}/person.rds"))

if (! snakemake@params[["release_group_only"]]){
    distinct(disease_group, abbr)$abbr %>%
        lapply(function (abbr){
            d <- filter(event, concept_id %in%
                    filter(codeset, codeset_name == str_glue("{abbr}, Dx"))$concept_id
                )
            if (nrow(d) > 0){
                saveRDS(d, str_glue("{out_dir}/{abbr}-event.rds"))
            }
        })
}

group_by(disease_group, group) %>%
    group_walk(function (.x, .y){
        lapply(.x$abbr, function (abbr) 
            filter(event, concept_id %in%
                filter(codeset, codeset_name == str_glue("{abbr}, Dx"))$concept_id
            )
        ) %>%
            bind_rows() %>%
            distinct() %>%
            saveRDS(str_glue("{out_dir}/{.y$group}-event.rds"))
    })

distinct(codeset, codeset_name) %>% 
    filter(str_detect(codeset_name, ", Rx")) %>% 
    unlist() %>% 
    unname() %>% 
    str_remove(", Rx$") %>%
    lapply(function (drug){
        indication_event <- filter(event, concept_id %in% (
            filter(codeset, codeset_name == str_glue("{drug}, ind")) %>%
            distinct(concept_id) %>%
            pull()
        ))

        list(
            drug_event = filter(event, concept_id %in% (
                filter(codeset, codeset_name == str_glue("{drug}, Rx")) %>%
                distinct(concept_id) %>%
                pull()
            )), 
            indication_event = indication_event, 
            covariate = filter(covariate, person_id %in% (
                distinct(indication_event, person_id) %>%
                pull()
            ))
        ) %>%
            saveRDS(str_glue("{out_dir}/{drug}-cohort.rds"))
    })
