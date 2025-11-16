---
layout: default
title: ELEC5305 Audio Loudness & True-Peak Analysis System
---

# ELEC5305 Audio Loudness & True-Peak Analysis System

<div align="center">

[![MATLAB](https://img.shields.io/badge/MATLAB-R2018b+-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-Repository-blue.svg)](https://github.com/cjx259-au/elec5305-project-540062964)
[![GitHub Releases](https://img.shields.io/badge/Releases-Data%20Files-orange.svg)](https://github.com/cjx259-au/elec5305-project-540062964/releases)

**A comprehensive MATLAB-based framework for ITU-R BS.1770/EBU R128 compliant loudness measurement, multi-platform compliance analysis, and codec distortion assessment.**

[GitHub Repository](https://github.com/cjx259-au/elec5305-project-540062964) • [Documentation](ELEC5305_Project_Documentation.md) • [Quick Start](#quick-start)

</div>

---

## Project Overview

This project implements a comprehensive audio loudness and true-peak analysis system compliant with **ITU-R BS.1770-4** and **EBU R128** standards. The system supports multi-platform compliance analysis (Apple Music, Spotify, YouTube, TikTok), dialogue-aware metrics, and codec distortion assessment.

### What This Project Does

This project addresses the critical problem of audio loudness normalization across different streaming platforms. Each platform has different loudness targets and processing algorithms, making it difficult for content creators to optimize their audio for all platforms simultaneously.

**Key Problems Solved:**
1. **Loudness Measurement**: Accurately measures audio loudness according to international standards (ITU-R BS.1770-4 / EBU R128)
2. **Multi-Platform Compliance**: Simulates how audio will sound on different streaming platforms after normalization
3. **True-Peak Safety**: Prevents inter-sample peaks that can cause clipping after digital-to-analog conversion
4. **Dialogue Intelligibility**: Analyzes speech content to ensure dialogue is not masked by background elements
5. **Codec Distortion**: Assesses how lossy audio codecs (AAC, Opus, OGG) affect audio quality

---

## Key Features

### Core Features

| Feature | Description |
|---------|-------------|
| **ITU-R BS.1770-4 / EBU R128 Compliance** | Standard-compliant loudness measurement with K-weighting filter |
| **Multi-Platform Analysis** | Apple Music (-16 LUFS), Spotify (-14 LUFS), YouTube (-14 LUFS), TikTok (-16 LUFS) |
| **True-Peak Measurement** | 4× or 8× oversampling for accurate inter-sample peak detection |
| **Dialogue-Aware Metrics** | Voice Activity Detection (VAD) and Dialogue Loudness Difference (LD) |
| **Codec Distortion Analysis** | Spectral and dynamic range analysis for AAC, Opus, OGG Vorbis |

### Advanced Features

- **True-Peak Sensitivity Analysis**: Comparison of 4× vs 8× oversampling
- **Adaptive Normalization**: True-peak safe gain optimization
- **Comprehensive Reporting**: HTML reports with embedded visualizations
- **Publication-Quality Figures**: 300 DPI PNG outputs

---

## Quick Start

### Prerequisites

- **MATLAB** R2018b or later (R2020a+ recommended)
- **Signal Processing Toolbox**
- **FFmpeg** (optional, for codec simulation)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/cjx259-au/elec5305-project-540062964.git
   cd elec5305-project-540062964/matlab
   ```

2. **Download audio data**
   - Audio files are available in [GitHub Releases](https://github.com/cjx259-au/elec5305-project-540062964/releases)
   - Download and extract to `data/wav/` directory

3. **Add MATLAB path**
   ```matlab
   addpath(genpath('path/to/project_root/matlab'));
   ```

4. **Run the project**
   ```matlab
   run_project()
   ```

### Output Files

After running, you'll find:
- **CSV Data**: `results/metrics.csv`, `results/compliance_platform.csv`
- **HTML Report**: `results/report.html`
- **Figures**: `figures/*.png` (publication-quality visualizations)

---

## Results & Outputs

### Generated Data Files

The system generates comprehensive analysis results:

- **`metrics.csv`**: Per-file loudness and dialogue metrics
  - Integrated loudness (LUFS), LRA, true-peak (dBTP)
  - Speech loudness, speech ratio, dialogue difference

- **`compliance_platform.csv`**: Per-file × platform compliance results
  - Pre/post-normalization LUFS and TP
  - Applied gain, limiter activation, compliance flags

- **`summary_platform.csv`**: Aggregated statistics by platform
  - Mean post-normalization LUFS/TP
  - Limiter activation rates, compliance rates

### Visualizations

The system generates publication-quality figures (300 DPI PNG):
- Loudness Range (LRA) distribution
- Gain vs True-Peak scatter plots
- Platform compliance comparisons
- True-peak analysis
- Dialogue metrics visualization
- Codec distortion analysis

### HTML Report

A comprehensive HTML report (`results/report.html`) includes:
- Executive summary with key statistics
- Complete data tables (collapsible sections)
- All visualizations with descriptions
- Direct links to CSV files

---

## Methodology

### Processing Pipeline

```
WAV Files → Preprocessing → Loudness Measurement → Dialogue Analysis
    ↓
Platform Compliance Analysis → Codec Simulation (optional) → Reporting
```

### Key Algorithms

1. **K-weighting Filter** (BS.1770)
   - Pre-filter: High-shelf at 1.7 kHz
   - RLB: Low-shelf at 38 Hz
   - Block-based RMS (400ms blocks, 100ms hop)
   - Gating mechanism

2. **True-Peak Measurement**
   - 4× or 8× oversampling
   - Anti-aliasing filter
   - Maximum absolute value detection

3. **Platform Normalization**
   - Gain calculation: `gain_dB = targetLUFS - preLUFS`
   - True-peak safety check
   - Adaptive limiter (3ms attack, 50ms release)

4. **Dialogue Analysis**
   - Multiple VAD methods (energy, spectral, WebRTC)
   - Dialogue Loudness Difference (LD) calculation
   - Risk assessment (LD > 6 LU)

---

## Project Structure

```
elec5305-project-540062964/
├── matlab/                    # All MATLAB source code
│   ├── config.m              # Global configuration
│   ├── run_project.m         # Main entry point
│   ├── measure_loudness.m    # BS.1770 loudness measurement
│   ├── dialogue_metrics.m    # Dialogue-aware analysis
│   ├── compliance_platform.m # Platform compliance
│   └── ...                   # 40+ additional modules
├── data/
│   └── wav/                  # Audio files (download from Releases)
├── results/                   # Generated outputs
│   ├── metrics.csv
│   ├── compliance_platform.csv
│   ├── report.html
│   └── figures/
├── README.md                  # Main documentation
├── ELEC5305_Project_Documentation.md
└── index.md                   # This file (GitHub Pages)
```

---

## Documentation

### Main Documentation Files

- **[README.md](README.md)**: Complete project documentation
- **[ELEC5305_Project_Documentation.md](ELEC5305_Project_Documentation.md)**: Detailed technical documentation
- **[COMPLETE_WORKFLOW.md](COMPLETE_WORKFLOW.md)**: Workflow and data flow diagrams
- **[MODULE_CONNECTIONS.md](MODULE_CONNECTIONS.md)**: Module dependency graph
- **[PARAMETERS_OPTIMIZED.md](PARAMETERS_OPTIMIZED.md)**: Parameter optimization guide
- **[GITHUB_SUBMISSION_GUIDE.md](GITHUB_SUBMISSION_GUIDE.md)**: GitHub submission instructions

### Key Modules

| Module | Purpose |
|--------|---------|
| `measure_loudness.m` | ITU-R BS.1770-4 compliant loudness measurement |
| `truepeak_ref.m` | High-precision true-peak measurement |
| `dialogue_metrics.m` | Dialogue-aware loudness analysis |
| `normalize_streaming.m` | Platform normalization simulation |
| `compliance_platform.m` | Multi-platform compliance checking |
| `analyze_codec_distortion.m` | Codec distortion analysis (requires FFmpeg) |
| `plot_helpers.m` | Publication-quality figure generation |
| `export_html_report.m` | Comprehensive HTML report generation |

---

## Research Questions Addressed

1. **How can we accurately measure audio loudness according to ITU-R BS.1770/EBU R128 standards?**
   - Implemented K-weighting filter and gating mechanism
   - Accurate true-peak measurement with configurable oversampling
   - Integration of dialogue-aware metrics

2. **How do different streaming platforms affect audio loudness and true-peak compliance?**
   - Platform-specific loudness targets analysis
   - Platform-specific true-peak limits
   - Normalization algorithm differences

3. **What are the spectral and dynamic range distortions introduced by lossy audio codecs?**
   - Spectral centroid, spread, and rolloff changes
   - Short-term loudness range (LRA) modifications
   - Dynamic range and crest factor alterations
   - Codec-induced true-peak overshoot

4. **How sensitive are true-peak measurements to oversampling factors?**
   - Comparison of 4× vs 8× oversampling
   - Identification of borderline cases and flip-cases

5. **Can we develop an adaptive normalization system that optimizes for both loudness targets and true-peak safety?**
   - True-peak safe gain optimization
   - Adaptive limiter with configurable attack/release

---

## System Requirements

### Required Software
- **MATLAB**: R2018b or later (R2020a+ recommended)
- **Signal Processing Toolbox**: For signal processing functions

### Optional Software
- **FFmpeg**: Version 4.0 or later (for codec simulation)
  - Download: https://ffmpeg.org/
  - Must be added to system PATH

### Hardware Requirements
- **RAM**: Minimum 4 GB, 8 GB or more recommended
- **Storage**: Sufficient space for input WAV files and output results

---

## Data Files

**Audio/video files are hosted on GitHub Releases** to keep the repository lightweight.

- **Download**: [GitHub Releases](https://github.com/cjx259-au/elec5305-project-540062964/releases)
- **Extract to**: `data/wav/` directory
- **Note**: You can also use your own WAV files by placing them in `data/wav/`

---

## Configuration

All parameters are configured via `config.m`:

```matlab
cfg = config();

% Processing parameters
cfg.truePeakOversample = 4;        % True-peak oversampling (EBU recommended 4×)
cfg.tpCeil            = -1.0;     % True-peak ceiling (dBTP)
cfg.loudnessBlockMs   = 400;      % Loudness block size (ms)
cfg.loudnessHopMs     = 100;      % Loudness hop size (ms)
cfg.limiterAttackMs   = 3.0;     % Limiter attack time (ms)
cfg.limiterReleaseMs  = 50.0;     % Limiter release time (ms)
```

---

## Usage Examples

### Basic Usage

```matlab
% Run complete analysis pipeline
run_project()
```

### Run All Experiments

```matlab
% Run full pipeline including optional modules
run_all_experiments()
```

### Custom Configuration

```matlab
cfg = config();
cfg.truePeakOversample = 8;      % Use 8× oversampling
cfg.streamTargetLUFS = -16;      % Set default target loudness
run_project(cfg);
```

### Run Specific Modules

```matlab
cfg = config();

% Platform compliance analysis
compliance_platform(cfg);

% Codec distortion analysis (requires FFmpeg)
analyze_codec_distortion(cfg, 10);

% True-peak sensitivity analysis
analyze_truepeak_sensitivity(cfg);

% Generate plots
plot_helpers('all', cfg);

% Export HTML report
export_html_report(cfg);
```

---

## Validation

The system has been validated for:
- ITU-R BS.1770-4 standard compliance
- EBU R128 standard compliance
- Multi-platform normalization simulation
- Real-world audio content testing

---

## License

This project is licensed under the MIT License. See LICENSE file for details.

---

## Author

**Jianxiang Chen (SID: 540062964)**

ELEC5305 Project - Audio Loudness & True-Peak Analysis System

---

## Acknowledgments

- **ITU-R BS.1770-4** standard
- **EBU R128** recommendation
- **FFmpeg** project (for codec simulation)

---

## Links

- **GitHub Repository**: [https://github.com/cjx259-au/elec5305-project-540062964](https://github.com/cjx259-au/elec5305-project-540062964)
- **GitHub Releases**: [Download Data Files](https://github.com/cjx259-au/elec5305-project-540062964/releases)
- **Documentation**: [Complete Documentation](ELEC5305_Project_Documentation.md)
- **Quick Start Guide**: [README.md](README.md)

---

<div align="center">

**Note**: This project is an academic research project for ELEC5305 course. Platform normalization algorithms are simulated based on public documentation, actual platform implementations may differ.

</div>

