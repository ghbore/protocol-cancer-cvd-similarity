# To add a new cell, type '# %%'
# To add a new markdown cell, type '# %% [markdown]'
# %%
## init env
import pandas as pd
from google.cloud import bigquery
import os
from time import sleep
from pathlib import Path
import jinja2

# change following configurations accordingly
ref_project_id = snakemake.params["ref_project_id"]
ref_dataset_id = snakemake.params["ref_dataset_id"]

work_project_id = snakemake.params["work_project_id"]
work_dataset_id = snakemake.params["work_dataset_id"]

os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "__ADD_YOUR_OWN_CREDENTIALS__"
os.environ["GCLOUD_PROJECT"] = work_project_id

client = bigquery.Client(project=work_project_id)

# %%
## function
CONFIG_DIR = snakemake.input["config_dir"]
SQL_SRC = snakemake.input["sql_template_dir"]
SQL_DEST = snakemake.output["sql_cache_dir"]
DUMP_DIR = snakemake.output["export_dir"]
if not Path(SQL_DEST).exists():
    Path(SQL_DEST).mkdir()
if not Path(DUMP_DIR).exists():
    Path(DUMP_DIR).mkdir()

env = jinja2.Environment(loader=jinja2.FileSystemLoader(SQL_SRC))

parameters = {
    "ref_project": ref_project_id,
    "ref_dataset": ref_dataset_id,
    "work_project": work_project_id,
    "work_dataset": work_dataset_id,
}


def load_sql_file(name, new_name=None, force=False, **kwargs):
    template = env.get_template(name)
    if new_name is None:
        new_name = name
    dest = f"{SQL_DEST}/{new_name}"
    sql = template.render(kwargs)
    if force or not Path(dest).exists():
        with open(dest, "w") as F:
            F.writelines(sql)
    return sql


def dump_df(df, name):
    df.to_csv(f"{DUMP_DIR}/{name}.csv.gz", index=False)


def dump_table(table, project=work_project_id, dataset=work_dataset_id):
    client.list_rows(
        bigquery.TableReference.from_string(f"{project}.{dataset}.{table}")
    ).to_dataframe().to_csv(f"{DUMP_DIR}/{table}.csv.gz", index=False)


# %%
## create codeset tables
sql = load_sql_file("create_codeset_table.sql", **parameters)
client.query(sql)

## disease, Dx
for abbr, info in (
    pd.read_excel(f"{CONFIG_DIR}/disease_concept.xlsx")
    .dropna()
    .astype({"concept_id": "int"})
    .groupby("abbr")
):
    sql = load_sql_file(
        "add_codeset.sql",
        f"codeset_{abbr}.sql",
        force=True,
        codeset_name=f"{abbr}, Dx",
        codeset_domain="condition_era",
        codeset_desc=f"diagnosed with {abbr}",
        target_concept=info.concept_id.to_list(),
        **parameters,
    )
    job = client.query(sql)
    while not job.done():
        sleep(1)

## drug
for drug, info in (
    pd.read_excel(f"{CONFIG_DIR}/drug_concept.xlsx")
    .dropna()
    .astype({"concept_id": "int"})
    .groupby("drug")
):
    sql = load_sql_file(
        "add_codeset.sql",
        f"codeset_{drug}.sql",
        force=True,
        codeset_name=f"{drug}, Rx",
        codeset_domain="drug_era",
        codeset_desc=f"prescribed with {drug}",
        target_concept=info.concept_id.to_list(),
        **parameters,
    )
    job = client.query(sql)
    while not job.done():
        sleep(1)

## indication
for drug, info in (
    pd.read_excel(f"{CONFIG_DIR}/indication_concept.xlsx", skiprows=1)
    .dropna()
    .astype({"concept_id": "int"})
    .groupby("drug")
):
    sql = load_sql_file(
        "add_codeset.sql",
        f"codeset_{drug}_ind.sql",
        force=True,
        codeset_name=f"{drug}, ind",
        codeset_domain="condition_era",
        codeset_desc=f"indications for {drug}",
        target_concept=info.concept_id.to_list(),
        **parameters,
    )
    job = client.query(sql)
    while not job.done():
        sleep(1)

# %%
## create event table
sql = load_sql_file("create_event_table.sql", **parameters)
client.query(sql)

## add all events associated with codeset
sql = load_sql_file("add_all_event.sql", **parameters)
client.query(sql)

# %%
## create covariate table
sql = load_sql_file("create_cov_table.sql", **parameters)
client.query(sql)

## add all covariates associated with indications
sql = load_sql_file("add_all_cov.sql", **parameters)
client.query(sql)

# %%
## dump table
dump_table("codeset_definition")
dump_table("codeset")
dump_table("event")
dump_table("cov")

sql = load_sql_file("get_person_info.sql", **parameters)
dump_df(client.query(sql).result().to_dataframe(), "person")

sql = load_sql_file("get_person_smoking.sql", **parameters)
dump_df(client.query(sql).result().to_dataframe(), "smoker")
