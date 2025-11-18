
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
#> here() starts at /Users/luciorq/workspaces/temp/align-condathis-targets
#> + reference_mmi dispatched
#> ℹ Running:
#> ✔ reference_mmi completed [49.5s, 7.23 GB]
#> + rna_mapping dispatched
#> ✔ rna_mapping completed [4ms, 320 B]
#> + trimmed_fastq_qc declared [2 branches]
#> Read1 before filtering:
#> total reads: 1086
#> total bases: 108600
#> Q20 bases: 0(0%)
#> Q30 bases: 0(0%)
#>
#> Read2 before filtering:
#> total reads: 1086
#> total bases: 108600
#> Q20 bases: 0(0%)
#> Q30 bases: 0(0%)
#>
#> Read1 after filtering:
#> total reads: 0
#> total bases: 0
#> Q20 bases: 0(nan%)
#> Q30 bases: 0(nan%)
#>
#> Read2 after filtering:
#> total reads: 0
#> total bases: 0
#> Q20 bases: 0(nan%)
#> Q30 bases: 0(nan%)
#>
#> Filtering result:
#> reads passed filter: 0
#> reads failed due to low quality: 2172
#> reads failed due to too many N: 0
#> reads failed due to too short: 0
#> reads with adapter trimmed: 0
#> bases trimmed due to adapters: 0
#>
#> Duplication rate: 0%
#>
#> Insert size peak (evaluated by paired-end reads): 110
#>
#> JSON report: /Users/luciorq/workspaces/temp/align-condathis-targets/data/outputs/fastp_qc/subj11_fastp.json
#> HTML report: /Users/luciorq/workspaces/temp/align-condathis-targets/data/outputs/fastp_qc/subj11_fastp.html
#>
#> fastp -i /Users/luciorq/workspaces/temp/align-condathis-targets/data/raw/fastq/subj1_L001_R1_001.fastq.gz -I /Users/luciorq/workspaces/temp/align-condathis-targets/data/raw/fastq/subj1_L001_R2_001.fastq.gz -o /Users/luciorq/workspaces/temp/align-condathis-targets/data/outputs/trimmed/subj1_L001_R1_001_trimmed.fastq.gz -O /Users/luciorq/workspaces/temp/align-condathis-targets/data/outputs/trimmed/subj1_L001_R2_001_trimmed.fastq.gz -h /Users/luciorq/workspaces/temp/align-condathis-targets/data/outputs/fastp_qc/subj11_fastp.html -j /Users/luciorq/workspaces/temp/align-condathis-targets/data/outputs/fastp_qc/subj11_fastp.json
#> fastp v0.23.4, time used: 0 seconds
#> Read1 before filtering:
#> total reads: 1145
#> total bases: 114500
#> Q20 bases: 0(0%)
#> Q30 bases: 0(0%)
#>
#> Read2 before filtering:
#> total reads: 1145
#> total bases: 114500
#> Q20 bases: 0(0%)
#> Q30 bases: 0(0%)
#>
#> Read1 after filtering:
#> total reads: 0
#> total bases: 0
#> Q20 bases: 0(nan%)
#> Q30 bases: 0(nan%)
#>
#> Read2 after filtering:
#> total reads: 0
#> total bases: 0
#> Q20 bases: 0(nan%)
#> Q30 bases: 0(nan%)
#>
#> Filtering result:
#> reads passed filter: 0
#> reads failed due to low quality: 2290
#> reads failed due to too many N: 0
#> reads failed due to too short: 0
#> reads with adapter trimmed: 6
#> bases trimmed due to adapters: 102
#>
#> Duplication rate: 0%
#>
#> Insert size peak (evaluated by paired-end reads): 120
#>
#> JSON report: /Users/luciorq/workspaces/temp/align-condathis-targets/data/outputs/fastp_qc/subj21_fastp.json
#> HTML report: /Users/luciorq/workspaces/temp/align-condathis-targets/data/outputs/fastp_qc/subj21_fastp.html
#>
#> fastp -i /Users/luciorq/workspaces/temp/align-condathis-targets/data/raw/fastq/subj2_L001_R1_001.fastq.gz -I /Users/luciorq/workspaces/temp/align-condathis-targets/data/raw/fastq/subj2_L001_R2_001.fastq.gz -o /Users/luciorq/workspaces/temp/align-condathis-targets/data/outputs/trimmed/subj2_L001_R1_001_trimmed.fastq.gz -O /Users/luciorq/workspaces/temp/align-condathis-targets/data/outputs/trimmed/subj2_L001_R2_001_trimmed.fastq.gz -h /Users/luciorq/workspaces/temp/align-condathis-targets/data/outputs/fastp_qc/subj21_fastp.html -j /Users/luciorq/workspaces/temp/align-condathis-targets/data/outputs/fastp_qc/subj21_fastp.json
#> fastp v0.23.4, time used: 0 seconds
#> ✔ trimmed_fastq_qc completed [468ms, 936.66 kB]
#> + mapped_sams declared [2 branches]
#> ✔ mapped_sams completed [10.5s, 5.33 kB]
#> + bam_files declared [2 branches]
#> ✔ bam_files completed [255ms, 3.19 kB]
#> + sorted_bams declared [2 branches]
#> ✔ sorted_bams completed [426ms, 4.68 kB]
#> ✔ ended pipeline [1m 9.6s, 10 completed, 9 skipped]
```

Check output

``` r
sorted_bams_path <- targets::tar_read(sorted_bams)

bam_header <- condathis::run(
  "samtools", "view", "-H", sorted_bams_path[1],
  env_name = "samtools-env",
  verbose = "silent"
)

cat(bam_header$stdout)
#> @HD  VN:1.6  SO:coordinate
#> @SQ  SN:1    LN:249250621
#> @SQ  SN:2    LN:243199373
#> @SQ  SN:3    LN:198022430
#> @SQ  SN:4    LN:191154276
#> @SQ  SN:5    LN:180915260
#> @SQ  SN:6    LN:171115067
#> @SQ  SN:7    LN:159138663
#> @SQ  SN:8    LN:146364022
#> @SQ  SN:9    LN:141213431
#> @SQ  SN:10   LN:135534747
#> @SQ  SN:11   LN:135006516
#> @SQ  SN:12   LN:133851895
#> @SQ  SN:13   LN:115169878
#> @SQ  SN:14   LN:107349540
#> @SQ  SN:15   LN:102531392
#> @SQ  SN:16   LN:90354753
#> @SQ  SN:17   LN:81195210
#> @SQ  SN:18   LN:78077248
#> @SQ  SN:19   LN:59128983
#> @SQ  SN:20   LN:63025520
#> @SQ  SN:21   LN:48129895
#> @SQ  SN:22   LN:51304566
#> @SQ  SN:X    LN:155270560
#> @SQ  SN:Y    LN:59373566
#> @SQ  SN:MT   LN:16569
#> @SQ  SN:GL000207.1   LN:4262
#> @SQ  SN:GL000226.1   LN:15008
#> @SQ  SN:GL000229.1   LN:19913
#> @SQ  SN:GL000231.1   LN:27386
#> @SQ  SN:GL000210.1   LN:27682
#> @SQ  SN:GL000239.1   LN:33824
#> @SQ  SN:GL000235.1   LN:34474
#> @SQ  SN:GL000201.1   LN:36148
#> @SQ  SN:GL000247.1   LN:36422
#> @SQ  SN:GL000245.1   LN:36651
#> @SQ  SN:GL000197.1   LN:37175
#> @SQ  SN:GL000203.1   LN:37498
#> @SQ  SN:GL000246.1   LN:38154
#> @SQ  SN:GL000249.1   LN:38502
#> @SQ  SN:GL000196.1   LN:38914
#> @SQ  SN:GL000248.1   LN:39786
#> @SQ  SN:GL000244.1   LN:39929
#> @SQ  SN:GL000238.1   LN:39939
#> @SQ  SN:GL000202.1   LN:40103
#> @SQ  SN:GL000234.1   LN:40531
#> @SQ  SN:GL000232.1   LN:40652
#> @SQ  SN:GL000206.1   LN:41001
#> @SQ  SN:GL000240.1   LN:41933
#> @SQ  SN:GL000236.1   LN:41934
#> @SQ  SN:GL000241.1   LN:42152
#> @SQ  SN:GL000243.1   LN:43341
#> @SQ  SN:GL000242.1   LN:43523
#> @SQ  SN:GL000230.1   LN:43691
#> @SQ  SN:GL000237.1   LN:45867
#> @SQ  SN:GL000233.1   LN:45941
#> @SQ  SN:GL000204.1   LN:81310
#> @SQ  SN:GL000198.1   LN:90085
#> @SQ  SN:GL000208.1   LN:92689
#> @SQ  SN:GL000191.1   LN:106433
#> @SQ  SN:GL000227.1   LN:128374
#> @SQ  SN:GL000228.1   LN:129120
#> @SQ  SN:GL000214.1   LN:137718
#> @SQ  SN:GL000221.1   LN:155397
#> @SQ  SN:GL000209.1   LN:159169
#> @SQ  SN:GL000218.1   LN:161147
#> @SQ  SN:GL000220.1   LN:161802
#> @SQ  SN:GL000213.1   LN:164239
#> @SQ  SN:GL000211.1   LN:166566
#> @SQ  SN:GL000199.1   LN:169874
#> @SQ  SN:GL000217.1   LN:172149
#> @SQ  SN:GL000216.1   LN:172294
#> @SQ  SN:GL000215.1   LN:172545
#> @SQ  SN:GL000205.1   LN:174588
#> @SQ  SN:GL000219.1   LN:179198
#> @SQ  SN:GL000224.1   LN:179693
#> @SQ  SN:GL000223.1   LN:180455
#> @SQ  SN:GL000195.1   LN:182896
#> @SQ  SN:GL000212.1   LN:186858
#> @SQ  SN:GL000222.1   LN:186861
#> @SQ  SN:GL000200.1   LN:187035
#> @SQ  SN:GL000193.1   LN:189789
#> @SQ  SN:GL000194.1   LN:191469
#> @SQ  SN:GL000225.1   LN:211173
#> @SQ  SN:GL000192.1   LN:547496
#> @SQ  SN:NC_007605    LN:171823
#> @SQ  SN:hs37d5   LN:35477943
#> @PG  ID:minimap2 PN:minimap2 VN:2.30-r1287   CL:minimap2 -ax sr -t 2 /Users/luciorq/workspaces/temp/align-condathis-targets/data/outputs/reference/Homo_sapiens_assembly19_1000genomes_decoy.mmi /Users/luciorq/workspaces/temp/align-condathis-targets/data/outputs/trimmed/subj1_L001_R1_001_trimmed.fastq.gz /Users/luciorq/workspaces/temp/align-condathis-targets/data/outputs/trimmed/subj1_L001_R2_001_trimmed.fastq.gz
#> @PG  ID:samtools PN:samtools PP:minimap2 VN:1.22.1   CL:samtools view -hb -@ 2 /Users/luciorq/workspaces/temp/align-condathis-targets/data/outputs/aligned_sam/subj11.sam
#> @PG  ID:samtools.1   PN:samtools PP:samtools VN:1.22.1   CL:samtools sort -T /Users/luciorq/workspaces/temp/align-condathis-targets/data/tmp -@ 2 -o /Users/luciorq/workspaces/temp/align-condathis-targets/data/outputs/sorted_bams/sorted_subj11.bam /Users/luciorq/workspaces/temp/align-condathis-targets/data/outputs/bams/subj11.bam
#> @PG  ID:samtools.2   PN:samtools PP:samtools.1   VN:1.22.1   CL:samtools view -H /Users/luciorq/workspaces/temp/align-condathis-targets/data/outputs/sorted_bams/sorted_subj11.bam
```
