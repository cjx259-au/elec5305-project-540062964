# ELEC5305 Audio Loudness & True-Peak Analysis System

[![MATLAB](https://img.shields.io/badge/MATLAB-R2018b+-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-Repository-blue.svg)](https://github.com/cjx259-au/elec5305-project-540062964)

**Repository**: [https://github.com/cjx259-au/elec5305-project-540062964](https://github.com/cjx259-au/elec5305-project-540062964)

A comprehensive MATLAB-based framework for ITU-R BS.1770/EBU R128 compliant loudness measurement, multi-platform compliance analysis, and codec distortion assessment.

Project Overview

**GitHub Repository**: [https://github.com/cjx259-au/elec5305-project-540062964](https://github.com/cjx259-au/elec5305-project-540062964)

This project implements a comprehensive audio loudness and true-peak analysis system compliant with ITU-R BS.1770-4 and EBU R128 standards. The system supports multi-platform compliance analysis (Apple Music, Spotify, YouTube, TikTok), dialogue-aware metrics, and codec distortion assessment.

### What This Project Does

This project addresses the critical problem of audio loudness normalization across different streaming platforms. Each platform (Apple Music, Spotify, YouTube, TikTok) has different loudness targets and processing algorithms, making it difficult for content creators to optimize their audio for all platforms simultaneously.

**Key Problems Solved:**
1. **Loudness Measurement**: Accurately measures audio loudness according to international standards (ITU-R BS.1770-4 / EBU R128)
2. **Multi-Platform Compliance**: Simulates how audio will sound on different streaming platforms after normalization
3. **True-Peak Safety**: Prevents inter-sample peaks that can cause clipping after digital-to-analog conversion
4. **Dialogue Intelligibility**: Analyzes speech content to ensure dialogue is not masked by background elements
5. **Codec Distortion**: Assesses how lossy audio codecs (AAC, Opus, OGG) affect audio quality

**Research Questions Addressed:**
- How can we accurately measure audio loudness according to ITU-R BS.1770/EBU R128 standards?
- How do different streaming platforms affect audio loudness and true-peak compliance?
- What are the spectral and dynamic range distortions introduced by lossy audio codecs?
- How sensitive are true-peak measurements to oversampling factors?
- Can we develop an adaptive normalization system that optimizes for both loudness targets and true-peak safety?

Key Features

### Core Features
ITU-R BS.1770-4 / EBU R128 Standard Loudness Measurement**
  - K-weighting filter implementation
  - Integrated Loudness (LUFS)
  - Loudness Range (LRA)
  - True-Peak measurement (dBTP)
  
Multi-Platform Compliance Analysis**
  - Apple Music (-16 LUFS)
  - Spotify (-14 LUFS)
  - YouTube (-14 LUFS)
  - TikTok (-16 LUFS)
  - Platform-specific normalization simulation
  - True-peak limiter analysis

Dialogue-Aware Metrics**
  - Voice Activity Detection (VAD)
  - Dialogue Loudness Difference (LD)
  - Dialogue risk assessment

### Advanced Features
    Codec Distortion Analysis** (requires FFmpeg)
  - AAC, Opus, OGG Vorbis encoding/decoding simulation
  - Spectral distortion analysis (centroid, spread, rolloff)
  - Dynamic range change analysis
  - True-peak overshoot measurement

- 📊 **True-Peak Sensitivity Analysis**
  - 4× vs 8× oversampling comparison
  - Borderline case identification

- 📈 **Visualization & Reporting**
  - Publication-quality figures (300 DPI PNG)
  - Comprehensive HTML reports
  - CSV data tables

Requirements

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

## 📦 Installation

### 1. Clone or Download the Project
```bash
git clone <repository-url>
cd matlab
```

### 2. Set Up Project Structure
Ensure the project directory structure is as follows:
```
project_root/
├── matlab/          # All .m files
├── data/
│   └── wav/        # Place WAV files here
├── results/         # Auto-created (output directory)
└── figures/         # Auto-created (figures directory)
```

### 3. Add MATLAB Path
Run in MATLAB:
```matlab
addpath(genpath('path/to/project_root/matlab'));
```

### 4. Download Audio Files
**Audio/video files are hosted on GitHub Releases** to keep the repository lightweight.

1. Go to [GitHub Releases](https://github.com/cjx259-au/elec5305-project-540062964/releases)
2. Download the data archive (e.g., `data.zip` or similar)
3. Extract the archive
4. Copy the WAV files to the `data/wav/` directory

The project structure should look like:
```
project_root/
├── matlab/
├── data/
│   └── wav/        # Place extracted WAV files here
├── results/
└── figures/
```

**Note**: If you don't have access to the data files, you can still run the project with your own WAV files by placing them in `data/wav/`.

### 5. (Optional) Install FFmpeg
For codec simulation features:
1. Download FFmpeg from https://ffmpeg.org/
2. Install and add to system PATH
3. Verify installation: `system('ffmpeg -version')`

Quick Start

### Prerequisites

**Download Audio Files**: Audio/video files are available in [GitHub Releases](https://github.com/cjx259-au/elec5305-project-540062964/releases). Download and extract the data archive to `data/wav/` directory.

### Basic Usage

Run the complete analysis pipeline:
```matlab
run_project()
```

This will:
1. Process all WAV files in `data/wav/`
2. Generate `metrics.csv` (per-file metrics)
3. Perform platform compliance analysis
4. Generate `compliance_platform.csv`
5. Generate platform summary statistics
6. Create HTML report
7. Generate visualizations
8. (Optional) Codec analysis (if FFmpeg available)

### Run All Experiments

Run the complete pipeline including all optional modules:
```matlab
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

Project Structure & File Descriptions

### Main Entry Points

**`config.m`**
- **Purpose**: Global configuration management
- **Function**: Returns configuration struct with all project parameters
- **Key Parameters**: File paths, processing parameters, platform configurations
- **Usage**: Called by all modules to get consistent configuration

**`run_project.m`**
- **Purpose**: Main analysis pipeline - one-click processing
- **Function**: Orchestrates the complete analysis workflow
- **Process**: 
  1. Processes all WAV files in `data/wav/`
  2. Measures loudness and dialogue metrics
  3. Performs platform compliance analysis
  4. Generates reports and visualizations
- **Output**: `metrics.csv`, `compliance_platform.csv`, HTML report, figures

**`run_all_experiments.m`**
- **Purpose**: Complete experimental pipeline with all optional modules
- **Function**: Runs full analysis including codec simulation and advanced features
- **Includes**: All features from `run_project()` plus optional modules

### Core Processing Modules

**`measure_loudness.m`**
- **Purpose**: ITU-R BS.1770-4 / EBU R128 compliant loudness measurement
- **Algorithm**: 
  - Applies K-weighting filter (pre-filter + RLB)
  - Calculates block-based RMS (400ms blocks, 100ms hop)
  - Implements gating mechanism
- **Output**: Integrated LUFS, LRA, short-term LUFS, momentary LUFS, true-peak dBTP
- **Key Function**: `bs1770_filter()` - Implements K-weighting filter

**`truepeak_ref.m`**
- **Purpose**: High-precision true-peak measurement
- **Algorithm**: 
  - Upsamples signal (4× or 8× oversampling)
  - Applies anti-aliasing filter
  - Finds maximum absolute value
- **Output**: True-peak in dBTP
- **Features**: Memory-safe chunked processing for long audio files

**`dialogue_metrics.m`**
- **Purpose**: Dialogue-aware loudness analysis
- **Function**: 
  - Calls `dialogue_VAD()` for speech detection
  - Calculates speech-only loudness
  - Computes Dialogue Loudness Difference (LD)
  - Flags risky content (LD > 6 LU)
- **Output**: Speech ratio, speech LUFS, LD, risk flags
- **Fallback**: Energy-based VAD if advanced VAD fails

**`dialogue_VAD.m`**
- **Purpose**: Voice Activity Detection (VAD)
- **Methods**: 
  1. Energy-based VAD (frame-level energy thresholding)
  2. Mini-SAD (Spectral Activity Detection)
  3. WebRTC VAD (if available)
- **Features**: 3-second temporal smoothing to reduce false positives
- **Output**: Sample-level boolean mask indicating speech regions

**`normalize_streaming.m`**
- **Purpose**: Simulates platform loudness normalization
- **Algorithm**:
  1. Calculates gain: `gain_dB = targetLUFS - preLUFS`
  2. Applies gain to audio signal
  3. Checks true-peak safety
  4. Applies adaptive limiter if needed (3ms attack, 50ms release)
- **Output**: Normalized audio, post-LUFS, post-TP, limiter statistics
- **Used by**: `compliance_platform.m`, codec analysis modules

### Platform Analysis Modules

**`platform_presets.m`**
- **Purpose**: Defines platform-specific loudness policies
- **Platforms**: Apple Music, Spotify, YouTube, TikTok
- **Fields**: targetLUFS, tpLimit, enableBoost, codecs, DRC, eqHF_dB
- **Usage**: Called by `config.m` to set up platform configurations

**`compliance_platform.m`**
- **Purpose**: Platform compliance analysis for all files
- **Process**:
  1. Reads `metrics.csv` (per-file loudness metrics)
  2. For each file and platform:
     - Simulates normalization using `normalize_streaming()`
     - Checks true-peak compliance
     - Records limiter activation
  3. Generates `compliance_platform.csv`
- **Output**: Per-file × platform compliance results

**`make_dashboard_tables.m`**
- **Purpose**: Aggregates platform compliance statistics
- **Process**: Reads `compliance_platform.csv` and calculates summary statistics
- **Output**: `summary_platform.csv` with mean LUFS/TP, limiter activation rates, compliance rates per platform

**`apply_platform_playback.m` / `simulate_platform.m`**
- **Purpose**: Simulates complete platform playback chain
- **Process**: Normalization → Codec encoding → Decoding → Analysis
- **Output**: Complete listening chain metrics

### Codec Simulation Modules

**`analyze_codec_distortion.m`**
- **Purpose**: Comprehensive codec distortion analysis
- **Requires**: FFmpeg installed and in PATH
- **Process**:
  1. Normalizes audio to platform target
  2. Encodes using FFmpeg (AAC, Opus, OGG Vorbis)
  3. Decodes back to PCM
  4. Measures spectral distortion (centroid, spread, rolloff, SNR)
  5. Measures dynamic range changes (LRA, dynamic range, crest factor)
- **Output**: 
  - `codec_spectral_distortion.csv`
  - `codec_dynamics_profile.csv`
  - `platform_normalization.csv`

**`simulate_codec_chain.m`**
- **Purpose**: Codec-induced true-peak overshoot analysis
- **Process**: Measures true-peak before and after codec encoding/decoding
- **Output**: `codec_overshoot.csv` with overshoot measurements

**`simulate_platform_listening.m`**
- **Purpose**: Complete listening chain simulation
- **Process**: Normalization → Codec → Post-codec analysis
- **Output**: `platform_listening.csv` with metrics at each stage

### Advanced Analysis Modules

**`analyze_truepeak_sensitivity.m`**
- **Purpose**: True-peak measurement sensitivity analysis
- **Process**: 
  - Measures TP with 4× and 8× oversampling
  - Compares results to identify flip-cases
  - Flags borderline files (close to -1.0 dBTP limit)
- **Output**: `tp_sensitivity.csv` with comparison results

**`adaptive_mastering_profiles.m`**
- **Purpose**: Adaptive normalization profiles for different content types
- **Process**: Analyzes content characteristics and suggests optimal normalization
- **Output**: `adaptive_mastering.csv` with recommended settings

**`optimize_gain_tp_safe.m`**
- **Purpose**: True-peak safe gain optimization
- **Function**: Finds maximum gain that doesn't exceed true-peak limit
- **Algorithm**: Iterative optimization considering both loudness target and TP constraint

**`adaptive_normalizer.m`**
- **Purpose**: Advanced adaptive normalization with configurable parameters
- **Features**: Configurable attack/release, look-ahead, multiple limiter types

### Visualization Module

**`plot_helpers.m`**
- **Purpose**: Generates all publication-quality figures
- **Available Plots**:
  - `hist_LRA`: Loudness Range distribution histogram
  - `scatter_deltalu_tp`: Gain vs True-Peak scatter plot
  - `platform_compliance`: Platform compliance comparison (bar charts)
  - `loudness_distribution`: Integrated loudness distribution with normal overlay
  - `truepeak_analysis`: Comprehensive TP analysis (distribution, box plot, statistics)
  - `dialogue_metrics`: Multi-panel dialogue metrics visualization
  - `codec_spectral`: Codec spectral distortion analysis
  - `codec_dynamics`: Short-term dynamics profile
  - `normalization_simulation`: Platform normalization simulation results
- **Output**: PNG files (300 DPI) in `figures/` directory
- **Usage**: `plot_helpers('all', cfg)` to generate all plots

### Reporting Modules

**`export_html_report.m`**
- **Purpose**: Generates comprehensive HTML report
- **Content**:
  - Executive summary with key statistics
  - Complete data tables (collapsible sections)
  - All visualizations with descriptions
  - File links for easy data access
- **Output**: `results/report.html`
- **Features**: Modern responsive design, collapsible sections, embedded figures

**`compliance_report.m`**
- **Purpose**: Generates text-based compliance report
- **Output**: `compliance_report.txt` with summary statistics

**`summarize_for_writeup.m`**
- **Purpose**: Generates summary statistics for writeup/documentation
- **Output**: `summary.txt` with key findings

### Utility Modules

**`force_write_table.m`**
- **Purpose**: Robust CSV file writing with error handling
- **Features**: 
  - Handles read-only files
  - Retries with exponential backoff
  - Prevents data loss
- **Usage**: All modules use this for CSV writing

**`row_metrics.m`**
- **Purpose**: Creates table row for per-file metrics
- **Input**: Filename, loudness metrics struct, true-peak value
- **Output**: Table row for `metrics.csv`

**`row_comp.m`**
- **Purpose**: Creates table row for compliance results
- **Input**: Filename, compliance struct
- **Output**: Table row for `compliance_platform.csv`

**`isFFmpegAvailable.m`**
- **Purpose**: Checks if FFmpeg is installed and accessible
- **Function**: Tests FFmpeg availability via system command
- **Usage**: Codec modules check this before running

**`verify_connections.m`**
- **Purpose**: Verifies all modules are properly connected
- **Function**: Checks function availability and dependencies
- **Usage**: Diagnostic tool to ensure system integrity

### Helper Functions

**`pickField.m`**, **`getfield_safe.m`**
- **Purpose**: Safe field access from structs with defaults
- **Usage**: Prevents errors when accessing optional fields

**`truepeak_fast_predict.m`**
- **Purpose**: Fast true-peak estimation (alternative to full oversampling)
- **Algorithm**: Uses spectral features and crest factor for estimation

**`truepeak_limiter.m`**
- **Purpose**: Standalone true-peak limiter implementation
- **Features**: Configurable attack/release, gain reduction tracking

### Testing & Diagnostic Modules

**`test_functions.m`**
- **Purpose**: Unit tests for core functions
- **Usage**: Validates function correctness

**`final_code_check.m`**
- **Purpose**: Final code validation before submission
- **Function**: Checks for common errors and issues

**`diagnose_csv_issue.m`**
- **Purpose**: Diagnoses CSV file writing issues
- **Usage**: Troubleshooting tool

**`validate_against_external.m`**
- **Purpose**: Validates results against external reference data
- **Usage**: Comparison with known-good measurements

Output Files

### CSV Data Files
All CSV files are saved in the `results/` directory:

- **metrics.csv**: Per-file loudness and dialogue metrics
  - Integrated loudness, LRA, true-peak
  - Speech loudness, speech ratio, dialogue difference

- **compliance_platform.csv**: Per-file × platform compliance results
  - Pre/post-normalization LUFS and TP
  - Applied gain, limiter activation
  - Compliance flags

- **summary_platform.csv**: Aggregated statistics by platform
  - Mean post-normalization LUFS/TP
  - Limiter activation rate
  - Compliance rate

- **codec_*.csv**: Codec analysis results (if FFmpeg available)
  - `codec_overshoot.csv`: Codec-induced TP overshoot
  - `codec_spectral_distortion.csv`: Spectral distortion
  - `codec_dynamics_profile.csv`: Dynamic range changes
  - `platform_listening.csv`: Complete listening chain simulation

### Visualizations
All figures are saved as PNG (300 DPI) in the `figures/` directory:
- LRA distribution histogram
- Gain vs True-Peak scatter plot
- Platform compliance comparison
- Loudness distribution
- True-peak analysis
- Dialogue metrics visualization
- Codec distortion analysis

### HTML Report
`results/report.html` contains:
- Executive summary
- Complete data tables (collapsible sections)
- All visualization figures
- File links

Configuration

All parameters are configured via `config.m`:

```matlab
cfg = config();

% Path configuration
cfg.dataDir    = 'data/wav';      % WAV file directory
cfg.resultsDir = 'results';        % Results output directory
cfg.figDir     = 'figures';        % Figures output directory

% Processing parameters
cfg.truePeakOversample = 4;        % True-peak oversampling (EBU recommended 4×)
cfg.tpCeil            = -1.0;      % True-peak ceiling (dBTP)
cfg.loudnessBlockMs   = 400;       % Loudness block size (ms)
cfg.loudnessHopMs     = 100;       % Loudness hop size (ms)
cfg.limiterAttackMs   = 3.0;       % Limiter attack time (ms)
cfg.limiterReleaseMs  = 50.0;      % Limiter release time (ms)

% Platform configuration
cfg.platforms = [
    platform_presets("AppleMusic")
    platform_presets("Spotify")
    platform_presets("YouTube")
    platform_presets("TikTok")
];
```

Feature Details

### Loudness Measurement
- Implements ITU-R BS.1770-4 K-weighting filter
- 400ms blocks, 100ms hop (EBU R128 standard)
- Gating mechanism (removes blocks below -70 LUFS)
- Integrated, short-term, and momentary loudness

### Platform Normalization
- Simulates platform-specific normalization algorithms
- True-peak safe gain optimization
- Adaptive limiter (3ms attack, 50ms release)
- Supports both gain boost and attenuation

### Dialogue Analysis
- Multiple VAD methods (energy, spectral, WebRTC)
- 3-second temporal smoothing
- Dialogue Loudness Difference (LD) calculation
- Risk flagging (LD > 6 LU)

### Codec Analysis
- Real encoding/decoding using FFmpeg
- Spectral feature analysis (centroid, spread, rolloff)
- Signal-to-Noise Ratio (SNR) calculation
- Short-term dynamic range analysis
- True-peak overshoot detection

 Methodology: How It Works

### 1. Audio Preprocessing Pipeline

**Input**: WAV audio files (any sample rate, mono or stereo)

**Processing Steps**:
1. **Mono Conversion**: Multi-channel audio is converted to mono using sum of squares (BS.1770 standard)
2. **DC Removal**: Removes DC offset to prevent measurement errors
3. **Resampling**: Audio is resampled to 48 kHz if needed (standard for broadcast/streaming)

### 2. Loudness Measurement Algorithm

**Implementation**: `measure_loudness.m`

**Algorithm Flow**:
```
Audio Signal
    ↓
1. K-weighting Filter (BS.1770)
   - Pre-filter: High-shelf at 1.7 kHz
   - RLB (Revised Low-frequency B-curve): Low-shelf at 38 Hz
    ↓
2. Block-based RMS Calculation
   - Block size: 400 ms (EBU R128 standard)
   - Hop size: 100 ms
   - RMS = sqrt(mean(filtered_signal^2))
    ↓
3. Gating Mechanism
   - Calculate ungated loudness
   - Remove blocks below (ungated - 70 LUFS)
   - Recalculate integrated loudness
    ↓
4. Output Metrics
   - Integrated Loudness (LUFS)
   - Loudness Range (LRA)
   - Short-term Loudness (3-second windows)
   - Momentary Loudness (400ms windows)
```

**True-Peak Measurement** (`truepeak_ref.m`):
1. Upsample signal by 4× (EBU recommended) or 8× (higher precision)
2. Apply anti-aliasing filter
3. Find maximum absolute sample value
4. Convert to dBTP: `TP_dBTP = 20×log₁₀(max(|x_upsampled|))`

### 3. Dialogue-Aware Analysis

**Implementation**: `dialogue_metrics.m` → `dialogue_VAD.m`

**Voice Activity Detection (VAD) Methods**:
1. **Energy-based VAD**: Frame-level energy thresholding (10ms frames)
2. **Spectral Activity Detection (Mini-SAD)**: Spectral centroid-based detection
3. **WebRTC VAD** (if available): Industry-standard VAD algorithm
4. **Temporal Smoothing**: 3-second smoothing window to reduce false positives

**Dialogue Metrics Calculation**:
- **Speech Ratio**: Percentage of audio containing speech
- **Speech-only LUFS**: Loudness of speech segments only
- **Dialogue Loudness Difference (LD)**: `LD = IntegratedLUFS - SpeechLUFS`
- **Risk Assessment**: Flags content where `LD > 6 LU` (potential masking)

### 4. Platform Normalization Simulation

**Implementation**: `normalize_streaming.m`

**Algorithm**:
```
1. Calculate Gain
   gain_dB = targetLUFS - preLUFS

2. Apply Gain
   y = x × 10^(gain_dB/20)

3. True-Peak Safety Check
   If (preTP + gain_dB) > tpLimit:
       Apply adaptive limiter
   Else:
       No limiting needed

4. Adaptive Limiter (if needed)
   - Attack time: 3 ms (fast enough to catch peaks)
   - Release time: 50 ms (smooth recovery)
   - Gain reduction: GR = min(1, tpLimit / peak)

5. Post-processing Metrics
   - Measure post-normalization LUFS
   - Measure post-normalization TP
   - Record limiter statistics
```

**Platform Configurations** (`platform_presets.m`):
- **Apple Music**: -16 LUFS target, -1.0 dBTP limit, boost allowed
- **Spotify**: -14 LUFS target, -1.0 dBTP limit, boost allowed
- **YouTube**: -14 LUFS target, -1.0 dBTP limit, attenuation only
- **TikTok**: -16 LUFS target, -1.0 dBTP limit, boost allowed

### 5. Codec Distortion Analysis

**Implementation**: `analyze_codec_distortion.m` (requires FFmpeg)

**Process**:
```
1. Normalize audio to platform target
   normalize_streaming() → normalized_audio

2. Encode using FFmpeg
   ffmpeg -i input.wav -c:a codec -b:a bitrate encoded.ogg

3. Decode back to PCM
   ffmpeg -i encoded.ogg decoded.wav

4. Measure Distortion
   a. Spectral Features:
      - Spectral Centroid (brightness)
      - Spectral Spread (bandwidth)
      - Spectral Rolloff (high-frequency content)
      - SNR (Signal-to-Noise Ratio)
   
   b. Dynamic Range:
      - Short-term LRA (Loudness Range)
      - Dynamic Range (peak-to-RMS ratio)
      - Crest Factor (peak-to-RMS in dB)
   
   c. True-Peak Overshoot:
      - Measure TP before and after codec
      - Calculate overshoot = postTP - preTP
```

### 6. Complete Processing Workflow

**Main Pipeline** (`run_project.m`):

```
For each WAV file:
    ↓
1. measure_loudness()
   → Integrated LUFS, LRA, TP
    ↓
2. dialogue_metrics()
   → dialogue_VAD()
   → Speech ratio, LD, risk flags
    ↓
3. row_metrics()
   → Create table row
    ↓
4. Write metrics.csv
    ↓
5. compliance_platform()
   For each platform:
      normalize_streaming()
      → Post-LUFS, Post-TP, limiter stats
    ↓
6. Write compliance_platform.csv
    ↓
7. make_dashboard_tables()
   → Aggregate statistics by platform
    ↓
8. Write summary_platform.csv
    ↓
9. (Optional) Codec analysis
   analyze_codec_distortion()
   → Spectral/distortion metrics
    ↓
10. plot_helpers()
    → Generate all visualizations
    ↓
11. export_html_report()
    → Comprehensive HTML report
```

Troubleshooting

### Common Issues

**Issue**: "No WAV files found"
- **Solution**: Check that WAV files are in the `data/wav/` directory
- Verify path in `config.m` or check `cfg.dataDir`

**Issue**: "FFmpeg not found" warnings
- **Solution**: Install FFmpeg and add to PATH, or ignore (codec features are optional)

**Issue**: CSV files are empty or read-only
- **Solution**: Close files in Excel/other programs, or use `force_write_table` (already implemented)

**Issue**: "Function not found" errors
- **Solution**: Ensure all .m files are in MATLAB path
- Run `verify_connections()` to check module availability

**Issue**: Out of memory errors
- **Solution**: Process files in smaller batches
- Reduce `K` parameter in codec analysis functions

Documentation

- **Complete Documentation**: See `ELEC5305_Project_Documentation.md`
- **Workflow**: See `COMPLETE_WORKFLOW.md`
- **Module Connections**: See `MODULE_CONNECTIONS.md`
- **Parameter Optimization**: See `PARAMETERS_OPTIMIZED.md`

 Validation

The system has been validated for:
- ✅ ITU-R BS.1770-4 standard compliance
- ✅ EBU R128 standard compliance
- ✅ Multi-platform normalization simulation
- ✅ Real-world audio content testing

Citation

If this project is helpful for your research, please cite:

```
ELEC5305 Audio Loudness & True-Peak Analysis System
A MATLAB-based framework for ITU-R BS.1770/EBU R128 compliant 
loudness measurement and multi-platform compliance analysis.

GitHub: https://github.com/cjx259-au/elec5305-project-540062964
```
License

This project is licensed under the MIT License. See LICENSE file for details.

contributing

Contributions are welcome! Please feel free to submit Issues and Pull Requests.

 Author

ELEC5305 Project

 Acknowledgments

- ITU-R BS.1770-4 standard
- EBU R128 recommendation
- FFmpeg project (for codec simulation)

---

**Note**: This project is an academic research project for ELEC5305 course. Platform normalization algorithms are simulated based on public documentation, actual platform implementations may differ.
