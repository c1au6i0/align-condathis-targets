#' trim with fastp.
#' Function that uses `fastp` to trim adapters and create qc.
#' @param r1 Path to r1 file.
#' @param r2 Path to r2 file.
#' @param conda_env Conda env containing fastp.
#' @param path_folder_out_trimmed Path to folder for trimmed fastq.
#' @param path_folder_out_qc Path to folder for qc files.
#' @param other_args Any other  parameter accepts by `fastp, as a vector.
fastp <- function(
  r1,
  r2,
  path_folder_out_trimmed,
  path_folder_out_qc,
  conda_env,
  other_args = NULL
) {
  if (!fs::dir_exists(path_folder_out_trimmed)) {
    fs::dir_create(path_folder_out_trimmed)
  }

  if (!fs::dir_exists(path_folder_out_qc)) {
    fs::dir_create(path_folder_out_qc)
  }

  r1_r2_name <- lapply(c(r1, r2), \(x) {
    gsub(".fastq.gz", "_trimmed.fastq.gz", basename(x))
  })
  html_name <- paste0(
    gsub("_R$", "", comsub(basename(c(r1, r2)))),
    "_fastp.html"
  )
  json_name <- paste0(
    gsub("_R$", "", comsub(basename(c(r1, r2)))),
    "_fastp.json"
  )

  r1_r2_out <- fs::path(path_folder_out_trimmed, r1_r2_name)
  names(r1_r2_out) <- c("r1", "r2")
  html_out <- fs::path(path_folder_out_qc, html_name)
  json_out <- fs::path(path_folder_out_qc, json_name)

  # This is where we use condathis <----
  condathis::run(
    "fastp",
    "-i",
    r1,
    "-I",
    r2,
    "-o",
    r1_r2_out["r1"],
    "-O",
    r1_r2_out["r2"],
    "-h",
    html_out,
    "-j",
    json_out,
    other_args,
    env_name = conda_env
  )

  out <- c(r1_r2_out["r1"], r1_r2_out["r2"], html_out, json_out)
  names(out) <- c("r1", "r2", "qc_html", "qc_json")
  out
}

#' comsub
#'
#' Find the minimal common letters between 2 or more strings. Adapted from something taken from stackoverflow.
#' Used to rename files after merging. Used internally
#'
#' @param x character vector
#' @return string
comsub <- function(x) {
  if (class(x) == "list") {
    x <- unlist(x)
  }

  if (length(x) == 1) {
    out <- x
  } else {
    x <- sort(x)
    # split the first and last element by character
    d_x <- strsplit(x[c(1, length(x))], "")
    # search for the first not common element and so, get the last matching one
    der_com <- match(FALSE, do.call("==", d_x)) - 1
    # if there is no matching element, return an empty vector, else return the common part
    ifelse(der_com == x, out <- character(0), out <- substr(x[1], 1, der_com))
  }
  stringr::str_remove_all(out, "_L00|_00")
}


#' download references hg19
#'
#' Download references files from broad and gencode
#'
#' @param path_download Where to save data.
#' @param gsutil_conda_env Name of the condathis generated environment for `gsutil`.
#' @param wget_conda_env Name of the condathis generated environment for `wget`.
download_references_hg19 <- function(
  path_download,
  gsutil_conda_env,
  wget_conda_env
) {
  if (!file.exists(path_download)) {
    fs::dir_create(path_download)
  }

  transcripts_ftp <- "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_38/GRCh37_mapping/gencode.v38lift37.transcripts.fa.gz"

  transcripts_out <- fs::path(path_download, basename(transcripts_ftp))
  condathis::run(
    "wget",
    "-O",
    transcripts_out,
    transcripts_ftp,
    env_name = wget_conda_env,
    verbose = "silent"
  )

  reference <- "gs://gcp-public-data--broad-references/Homo_sapiens_assembly19_1000genomes_decoy/Homo_sapiens_assembly19_1000genomes_decoy.fasta"

  # This is where we use condathis <----
  condathis::run(
    "gsutil",
    "-m",
    "cp",
    reference,
    path_download,
    env_name = gsutil_conda_env,
    verbose = "silent"
  )

  # path are saved in a v0 folder

  list.files(
    path = path_download,
    include.dirs = FALSE,
    full.names = TRUE,
    recursive = TRUE
  )
}


#' fastqc
#'
#' Download references files from broad and GENCODE
#'
#' @param path_folder_out Where to save data.
#' @param path_fastq Path of fastq.
#' @param threads Number of threads.
#' @param conda_env Name of the condathis generated environemnt with fastqc.
#' @param other_args Vector of other arguments to be passed to fastqc.
fastqc <- function(
  path_folder_out,
  path_fastq,
  conda_env,
  threads = 1,
  other_args = NULL
) {
  if (!file.exists(path_folder_out)) {
    fs::dir_create(path_folder_out)
  }

  cmd <- paste(
    "fastqc",
    "-o",
    path_folder_out,
    "-t",
    threads,
    path_fastq,
    sep = " "
  )

  cli::cli_alert_info(paste0("Running: ", cmd))

  # This is where we use condathis <----
  condathis::run(
    "fastqc",
    "-o",
    path_folder_out,
    "-t",
    threads,
    path_fastq,
    env_name = conda_env,
    verbose = "silent"
  )

  basename_fastq <- gsub("\\..*$", "", basename(path_fastq))
  ext_out <- c("_fastqc.html", "_fastqc.zip")
  out <- fs::path(path_folder_out, paste0(basename_fastq, ext_out))
  names(out) <- c("html", "zip")

  out
}


#' index reference
#'
#' It indexes a fasta file using `minimap2` and create a file with extension .mmi and return the path to it.
#'
#' @param reference_files A vector of file paths with at least one with .fasta extension.
#' @param threads Number of threads.
#' @param conda_env Condathis env containing minimap2.
#' @param path_output_folder.
minimap2_index <- function(
  reference_files,
  threads = 1,
  path_folder_out,
  conda_env
) {
  if (!file.exists(path_folder_out)) {
    fs::dir_create(path_folder_out)
  }

  path_fasta <- grep("fasta$", reference_files, value = TRUE)

  name_mmi <- gsub("fasta$", "mmi", basename(path_fasta))

  path_mmi <- file.path(path_folder_out, name_mmi)

  cmd <- paste("minimap2 -t", threads, "-d", path_mmi, path_fasta, sep = " ")

  cli::cli_alert_info("Running: ", cmd)

  # This is where we use condathis <----
  condathis::run(
    "minimap2",
    "-t",
    threads,
    "-d",
    path_mmi,
    path_fasta,
    env_name = conda_env,
    verbose = "silent"
  )

  path_mmi
}

#' align fastq
#'
#' It aligns fastq files using `minimap2 -ax sr` and create a file with extension .sam and return the path to it.
#'
#' @param reference_mmi A path to a mmi reference.
#' @param r1 Path of r1 trimmed fastq files.
#' @param r2 Path of r2 trimmed fastq files.
#' @param threads Number of threads.
#' @param path_output_folder.
#' @param conda_env Condathis env containing minimap2.
#' @param other_args Other arguments to pass to minimap2 as a vector
minimap2_align <- function(
  reference_mmi,
  r1,
  r2,
  threads = 1,
  path_folder_out,
  other_args = NULL,
  conda_env
) {
  if (!file.exists(path_folder_out)) {
    fs::dir_create(path_folder_out)
  }

  r1_r2 <- c(r1, r2)
  names(r1_r2) <- c("r1", "r2")

  file_name_out <- paste0(gsub("_R$", "", comsub(basename(r1_r2))), ".sam")
  path_sam <- fs::path(path_folder_out, file_name_out)

  # This is where we use condathis <----
  condathis::run(
    "minimap2",
    "-ax",
    "sr",
    "-t",
    threads,
    reference_mmi,
    r1_r2["r1"],
    r1_r2["r2"],
    other_args,
    stdout = path_sam,
    env_name = conda_env,
    verbose = "silent"
  )

  path_sam
}


#' sam to bam
#'
#' Use `samtools` to convert sam to bam. Create a bam file with .bam extension.
#'
#' @param path_sam Path to sam file.
#' @param path_folder_out Path to output folder.
#' @param num_threads.
#' @param conda_env Condathis env containing samtools.
sam_to_bam <- function(
  path_sam,
  path_tmp,
  path_folder_out,
  threads,
  conda_env
) {
  if (!file.exists(path_tmp)) {
    fs::dir_create(path_tmp)
  }

  if (!file.exists(path_folder_out)) {
    fs::dir_create(path_folder_out)
  }

  path_bam <- file.path(
    path_folder_out,
    gsub("sam$", "bam", basename(path_sam))
  )

  # This is where we use condathis <----
  condathis::run(
    "samtools",
    "view",
    "-hb",
    "-@",
    threads,
    path_sam,
    stdout = path_bam,
    env_name = conda_env,
    verbose = "silent"
  )
  path_bam
}

#' sort and index
#'
#' Use `samtools` to sort and index bams
#'
#' @param path_tmp for tmp_files.
#' @param path_bam Path to bam.
#' @param path_folder_out Path to output folder.
#' @param threads.
#' @param conda_env Condathis env containing samtools.
sort_index <- function(
  path_bam,
  path_tmp,
  path_folder_out,
  threads,
  conda_env
) {
  if (!file.exists(path_folder_out)) {
    fs::dir_create(path_folder_out)
  }

  path_sorted_bam <- file.path(
    path_folder_out,
    paste0("sorted_", basename(path_bam))
  )
  path_sorted_bai <- paste0(path_sorted_bam, ".bai")

  # This is where we use condathis <----
  condathis::run(
    "samtools",
    "sort",
    "-T",
    path_tmp,
    path_bam,
    "-@",
    threads,
    "-o",
    path_sorted_bam,
    env_name = conda_env,
    verbose = "silent"
  )
  condathis::run(
    "samtools",
    "index",
    "-@",
    threads,
    path_sorted_bam,
    env_name = conda_env,
    verbose = "silent"
  )

  c(path_sorted_bam, path_sorted_bai)
}
