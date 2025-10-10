# ELEC5305 Project — 540062964

**Topic:** Explore LUFS and Standards for Broadcast and Streaming Audio  
**Student:** Jianxiang Chen (SID: 540062964)  
**Repository:** https://github.com/cjx259-au/elec5305-project-540062964  
**GitHub Pages:** https://cjx259-au.github.io/elec5305-project-540062964

---

## 1) Overview
This project measures programme loudness and true-peak for broadcast/streaming audio and checks compliance with:
- **EBU R128** (target −23 LUFS, **True-Peak ≤ −1 dBTP**)
- **ATSC A/85** (target −24 LKFS)

It also simulates streaming normalization to **−14 LUFS**, reporting required gains and whether a soft limiter must engage to keep true-peak under −1 dBTP.

**Key metrics:** Integrated LUFS, Loudness Range (LRA), True-Peak (dBTP), suggested gains, compliance flags.

---

## 2) Quick Start
```matlab
cd matlab
run_project
Outputs

CSV: results/metrics.csv, results/compliance.csv, results/normalization.csv

Plots: figures/*.png (LUFS timelines, LRA histogram, ΔLU vs dBTP)

You can also browse results on the project website (GitHub Pages):
https://cjx259-au.github.io/elec5305-project-540062964

3) Data

To keep the repository lightweight, raw audio is hosted on GitHub Releases.

Download full data:
https://github.com/cjx259-au/elec5305-project-540062964/releases/tag/data

After extracting the archive, the project should look like:
elec5305-project-540062964/
  data/
    wav/            # or flac/
  matlab/
  results/
  figures/
Get-FileHash .\data.zip -Algorithm SHA256
matlab/                         % MATLAB scripts
  run_project.m
  config.m
  measure_loudness.m
  truepeak_dbTP.m
  normalize_streaming.m
  compliance_report.m
  plot_helpers.m
data/
  wav/                          % place extracted audio here
results/                        % auto-generated CSVs
figures/                        % auto-generated plots
README.md
index.md
ELEC5305_Proposal_540062964.pdf
5) Reproduce Exactly

Download and extract data.zip into data/.

Open MATLAB and set the current folder to matlab/.

Run:run_project
Inspect results/*.csv and figures/*.png.
If you want these artifacts visible on the website, upload the CSV/PNG files to the repo (already configured).

6) Notes

EBU R128: −23 LUFS, True-Peak ≤ −1 dBTP

ATSC A/85: −24 LKFS

Streaming demo: normalization to −14 LUFS; a soft limiter is applied if the predicted true-peak would exceed −1 dBTP.

Scripts rely on standard MATLAB toolboxes (Signal Processing, Audio, Statistics/ML). No deep learning toolbox is required.

7) Acknowledgements

This repository is for ELEC5305 coursework. Audio data are distributed via Release assets for reproducibility; please respect dataset licenses and terms of use.
::contentReference[oaicite:0]{index=0}


