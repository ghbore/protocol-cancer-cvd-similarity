# Protocol to identify shared transcriptional risks between diseases and compounds predicted to result in mutual benefit

The accumulation of Omics and biobank resources allows for a holistic genome-wide understanding of the shared pathologic mechanisms that drive diseases and for strategies to identify drugs that could be repurposed as novel treatments for these diseases. However, this abundance of publicly available data can be challenging to integrate to generate valuable insights. We recently published two studies ([Gao et al, 2022](#1) and [Baylis et al, 2023](#2)) comparing transcriptional datasets correlated with disease outcomes between multiple diseases to allow for novel discovery of shared biology and for identification of novel putative therapies. Specifically, we used tumor transcriptomes correlated with cancer mortality to compare individual cancer subtypes and identified novel cancer clusters with shared biology and identify therapeutics that may benefit individual clusters. We expanded this effort by comparing the cancer dataset with multiple coronary artery disease datasets, which again revealed novel pathophysiologic insights and identified therapies that could be repurposed to treat both diseases. Herein, we present the computational protocol used in these works, implemented as a Snakemake workflow which will allow investigators to identify shared transcriptional processes that drive disease and how to use this data to screen existing compounds that could result in mutual benefit. This protocol also includes a description of the pharmacovigilance study design that was used to validate the effect of novel compounds using electronic health records where applicable.

## Citation

[![DOI:10.1016/j.xpro.2024.102883](http://img.shields.io/badge/DOI-10.1016/j.xpro.2024.102883-blue.svg)](https://star-protocols.cell.com/protocols/3300)

Gao, Hua, Mao Zhang, Richard A. Baylis, Fudi Wang, Johan L.M. Björkegren, Jason J. Kovacic, Arno Ruusalepp, and Nicholas J. Leeper. “Computational Protocol to Identify Shared Transcriptional Risks and Mutually Beneficial Compounds between Diseases.” STAR Protocols 5, no. 1 (March 2024): 102883. https://doi.org/10.1016/j.xpro.2024.102883.

## Manual

The pipeline below describes the specific steps used to identify the shared transcriptional risks between atherosclerosis and cancer, by using [The Cancer Genome Atlas (TCGA) datasets](www.cancer.gov/ccg/research/genome-sequencing/tcga) for the various cancer subtypes and the [Stockholm-Tartu Atherosclerosis Reverse Network Engineering Task (STARNET)](#3) and [Biobank of Karolinska Endarterectomy (BiKE)](ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE21545) atherosclerosis datasets. However, the protocol is adaptable to any analogous datasets from which summary statistics of transcriptional risks can be derived.

### Download this pipeline

```bash
git clone https://github.com/ghbore/protocol-cancer-cvd-similarity.git
```

### Install the virtual environment

1. Create a conda virtual environment and activate it.

```bash
cd protocol-cancer-cdv-similarity
mamba create --name protocol --file workflow/envs/env.yaml
conda activate protocol
```

2. Install dependent R packages.

```bash
bash workflow/envs/post.sh
```

### Workflow configuration

This pipeline is encapsulated in a Snakemake workflow, making it highly accessible and user-friendly. The user experience is further enhanced by the centralized configuration options housed in the `config/config.yaml` file. These configurations include,

  1. Gencode Annotation version. Choose the preferred Gencode annotation version from the available options listed here: https://www.gencodegenes.org/human/releases.html. The default value is 36, to replicate the published results.

      ```YAML
      # Gencode annotation is going to be used for gene ID mapping.
      # The Gencode release version.
      # Choose the preferred Gencode annotation version from 
      #   the available options listed here: https://www.gencodegenes.org/human/releases.html
      gencode_version: "36"
      ```
  
  2. The database used for pathway enrichment analysis. The options include MSigDB, KEGG, GO molecular function, GO biological process, or even a custom term-gene mapping file. The default is hallmark.
  
      ```YAML
      # Available databases for enrichment analysis:
      #  1. hallmark
      #  2. KEGG
      #  3. GO_MF
      #  4. GO_BP
      #  5. Custom pathway term-gene mapping file in the TSV format
      #       with at least two columns,
      #       one for the pathway term (ID and/or description),
      #       and one for the gene (ensembl, entrez, and/or symbol).
      #       For example:
      #       ID        entrez    description
      #       hsa01100  10        Metabolic pathways
      #       hsa01100  100       Metabolic pathways
      enrichment_analysis_database: hallmark
      ```

  3. Custom dataset registration, allowing researchers to integrate custom datasets into the analysis. The configuration includes,

      a. Dataset name. Define unique dataset names for easy identification and reference.

      b. Gene level risk profile file. The file can be an R Data file, or TSV file, or XLSX file, and be formatted as required.

      - At least one gene IDs, such as ensembl (Ensembl gene ID), entrez (NCBI Entrez gene ID), and symbol (gene symbol),
      - beta, the effect size, such as survival log hazard ratio and correlation coefficient,
      - pval, the statistical P-value associated with the corresponding “beta” value.

      ```YAML
      # Custom dataset registration.
      datasets:
        custom_1: # Dataset name
          # Risk profile file in the gene level.
          # The file can be an R Data, TSV, or XLSX, with at least three columns:
          #   1. gene ID, such as `ensembl` (Ensembl gene ID), `entrez` (NCBI Entrez gene ID), and / or `symbol` (gene symbol)
          #   2. `beta`, the effect size, such as survival log hazard ratio and correlation coefficient
          #   3. `pval`, the statistical P-value associated with the `beta` value
          gene: "path/to/gene_level_risk_profile"
        AOR_vs_MAM: # An example
          gene: "custom/AOR_vs_MAM_DGElist.xlsx"
      ```

  4. P-value and effect size cutoffs to remove noise and outlier genes.

      ```YAML
      # Criteria to remove noise and outlier genes.
      ## General criteria
      pvalue_range:
        - 0
        - 0.5
      beta_range:
        - "-Inf"
        - "Inf"
      ## Dataset specific criteria,
      ##   which will overwrite the corresponding general criteria
      bike_plaque:
        beta_range:
          - -10
          - 10
      ```

  5. Dataset clustering configuration, further including,

      a. Analysis name. Define unique names for different analyses combining various datasets and resolution setting. Each name will serve as a prefix for corresponding output filenames (e.g., reports/cancer_only-clustering.html for analysis “cancer_only”).

      b. Associated datasets. Specify the list of datasets included in each analysis.

      c. Resolution parameter. This parameter controls the granularity of clustering. Higher values (above 1.0) lead to a larger number of communities, while lower values (below 1.0) result in a smaller number of communities. The optimal value depends on the specific goals. Additional details are available here: https://satijalab.org/seurat/reference/findclusters.

      ```YAML
      # Clustering parameters.
      # This part configures which datasets will be included in the clustering analysis,
      #   and how densely clustered datasets are grouped together.
      # Configurations for multiple analyses are allowed.
      dataset_clustering:

        cancer_only: # Analysis name, as prefix to the corresponding output filenames
          datasets: # The list of datasets included in the analysis
            [
              "ACC", "BLCA", "BRCA", "CESC", "CHOL", "COAD", 
              "ESCA", "GBM", "HNSC", "KIRC", "KIRP", "LAML", "LGG",
              "LIHC", "LUAD", "LUSC", "MESO", "OV", "PAAD", "READ",
              "SARC", "SKCM", "STAD", "THCA", "UCEC", "UCS", "UVM"
            ]
          # The resolution parameter controls the granularity of clustering.
          # Higher values (above 1.0) lead to a larger number of communities, 
          #   while lower values (below 1.0) result in a smaller number of communities.
          # The optimal value depends on the specific goals.
          # For details, see https://satijalab.org/seurat/reference/findclusters
          resolution: 1
      ```

  6. Dataset grouping configuration. The grouping configuration may depend on dataset clustering results. The configuration further includes,

      a. Analysis name. Similar to clustering, specify distinct names for various grouping configurations. These names will again prefix output filenames, for example, “reports/ cancer_clusters-shared_risks.html” for the analysis “cancer_clusters”.

      b. Group names and their associated datasets. Assign meaningful names to each cluster of datasets after dataset clustering.

      ```YAML
      # Dataset group definition.
      # The grouping configuration may depend on dataset clustering results.
      # Here is the chance to assign meaningful names to each cluster after dataset clustering.
      dataset_grouping:

        cancer_clusters: # Analysis name, as prefix to the corresponding output filenames
          inflammatory: ["BRCA" , "CESC" , "GBM" , "LGG" , "LUSC" , "OV" , "PAAD" , "READ" , "STAD" , "THCA"]
          proliferative: ["ACC" , "BLCA" , "COAD" , "KIRC" , "KIRP" , "LUAD" , "MESO" , "SARC" , "SKCM" , "UCEC"]
          metabolic: ["CHOL" , "ESCA" , "HNSC" , "LAML" , "LIHC" , "UCS" , "UVM"]
      ```


### Download dependent resources

These resources provide the initial materials necessary to replicate the two published studies.

Given that the [BiKE](ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE21545) dataset is array-based expression profiles using Affymetrix Human Genome U133 Plus 2.0 Array, and the official array annotation file is under restricted access, the researcher can download the annotation file following the instruction in [this Thermofisher webpage](www.thermofisher.com/us/en/home/life-science/microarray-analysis/microarray-data-analysis/genechip-array-annotation-files.html), and then move the downloaded file to “resources/bike/HG-U133_Plus_2-na36-annot-csv.zip”.

Considering the STARNET CVD dataset, researchers with authorized access can download the raw RNA-Seq data and phenotype data from [dbGaP (phs001203.v3.p1)](https://www.ncbi.nlm.nih.gov/projects/gap/cgi-bin/study.cgi?study_id=phs001203.v3.p1), re-analyze them to generate the summary statistics, and copy the summary statistics to the “resources/starnet/” directory as demonstrated below. Alternatively, the original summary statistics of the STARNET dataset are available upon request from Prof. Björkegren. Researchers can also skip the gene-level analysis and start from the pathway-level statistics provided in the [“all resources and results bundle”](https://zenodo.org/doi/10.5281/zenodo.10032148).


```bash
snakemake --cores all Download

tree resources
# resources/
# ├── bike
# │   ├── HG-U133_Plus_2-na36-annot-csv.zip
# │   └── series.gz
# ├── gencode.gff.gz
# ├── gencode.metadata.entrez
# ├── gsea
# │   └── hallmark
# ├── lincs
# │   ├── GPL20573.tsv.gz
# │   └── octad.db_0.99.0.tar.gz
# ├── starnet
# │   ├── AOR_vs_MAM_DGElist.xlsm
# │   └── AORsyntax_duke_Cor_P.xlsm
# └── tcga
#     ├── all_indexed_clinical.rds
#     ├── basic_pheno.tsv.gz
#     └── fpkm-uq.tsv.gz

snakemake --cores all Compile

tree resources # list newly generated files below
# resources/
# ├── bike
# │   ├── anno.rds
# │   └── data.rds
# ├── gencode.rds
# ├── lincs
# │   ├── landmark.rds
# │   └── lincs.rds
# ├── starnet
# │   ├── AOR_vs_MAM.rds
# │   ├── AOR_syntax.rds
# │   └── AOR_duke.rds
# └── tcga
#     └── pheno.rds
```

### Identify transcriptional risks

```bash
snakemake --cores all Gene

tree results
# results
# └── gene
#     ├── ACC.rd
#     ├── AOR_duke.rds
#     ├── AOR_syntax.rds
#     ├── AOR_vs_MAM.rds
#     ├── BLCA.rds
#     ├── ...
#     └── bike_plaque.rds
```

Previous steps would be dataset specific. However, the results in directory “results/gene/” are standardized. Each R Data (RDS) file contains a table storing the summary statistics (beta and pval), and the GENCODE annotations (ensembl, entrez and symbol). The filenames will serve as unique identifiers for the corresponding datasets.

```bash
snakemake --cores all Pathway

tree results/pathway 
# results/pathway
# ├── ACC.rds
# ├── AOR_duke.rds
# ├── AOR_syntax.rds
# ├── AOR_vs_MAM.rds
# ├── BLCA.rds
# ├── ...
# └── bike_plaque.rds
```

### Cluster and identify shared risks

These two steps are dependent on the configuration file `config/config.yaml`. For the clustering, the "dataset_clustering" section controls which datasets will be clustered together. In this example, the pipeline will run clustering twice, one for "cancer_only" datasets, and another for "athero_and_cancer" datasets. Additionally, the clustering parameters could be fine-tuned in accordance with available knowledge and data.

```YAML
dataset_clustering:
  cancer_only:
    datasets: ["ACC", "BLCA", "BRCA", "CESC", "CHOL", "COAD", 
        "ESCA", "GBM", "HNSC", "KIRC", "KIRP", "LAML", "LGG",
        "LIHC", "LUAD", "LUSC", "MESO", "OV", "PAAD", "READ",
         "SARC", "SKCM", "STAD", "THCA", "UCEC", "UCS", "UVM"
      ]
    resolution: 1
  athero_and_cancer:
    datasets: ["AOR_vs_MAM", "AOR_duke", "AOR_syntax", "bike_plaque",
        "ACC", "BLCA", "BRCA", "CESC", "CHOL", "COAD", 
        "ESCA", "GBM", "HNSC", "KIRC", "KIRP", "LAML", "LGG",
        "LIHC", "LUAD", "LUSC", "MESO", "OV", "PAAD", "READ",
         "SARC", "SKCM", "STAD", "THCA", "UCEC", "UCS", "UVM"
      ]
    resolution: 0.4
```

Thus,

```bash
snakemake --cores all Cluster
  
tree -P “*-clustering.html” reports/
# reports
# ├── athero_and_cancer-clustering.html
# └── cancer_only-clustering.html
```

For the shared risk identification, the "dataset_grouping" section defines how to group the dataset and then identify the shared risks between groups. In this example, the pipeline will run this step triple times.

```YAML
dataset_grouping:
  cancer_clusters:
    inflammatory: ["BRCA" , "CESC" , "GBM" , "LGG" , "LUSC" , "OV" , "PAAD" , "READ" , "STAD" , "THCA"]
    proliferative: ["ACC" , "BLCA" , "COAD" , "KIRC" , "KIRP" , "LUAD" , "MESO" , "SARC" , "SKCM" , "UCEC"]
    metabolic: ["CHOL" , "ESCA" , "HNSC" , "LAML" , "LIHC" , "UCS" , "UVM"]
  athero_vs_cancer:
    atherosclerosis: ["AOR_vs_MAM", "AOR_duke", "AOR_syntax", "bike_plaque"]
    cancer: ["ACC", "BLCA", "BRCA", "CESC", "CHOL", "COAD", 
        "ESCA", "GBM", "HNSC", "KIRC", "KIRP", "LAML", "LGG",
        "LIHC", "LUAD", "LUSC", "MESO", "OV", "PAAD", "READ",
         "SARC", "SKCM", "STAD", "THCA", "UCEC", "UCS", "UVM"
      ]
  athero_vs_cancer2:
    atherosclerosis: ["AOR_vs_MAM", "AOR_duke", "AOR_syntax", "bike_plaque"]
    athero_similar: ["BRCA", "CESC", "GBM", "LGG", "LUSC", "OV", "PAAD", "READ", "STAD", "THCA"]
    athero_dissimilar: ["ACC", "BLCA", "COAD", "KIRC", "KIRP", "LUAD", "MESO", "SARC",
      "SKCM", "UCEC", "CHOL", "ESCA", "HNSC", "LAML", "UCS", "UVM"]
```

Thus,

```bash
snakemake --cores all Common

tree -P “*-shared_risks.html” reports/
# reports
# ├── athero_vs_cancer-shared_risks.html
# ├── athero_vs_cancer2-shared_risks.html
# └── cancer_clusters-shared_risks.html
```

### Screen drug

```bash
snakemake --cores all Compound

tree -P “rges.rds” results/compound 
# results/compound
# └── rges.rds
```

It is highly recommended to run this step on a high-performance computing cluster. The output “results/compound/rges.rds” is a table containing the reversal gene expression score (RGES) and associated P-value for each compound perturbation assay in each dataset.

### Validate the promising drug using EHR

This protocol involves pharmacovigilance study design that leverages de-identified electronic health records (EHR). While the code is initially tailored for use on the Stanford STARR platform and the necessary permissions are required, it is important to note that any warehouse adhering to the [Observational Medical Outcomes Partnership (OMOP) Common Data Model (CDM)](www.ohdsi.org/data-standardization/), would be compatible with this protocol.

Here, we use Clopidogrel as an example. Clopidogrel was predicted to have specific benefit for certain cancer types. To validate this prediction, we collected two propensity-matched (matched on demographics, smoking status, comorbid conditions, procedures, and therapeutics in the 6 months leading up to enrollment) cohorts. Clopidogrel generally is prescribed to patients diagnosed with cardiovascular events, such as myocardial infarction. Thus, those indications were defined as the entry events. Patients prescribed clopidogrel were then defined as being in the treatment cohort, while those that were not prescribed this drug were defined as being in the control cohort. The endpoint was defined as the incidence of different cancer types within 5 years.

Once the study design is finalized, prepare the configuration files (see examples in EHR-OMOP/conf) by translating the drug, diseases, and indications to OMOP Vocabulary concept IDs, using [Athena](athena.ohdsi.org/search-terms/terms).

Then, setup the credentials for accessing the EHR database, and initiate the pharmacovigilance study.

```bash
snakemake --cores all EHR_validation

tree EHR-OMOP/fit EHR-OMOP/plot
# EHR-OMOP/fit
# ├── clopidogrel-inflammatory.rds
# ├── clopidogrel-metabolic.rds
# ├── clopidogrel-proliferative.rds
# ├── clopidogrel.csv
# └── clopidogrel.rds
# EHR-OMOP/plot
# ├── clopidogrel-inflammatory.pdf
# ├── clopidogrel-metabolic.pdf
# └── clopidogrel-proliferative.pdf
```

It is also highly recommended to run this step on a high-performance computing cluster. The output “EHR-OMOP/fit/clopidogrel.csv” is a table containing the survival statistics.

### The expected outcomes

1. The example results for the clustering refer to Figure 1A in [Gao et al, 2022](#1), and Figure 2B in [Baylis et al, 2023](#2).
2. The example results for the shared risk identification refer to Figure 1B in [Gao et al, 2022](#1), and Figure 1B in [Baylis et al, 2023](#2).
3. The example results for the drug screening refer to Figure 3B in [Baylis et al, 2023](#2).
4. The example results for the EHR validation refer to Figure 1E in [Gao et al, 2022](#1).

## Reference
<a id="1">1</a>. Gao, Hua, Richard A. Baylis, Lingfeng Luo, Yoko Kojima, Caitlin F. Bell, Elsie G. Ross, Fudi Wang, and Nicholas J. Leeper. “Clustering Cancers by Shared Transcriptional Risk Reveals Novel Targets for Cancer Therapy.” Molecular Cancer 21, no. 1 (December 2022): 116. https://doi.org/10.1186/s12943-022-01592-y.

<a id="2">2</a>. Baylis, Richard A., Hua Gao, Fudi Wang, Caitlin F. Bell, Lingfeng Luo, Johan L.M. Björkegren, and Nicholas J. Leeper. “Identifying Shared Transcriptional Risk Patterns between Atherosclerosis and Cancer.” iScience 26, no. 9 (September 2023): 107513. https://doi.org/10.1016/j.isci.2023.107513.

<a id="3">3</a>. Franzén, Oscar, Raili Ermel, Ariella Cohain, Nicholas K. Akers, Antonio Di Narzo, Husain A. Talukdar, Hassan Foroughi-Asl, et al. “Cardiometabolic Risk Loci Share Downstream Cis- and Trans-Gene Regulation across Tissues and Diseases.” Science 353, no. 6301 (August 19, 2016): 827–30. https://doi.org/10.1126/science.aad6970.
