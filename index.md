# ELEC5305 Project — 540062964

**Topic:** Explore LUFS and Standards for Broadcast and Streaming Audio  
**Student:** Jianxiang Chen (SID: 540062964)  
**Repository:** https://github.com/cjx259-au/elec5305-project-540062964

---

## Data (GitHub Releases)

- **Full dataset (Release asset):**  
  **[Download `data.zip`](https://github.com/cjx259-au/elec5305-project-540062964/releases/tag/data)**

**Extract and place under the project folder so it looks like:**
elec5305-project-540062964/
data/
wav/ # or flac/
matlab/
results/
figures/

*(Optional) Verify integrity on Windows PowerShell)*
```powershell
Get-FileHash .\data.zip -Algorithm SHA256
cd matlab
run_project
Outputs

CSV: results/metrics.csv, results/compliance.csv, results/normalization.csv

Plots: figures/*.png
Results

metrics.csv

compliance.csv

normalization.csv

Plots




If a link shows 404, upload the file to the repo (Code → Add file → Upload files) and refresh after 1–3 minutes.

Method Summary

Standards checked:

EBU R128 (target −23 LUFS, True-Peak ≤ −1 dBTP)

ATSC A/85 (target −24 LKFS)

Pipeline:

Measure Integrated LUFS, Short-term/Momentary LUFS, LRA, True-Peak (dBTP).

Generate compliance table (targets above).

Simulate streaming normalization to −14 LUFS with a soft limiter if TP would exceed −1 dBTP.

Artifacts: CSV summaries in results/, figures in figures/.

How to Run Locally

Download the data from the Release and extract into data/.
run_project
Notes

Scripts rely on standard MATLAB toolboxes (Signal Processing, Audio, Statistics/ML).

No deep learning toolbox is required.

True-Peak ceiling used in the demo pipeline is −1 dBTP.

Streaming demo normalizes to −14 LUFS (teaching reference).
Open MATLAB, set the current folder to matlab/.

Run:
