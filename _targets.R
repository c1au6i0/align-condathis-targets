# _targets.R

library(targets)
library(tarchetypes)
library(future)
library(future.batchtools)
library(batchtools)
library(here)
source(here("code", "targets_functions.R"))

# @@@@@@@@@@@@
# Set Up -----
# @@@@@@@@@@@

options(tidyverse.quiet = TRUE)
tar_option_set(
  packages = c(
    "data.table",
    "here",
    "fs",
    "condathis",
    "janitor",
    "tidyverse",
    "vroom"
  ),
  workspace_on_error = TRUE,
  garbage_collection = TRUE,
  memory = "transient"
)


list(
  # @@@@@@@@@@@@
  # Set up -----
  # @@@@@@@@@@@@

  # folder with the FASTQ files
  tar_target(
    fastq_path,
    here::here("data", "raw", "fastq")
  ),

  # This is the file that maps subj to fastq file
  tar_file_read(
    rna_files,
    here("config", "mapping.csv"),
    read_csv(file = !!.x, col_types = cols()) |>
      # add absolute path to file name
      mutate(across(
        starts_with("r"),
        \(x) fs::path(fastq_path, x)
      ))
  ),

  # Make it iterable for branching
  tar_target(
    rna_mapping,
    rna_files |>
      group_by(subject_id) |>
      tar_group(),
    iteration = "group"
  ),
  # @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  # ___check fastq  and trimmed them ----
  # @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

  # Create environment and install fastp
  tar_target(
    fastp_env,
    {
      condathis::create_env(
        "fastp=0.23.4",
        env_name = "fastp-env",
        overwrite = TRUE
      )
      "fastp-env"
    }
  ),
  # use a wrapper function in here("code", "targets_functions.R")
  # to run fastp
  tar_target(
    trimmed_fastq_qc,
    {
      fastp(
        r1 = rna_mapping$r1,
        r2 = rna_mapping$r2,
        path_folder_out_trimmed = here::here("data", "outputs", "trimmed"),
        path_folder_out_qc = here::here("data", "outputs", "fastp_qc"),
        conda_env = fastp_env
      )
    },
    iteration = "list",
    format = "file",
    pattern = map(rna_mapping)
  ),

  # @@@@@@@@@@@@
  # Align -----
  # @@@@@@@@@@@@

  # @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  # ___Prepare Micromamba Envs for Download and Align -----
  # @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

  # Create environment and install gsutils
  tar_target(
    wget_env,
    {
      if (.Platform$OS.type %in% c("windows")) {
        package_string <- "m2-wget"
      } else {
        package_string <- "wget"
      }
      condathis::create_env(
        packages = package_string,
        env_name = "wget-env",
        overwrite = TRUE
      )
      "wget-env"
    }
  ),
  # Create environment and install gsutils
  tar_target(
    gsutil_env,
    {
      condathis::create_env("gsutil=5.35", env_name = "gsutil-env", overwrite = TRUE)
      "gsutil-env"
    }
  ),
  # samtools
  tar_target(
    samtools_env,
    {
      condathis::create_env("samtools=1.22.*", env_name = "samtools-env", overwrite = TRUE)
      "samtools-env"
    }
  ),
  # minimap2
  tar_target(
    minimap_env,
    {
      condathis::create_env("minimap2=2.30.*", env_name = "minimap-env", overwrite = TRUE)
      "minimap-env"
    }
  ),

  # @@@@@@@@@@@@@@@@@@@@@@@@@@@@
  # ___Download References -----
  # @@@@@@@@@@@@@@@@@@@@@@@@@@@@

  # use a wrapper function in here("code", "targets_functions.R")
  tar_target(
    reference_files,
    download_references_hg19(
      path_download = here::here("data", "outputs", "reference"),
      gsutil_conda_env = gsutil_env,
      wget_conda_env = wget_env
    ),
    format = "file"
  ),

  # the minimap2 indexed reference
  tar_file(
    reference_mmi,
    minimap2_index(
      reference_files = reference_files,
      threads = 2,
      path_folder_out = here::here("data", "outputs", "reference"),
      conda_env = minimap_env
    )
  ),
  # @@@@@@@@@@@@@@@@
  # ___mapping -----
  # @@@@@@@@@@@@@@@@

  # use a wrapper function in here("code", "targets_functions.R")
  tar_target(
    mapped_sams,
    minimap2_align(
      reference_mmi = reference_mmi,
      r1 = trimmed_fastq_qc[1],
      r2 = trimmed_fastq_qc[2],
      threads = 2,
      path_folder_out = here::here("data", "outputs", "aligned_sam"),
      conda_env = minimap_env
    ),
    pattern = map(trimmed_fastq_qc),
    format = "file"
  ),
  # @@@@@@@@@@@@@@@@@@@@@@@@@
  # SAM to BAM and Sort -----
  # @@@@@@@@@@@@@@@@@@@@@@@@@

  # use a wrapper function in here("code", "targets_functions.R")
  tar_target(
    bam_files,
    sam_to_bam(mapped_sams,
      path_tmp = here::here("data", "tmp"),
      path_folder_out = here::here("data", "outputs", "bams"),
      threads = 2,
      conda_env = samtools_env
    ),
    pattern = map(mapped_sams),
    format = "file"
  ),
  # use a wrapper function in here("code", "targets_functions.R")
  tar_target(
    sorted_bams, # Sorted and Indexed
    sort_index(bam_files,
      path_tmp = here::here("data", "tmp"),
      path_folder_out = here::here("data", "outputs", "sorted_bams"),
      threads = 2,
      conda_env = samtools_env
    ),
    pattern = map(bam_files),
    format = "file"
  )
)
