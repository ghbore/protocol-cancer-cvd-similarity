#! /usr/bin/env Rscript

suppressPackageStartupMessages({
    library(tidyverse)
})

(\ (basic, clinical, output){
    read_tsv(basic) |>
        filter(program == "TCGA", sample_type_id < 10) |>
        transmute(
            submitter_id = str_extract(sample, "TCGA-[^-]+-[^-]+"),
            sample, sample_type,
            disease = str_sub(project_id, 6)
        ) |>
        filter(
            disease != "",
            str_starts(sample_type, "Primary")
        ) |>
        arrange(submitter_id, sample) |>
        group_by(submitter_id) |>
        slice_head() |>
        ungroup() |>
        inner_join(
            readRDS(clinical) |>
                filter(race == "white") |>
                transmute(
                    submitter_id,
                    gender, age_at_index,
                    event = case_when(
                        vital_status == "Alive" ~ 0L,
                        vital_status == "Dead" ~ 1L,
                        TRUE ~ NA_integer_
                    ),
                    time = case_when(
                        vital_status == "Alive" ~ days_to_last_follow_up,
                        vital_status == "Dead" ~ days_to_death,
                        TRUE ~ NA_integer_
                    )
                ) |>
                filter(!if_any(everything(), is.na))
        ) |>
        select(
            submitter_id, sample, disease,
            gender, age_at_index, event, time
        ) |>
        filter(time > 0) |>
        saveRDS(output)
})(
    snakemake@input[["basic"]],
    snakemake@input[["clinical"]],
    snakemake@output[[1]]
)