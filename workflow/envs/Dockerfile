FROM mambaorg/micromamba as conda

RUN micromamba create -y \
    -c conda-forge -c bioconda \
    -n protocol \
    pandas snakemake openpyxl

FROM rocker/tidyverse:4.1

COPY --from=conda /opt/conda/envs/protocol /opt/conda/envs/protocol
COPY . /opt/protocol
ENV PATH="/opt/conda/envs/protocol/bin:$PATH"

# Rhtslib/Rsamtools/GenomicAlignments/rtracklayer dependency:
#   libssl-dev libbz2-dev liblzma-dev libcurl-dev
# igraph/enrichplot/clusterProfiler dependency:
#   libglk40
RUN apt update -qq && \
    apt install -y pkg-config build-essential \
    libssl-dev libbz2-dev liblzma-dev libcurl4-openssl-dev \
    libglpk40

RUN Rscript -e " \
        install.packages(c( \
            'renv', \
            'yulab.utils', \
            'BiocManager' \
        )); \
        renv::install(c( \
            'data.table', 'Rfast', \
            'survival', 'survminer', \
            'ggsci', 'gridExtra', 'GGally', \
            'spatstat@1.64-1', 'Seurat@4.0.0', \
            'extrafont', \
            'pheatmap', 'ggbeeswarm', \
            'DT', 'mixsmsn', \
            'MatchIt' \
        ), prompt = TRUE); \
        BiocManager::install( \
            c( \
                'clusterProfiler', \
                'rtracklayer', \
                'GenomicRanges', \
                'DOSE', \
                'org.Hs.eg.db' \
            ), \
            version = '3.14', \
            update = FALSE, \
            ask = FALSE \
        ); \
    "