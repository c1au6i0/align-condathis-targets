
<!-- README.md is generated from README.Rmd. Please edit that file -->

## align-condathis-targets

This repo showcases the use of
[`targets`](https://cran.r-project.org/web/packages/targets/index.html)
and
[`condathis`](https://cran.r-project.org/web/packages/condathis/index.html)
to build a pure `R` pipeline that stays reproducible while also using
non-`R` command-line interface (CLI) tools. The `targets` package is [“a
Make-like pipeline tool for statistics and data science in
`R`”](https://books.ropensci.org/targets/). The
[`condathis`](https://github.com/luciorq/condathis) package is a CRAN
package that lets you run CLI tools in `R`, ensuring reproducibility
across systems and environmental isolation. With `condathis`, there’s no
need for users to manually ensure CLI tools are installed on their
systems.

*The pipeline in this example processes RNA-seq FASTQ files by running
quality control (QC), trimming adapters, aligning the sequences, and
ultimately producing sorted BAM files.*

## Motivation

As bioinformaticians working with omics data, `R` is incredibly rich in
packages. However, most tools for the initial phases of omics analysis
are not `R`-based. The `targets` package is fantastic for building `R`
pipelines. By combining `targets` with `condathis`, we can create
pipelines that integrate both `R` tools and other CLI tools in an `R`
environment, while still maintaining reproducibility.

## How condathis is used

The package `condathis` is used to:

1)  Create environments with specific versions of the CLI tools needed.
    See example below.

``` r
## Create an environment with gsutil v5.33
condathis::create_env("gsutil==5.33", env_name = "gsutil-env")
```

2)  Interact with those environments and launch the CLI commands. See
    example below.

``` r
url_cloude_storage <- "gs://gcp-public-data--broad-references/Homo_sapiens_assembly19_1000genomes_decoy/Homo_sapiens_assembly19_1000genomes_decoy.fasta"

# Same as processx::run but needs to indicate the envname
condathis::run(
  "gsutil", "-m", "cp", url_cloude_storage, here::here("data", "outputs"), # where to save the data
  env_name = "gsutil-env"
)
```

–\> **R wrapper functions** that incorporate specific `condathis` CLI
commands are created to return paths that can be used by `tar_files`.
\<–

## Folders and files

- All the **wrapper functions** are stored in
  [`code/targets_functions.R`](./code/targets_functions.R).
- `config/`: Contains the [`mapping.csv`](./config/mapping.csv) that
  maps subjects with corresponding files.
- `data/raw/`: Contains some example FASTQ files (note that the files
  have been trimmed to contain only a few reads for easy processing).
- `data/outputs/`: This is where the outputs of the pipeline are
  created.

## Pipeline Overview

- `fastp`: Quality of FASTQ files is checked and adapters are trimmed.
- `gsutil`: Reference genome is downloaded.
- `minimap2`: Aligns the files to the reference.
- `samtools`: Transforms SAM files to BAM files and sorts

To restore all the project dependencies, run: `renv::restore()`.

All outputs will be generated in `data/outputs`.

### Run Pipeline with `targets`

``` r
library(targets)
# tar_dir()
targets::tar_make()
#> Loading required package: parallelly
#> here() starts at /Users/luciorq/projects/clones/align-condathis-targets
#> ✔ skipped target samtools_env
#> ✔ skipped target minimap_env
#> ✔ skipped target rna_files_file
#> ▶ dispatched target fastp_env
#> ● completed target fastp_env [2.669 seconds, 62 bytes]
#> ✔ skipped target gsutil_env
#> ✔ skipped target wget_env
#> ✔ skipped target fastq_path
#> ✔ skipped target reference_files
#> ✔ skipped target rna_files
#> ✔ skipped target reference_mmi
#> ✔ skipped target rna_mapping
#> ✔ skipped branch trimmed_fastq_qc_ca20143f0fae43e9
#> ✔ skipped branch trimmed_fastq_qc_6f135ab8bf1a9cb5
#> ✔ skipped pattern trimmed_fastq_qc
#> ✔ skipped branch mapped_sams_d241dbb2d8120a23
#> ✔ skipped branch mapped_sams_3c0cda8129e92eb0
#> ✔ skipped pattern mapped_sams
#> ✔ skipped branch bam_files_5c0a6881bee73101
#> ✔ skipped branch bam_files_e73d037ef7aa1ce0
#> ✔ skipped pattern bam_files
#> ✔ skipped branch sorted_bams_bcf10dcc743dc79b
#> ✔ skipped branch sorted_bams_b3b2d89238686ae2
#> ✔ skipped pattern sorted_bams
#> ▶ ended pipeline [3.471 seconds]
```
