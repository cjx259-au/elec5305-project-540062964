# ELEC5305 Project: Comprehensive Audio Loudness and True-Peak Analysis System

**A MATLAB-based Framework for ITU-R BS.1770/EBU R128 Compliant Loudness Measurement, Platform Compliance Analysis, and Codec Distortion Assessment**

---

# 1. Literature Review

## 1.1 Audio Loudness Standards

The project implements and extends the ITU-R BS.1770-4 standard [1] and EBU R128 recommendation [2], which have become the de facto standards for broadcast and streaming audio loudness measurement. These standards address the "loudness war" problem by providing objective, perceptually-relevant loudness metrics.

### Key Standards:

- **ITU-R BS.1770-4**: Defines the K-weighting filter and gating mechanism for loudness measurement
- **EBU R128**: Specifies target loudness (-23 LUFS for broadcast, -14 to -16 LUFS for streaming) and true-peak limits (-1.0 dBTP)
- **ATSC A/85**: Similar standards for North American broadcast
- **Platform-specific policies**: Each streaming platform (Spotify, Apple Music, YouTube, TikTok) implements its own loudness normalization

## 1.2 True-Peak Measurement

True-peak measurement is critical for preventing inter-sample peaks that can cause clipping after digital-to-analog conversion. The EBU R128 standard recommends 4× oversampling for true-peak measurement, though higher oversampling factors (8×) can reveal additional peaks in some content [3].

## 1.3 Dialogue-Aware Loudness

Recent research has highlighted the importance of dialogue-specific loudness metrics, particularly for broadcast content where speech intelligibility is paramount. The Dialogue Loudness Difference (LD) metric helps identify content where dialogue may be masked by background elements [4].

## 1.4 Codec-Induced Distortion

Lossy audio codecs (AAC, Opus, OGG Vorbis) introduce spectral and dynamic range distortion. Understanding these distortions is essential for optimizing content for different streaming platforms [5].

## References

[1] ITU-R BS.1770-4, Algorithms to measure audio programme loudness and true-peak audio level
[2] EBU Tech 3341/3342, Loudness normalisation and permitted maximum level of audio signals
[3] EBU Tech 3343, Practical guidelines for production programmes in accordance with EBU R 128
[4] ITU-R BS.1770-4 Annex 2, Dialogue gating
[5] Various codec specifications: AAC (ISO/IEC 13818-7), Opus (RFC 6716), OGG Vorbis

# 2. Research Questions

This project addresses the following research questions:

## 2.1 Primary Research Questions

1. **How can we accurately measure and analyze audio loudness according to ITU-R BS.1770/EBU R128 standards?**
   - Implementation of K-weighting filter and gating mechanism
   - Accurate true-peak measurement with configurable oversampling
   - Integration of dialogue-aware metrics

2. **How do different streaming platforms affect audio loudness and true-peak compliance?**
   - Platform-specific loudness targets (Apple Music: -16 LUFS, Spotify: -14 LUFS, YouTube: -14 LUFS, TikTok: -16 LUFS)
   - Platform-specific true-peak limits (typically -1.0 dBTP)
   - Normalization algorithm differences (gain application, limiting behavior)

3. **What are the spectral and dynamic range distortions introduced by lossy audio codecs?**
   - Spectral centroid, spread, and rolloff changes
   - Short-term loudness range (LRA) modifications
   - Dynamic range and crest factor alterations
   - Codec-induced true-peak overshoot

## 2.2 Secondary Research Questions

4. **How sensitive are true-peak measurements to oversampling factors?**
   - Comparison of 4× vs 8× oversampling
   - Identification of borderline cases and flip-cases

5. **Can we develop an adaptive normalization system that optimizes for both loudness targets and true-peak safety?**
   - True-peak safe gain optimization
   - Adaptive limiter with configurable attack/release

# 3. Methods / Pipeline

## 3.1 System Architecture

The project implements a modular MATLAB-based framework with the following components:

### 3.1.1 Core Processing Pipeline

```
WAV Files (data/wav/*.wav)
    ↓
1. Audio Preprocessing
   - Mono conversion (sum of squares for multi-channel)
   - DC removal
   - Resampling to 48 kHz (if needed)
    ↓
2. Loudness Measurement (measure_loudness)
   - BS.1770 K-weighting filter
   - Block-based loudness (400ms blocks, 100ms hop)
   - Integrated loudness (LUFS)
   - Loudness Range (LRA)
   - Short-term and momentary loudness
   - True-peak measurement (4× oversampling)
    ↓
3. Dialogue Metrics (dialogue_metrics)
   - Voice Activity Detection (VAD)
   - Speech-only loudness
   - Dialogue Loudness Difference (LD)
   - Dialogue risk assessment
    ↓
4. Platform Compliance Analysis (compliance_platform)
   - Platform-specific normalization simulation
   - True-peak limiting
   - Compliance flagging
    ↓
5. Results Export
   - CSV tables (metrics, compliance, summaries)
   - HTML report with visualizations
   - Publication-quality figures
```

### 3.1.2 Optional Advanced Analysis Modules

**Codec Simulation** (requires FFmpeg):
- Platform normalization → Codec encoding/decoding → Post-codec analysis
- Spectral distortion analysis (centroid, spread, rolloff, SNR)
- Short-term dynamics profiling (LRA, dynamic range, crest factor)
- True-peak overshoot measurement

**True-Peak Sensitivity Analysis**:
- Comparison of 4× vs 8× oversampling
- Identification of flip-cases and borderline files

## 3.2 Key Algorithms

### 3.2.1 BS.1770 K-Weighting Filter

The K-weighting filter consists of:
1. Pre-filter: High-shelf filter at 1.7 kHz
2. RLB (Revised Low-frequency B-curve): Low-shelf filter at 38 Hz
3. RMS calculation on filtered signal
4. Gating: Remove blocks below -70 LUFS relative to ungated loudness

### 3.2.2 True-Peak Measurement

True-peak is measured by:
1. Upsampling audio signal (default 4×, configurable)
2. Applying anti-aliasing filter
3. Finding maximum absolute sample value
4. Converting to dBTP: TP_dBTP = 20×log₁₀(max(|x_upsampled|))

### 3.2.3 Voice Activity Detection (VAD)

Multiple VAD methods are implemented:
1. **Energy-based VAD**: Frame-level energy thresholding
2. **Mini-SAD (Spectral Activity Detection)**: Spectral centroid-based detection
3. **WebRTC VAD** (if available): Industry-standard VAD algorithm
4. **Temporal smoothing**: 3-second smoothing window to reduce false positives

### 3.2.4 Platform Normalization

The normalization process (`normalize_streaming`) implements:
1. **Gain calculation**: gain_dB = targetLUFS - preLUFS
2. **True-peak safety check**: If (preTP + gain_dB) > tpLimit, apply limiting
3. **Adaptive limiter**: Fast attack (3ms), smooth release (50ms)
4. **Post-processing metrics**: Measure post-normalization LUFS and TP

### 3.2.5 Codec Simulation

Codec simulation uses FFmpeg for realistic encoding/decoding:
1. Normalize audio to platform target
2. Encode using platform codec (AAC, Opus, OGG Vorbis) at specified bitrate
3. Decode back to PCM
4. Measure spectral and dynamic changes
5. Calculate true-peak overshoot

# 4. Experiments

## 4.1 Experimental Setup

### 4.1.1 Dataset

- **Input**: WAV audio files in `data/wav/` directory
- **Format**: Any sample rate, mono or stereo (automatically converted)
- **Processing**: All files processed in batch mode

### 4.1.2 Platform Configuration

Four major streaming platforms are analyzed:

| Platform | Target LUFS | TP Limit | Boost Allowed | Codecs |
|----------|-------------|----------|---------------|--------|
| Apple Music | -16 | -1.0 dBTP | Yes | AAC, Opus, OGG |
| Spotify | -14 | -1.0 dBTP | Yes | AAC, Opus, OGG |
| YouTube | -14 | -1.0 dBTP | No | AAC, Opus, OGG |
| TikTok | -16 | -1.0 dBTP | Yes | AAC, Opus, OGG |

### 4.1.3 Processing Parameters

All parameters follow EBU R128 standards:
- Loudness block size: 400 ms
- Loudness hop size: 100 ms
- True-peak oversampling: 4× (EBU recommended)
- True-peak ceiling: -1.0 dBTP
- Limiter attack: 3 ms
- Limiter release: 50 ms
- VAD frame size: 10 ms
- VAD smoothing: 3 seconds

## 4.2 Experimental Procedures

### 4.2.1 Core Analysis (run_project)

1. **Loudness Measurement**: For each WAV file, measure:
   - Integrated loudness (LUFS)
   - Loudness Range (LRA)
   - Short-term and momentary loudness
   - True-peak (dBTP)

2. **Dialogue Analysis**: For each file, compute:
   - Speech ratio (percentage of audio containing speech)
   - Speech-only loudness (LUFS)
   - Dialogue Loudness Difference (LD = integratedLUFS - speechLUFS)
   - Dialogue risk flag (LD > 6 LU indicates potential masking)

3. **Platform Compliance**: For each file and platform:
   - Simulate platform normalization
   - Check true-peak compliance
   - Record limiter activation
   - Generate compliance flags

4. **Summary Statistics**: Aggregate results by platform:
   - Mean post-normalization LUFS
   - Mean post-normalization TP
   - Limiter activation rate
   - Compliance rate

### 4.2.2 Advanced Analysis (Optional)

**Codec Distortion Analysis** (`analyze_codec_distortion`):
- Process up to 10 files (configurable)
- For each file, platform, and codec:
  1. Normalize to platform target
  2. Encode/decode using FFmpeg
  3. Measure spectral features (centroid, spread, rolloff)
  4. Calculate SNR
  5. Measure short-term dynamics (LRA, dynamic range, crest factor)
  6. Record true-peak overshoot

**True-Peak Sensitivity** (`analyze_truepeak_sensitivity`):
- Measure TP with both 4× and 8× oversampling
- Identify flip-cases (compliance changes between methods)
- Flag borderline files (close to -1.0 dBTP limit)

## 4.3 Output Files

### 4.3.1 CSV Data Tables

- **metrics.csv**: Per-file loudness and dialogue metrics
- **compliance_platform.csv**: Per-file, per-platform compliance results
- **summary_platform.csv**: Aggregated statistics by platform
- **codec_overshoot.csv**: Codec-induced true-peak overshoot
- **platform_listening.csv**: Complete listening chain simulation
- **codec_spectral_distortion.csv**: Spectral changes after codec
- **codec_dynamics_profile.csv**: Dynamic range changes after codec
- **platform_normalization.csv**: Normalization simulation results
- **tp_sensitivity.csv**: True-peak sensitivity analysis

### 4.3.2 Visualizations

Publication-quality figures generated:
- LRA distribution histogram
- Gain vs True-Peak scatter plot
- Platform compliance comparison
- Loudness distribution with normal overlay
- True-peak analysis (distribution, box plot, statistics)
- Dialogue metrics visualization
- Codec spectral distortion analysis
- Short-term dynamics profile
- Platform normalization simulation

### 4.3.3 HTML Report

Comprehensive HTML report (`report.html`) includes:
- Executive summary with key statistics
- Complete data tables (collapsible sections)
- All visualizations with descriptive captions
- File links for easy data access

# 5. Code Description

## 5.1 Project Structure

Project structure:

project_root/
  matlab/              # All MATLAB source code
    config.m         # Global configuration
    run_project.m    # Main entry point
    run_all_experiments.m  # Full experimental pipeline
    Core Processing/
      measure_loudness.m      # BS.1770 loudness measurement
      dialogue_metrics.m       # Dialogue-aware analysis
      dialogue_VAD.m          # Voice Activity Detection
      truepeak_ref.m          # True-peak measurement
      normalize_streaming.m   # Platform normalization
    Platform Analysis/
      platform_presets.m      # Platform configurations
      compliance_platform.m  # Compliance checking
      make_dashboard_tables.m # Summary statistics
    Codec Simulation/
      simulate_codec_chain.m        # Codec overshoot analysis
      simulate_platform_listening.m # Full listening chain
      analyze_codec_distortion.m    # Comprehensive distortion
    Advanced Analysis/
      analyze_truepeak_sensitivity.m # TP sensitivity
      adaptive_mastering_profiles.m   # Adaptive normalization
      optimize_gain_tp_safe.m        # TP-safe optimization
    Visualization/
      plot_helpers.m          # All plotting functions
    Reporting/
      export_html_report.m   # HTML report generation
      compliance_report.m    # Text report
    Utilities/
      force_write_table.m    # Robust CSV writing
      row_metrics.m          # Metrics table row
      row_comp.m             # Compliance table row
      isFFmpegAvailable.m    # FFmpeg detection
  data/
    wav/            # Input WAV files
  results/            # Output directory
    *.csv          # Data tables
    report.html    # HTML report
    figures/       # Generated plots
  figures/            # Alternative figure location

## 5.2 Key Functions

### 5.2.1 Core Measurement Functions

**`measure_loudness(x, Fs, cfg)`**:
- Implements ITU-R BS.1770-4 / EBU R128 compliant loudness measurement
- Applies K-weighting filter (pre-filter + RLB)
- Calculates block-based loudness (400ms blocks, 100ms hop)
- Returns: integratedLUFS, LRA, shortTermLUFS, momentaryLUFS, truePeak_dBTP
- Configurable via `cfg.loudnessBlockMs`, `cfg.loudnessHopMs`

**`truepeak_ref(x, Fs, oversample)`**:
- Measures true-peak with configurable oversampling (default 4×)
- Upsamples signal, applies anti-aliasing filter
- Returns maximum absolute value in dBTP

**`dialogue_metrics(x, Fs, cfg)`**:
- Performs Voice Activity Detection (VAD)
- Calculates speech-only loudness
- Computes Dialogue Loudness Difference (LD)
- Flags risky content (LD > 6 LU)
- Returns: speechLUFS, speechRatio, LD, flag_risky, flag_bad

### 5.2.2 Platform Analysis Functions

**`normalize_streaming(x, Fs, preLUFS, preTP, targetLUFS, cfg, plat, fname)`**:
- Simulates platform loudness normalization
- Calculates gain: gain_dB = targetLUFS - preLUFS
- Applies true-peak safe limiting if needed
- Uses adaptive limiter (3ms attack, 50ms release)
- Returns: y (normalized audio), postLUFS, postTP, gain_dB, limited, maxGR, meanGR

**`compliance_platform(cfg)`**:
- Reads metrics.csv
- For each file and platform, simulates normalization
- Checks compliance with platform limits
- Generates compliance_platform.csv

**`platform_presets(name)`**:
- Returns platform configuration struct
- Fields: name, targetLUFS, tpLimit, enableBoost, DRC, codecs, eqHF_dB
- Supports: AppleMusic, Spotify, YouTube, TikTok

### 5.2.3 Codec Simulation Functions

**`analyze_codec_distortion(cfg, K)`**:
- Comprehensive codec distortion analysis
- Processes K files (default 10)
- For each file, platform, and codec:
  * Normalizes audio
  * Encodes/decodes using FFmpeg
  * Measures spectral features (centroid, spread, rolloff)
  * Calculates SNR and spectral distortion
  * Measures short-term dynamics (LRA, dynamic range, crest factor)
- Generates three CSV files: spectral_distortion, dynamics_profile, normalization

**`simulate_codec_chain(cfg, K)`**:
- Simulates codec encoding/decoding chain
- Measures true-peak before and after codec
- Calculates codec-induced overshoot
- Generates codec_overshoot.csv

**`simulate_platform_listening(cfg, K)`**:
- Simulates complete listening chain: normalization + codec
- Measures loudness and TP at each stage
- Generates platform_listening.csv

### 5.2.4 Visualization Functions

**`plot_helpers(kind, cfg)`**:
- Generates publication-quality figures
- Available plots: hist_LRA, scatter_deltalu_tp, platform_compliance, loudness_distribution, truepeak_analysis, dialogue_metrics, codec_spectral, codec_dynamics, normalization_simulation, all
- All figures saved as PNG (300 DPI)
- Includes statistical annotations (mean, median, std)

### 5.2.5 Reporting Functions

**`export_html_report(cfg)`**:
- Generates comprehensive HTML report
- Includes all CSV data (collapsible sections)
- Embeds all visualizations
- Provides summary statistics
- Includes file links for easy access

## 5.3 Configuration System

**`config()`** returns a struct with all project parameters:

```matlab
cfg.resultsDir          cfg.dataDir             cfg.figDir              cfg.platforms           cfg.truePeakOversample  cfg.tpCeil              cfg.loudnessBlockMs     cfg.loudnessHopMs       cfg.limiterAttackMs     cfg.limiterReleaseMs     cfg.vadFrameMs          cfg.vadSmoothingSec    ```

## 5.4 Error Handling and Robustness

- **Robust file I/O**: `force_write_table` handles read-only files, retries with exponential backoff
- **Graceful degradation**: Missing optional modules (FFmpeg, external tools) don't crash pipeline
- **Fallback mechanisms**: Dialogue metrics fallback if VAD fails
- **Comprehensive error catching**: All modules wrapped in try-catch blocks
- **Parameter validation**: All functions check for required fields and provide defaults

# 6. Results

## 6.1 Output Data Structure

The system generates comprehensive results organized as follows:

### 6.1.1 Per-File Metrics (metrics.csv)

Each row contains:
- File name
- Integrated loudness (LUFS)
- Loudness Range (LRA, LU)
- Short-term loudness (LUFS)
- Momentary loudness (LUFS)
- True-peak (dBTP)
- Speech loudness (LUFS)
- Speech ratio (0-1)
- Dialogue Level Difference (LD, LU)
- Dialogue risk flag (0 or 1)

### 6.1.2 Platform Compliance (compliance_platform.csv)

Each row contains (file × platform):
- File name
- Platform name
- Pre-normalization LUFS and TP
- Post-normalization LUFS and TP
- Applied gain (dB)
- Limiter activation flag
- Maximum gain reduction (dB)
- Mean gain reduction (dB)
- Gain reduction time ratio
- Compliance flag

### 6.1.3 Platform Summary (summary_platform.csv)

Aggregated statistics per platform:
- Number of files processed
- Number of files requiring limiting
- Limiter activation rate (%)
- Mean post-normalization LUFS
- Mean post-normalization TP

### 6.1.4 Codec Analysis Results

**Codec Spectral Distortion** (codec_spectral_distortion.csv):
- Pre- and post-codec spectral centroid, spread, rolloff
- Spectral changes (differences)
- Signal-to-noise ratio (SNR)
- Overall spectral distortion metric

**Short-term Dynamics Profile** (codec_dynamics_profile.csv):
- Pre- and post-codec mean LRA, max LRA
- LRA changes
- Pre- and post-codec dynamic range
- Dynamic range changes
- Pre- and post-codec crest factor

**Platform Normalization Simulation** (platform_normalization.csv):
- Pre- and post-normalization LUFS and TP
- Applied gain
- Limiter statistics (activation, max GR, mean GR, time ratio)

## 6.2 Visualization Results

The system generates publication-quality visualizations:

### 6.2.1 Core Analysis Plots

1. **LRA Distribution**: Histogram showing distribution of Loudness Range values
2. **Gain vs True-Peak**: Scatter plot showing relationship between applied gain and resulting TP
3. **Platform Compliance**: Bar charts comparing limiter activation rates, mean TP, and loudness across platforms
4. **Loudness Distribution**: Histogram with normal distribution overlay and target references
5. **True-Peak Analysis**: Comprehensive TP analysis including distribution, box plot, and statistics
6. **Dialogue Metrics**: Multi-panel visualization of speech ratio, LD, and risk assessment

### 6.2.2 Advanced Analysis Plots

7. **Codec Spectral Distortion**: Analysis of spectral changes (centroid, spread, rolloff) introduced by codecs
8. **Short-term Dynamics Profile**: Analysis of dynamic range and LRA changes in short-term windows
9. **Platform Normalization Simulation**: Comprehensive analysis of gain application, limiting, and post-normalization metrics

## 6.3 Statistical Summary

All visualizations include statistical annotations:
- Mean, median, standard deviation
- Min/max values
- Sample counts
- Percentage distributions (where applicable)

# 7. Discussion

## 7.1 Implementation Achievements

This project successfully implements a comprehensive loudness analysis framework that:

1. **Fully complies with ITU-R BS.1770-4 and EBU R128 standards**
   - Accurate K-weighting filter implementation
   - Proper gating mechanism
   - Standard-compliant true-peak measurement

2. **Provides multi-platform analysis**
   - Supports four major streaming platforms
   - Platform-specific normalization simulation
   - Comprehensive compliance checking

3. **Extends beyond basic loudness measurement**
   - Dialogue-aware metrics for broadcast content
   - Codec distortion analysis
   - True-peak sensitivity assessment
   - Short-term dynamics profiling

4. **Offers production-ready tools**
   - Robust error handling
   - Comprehensive reporting (HTML + CSV)
   - Publication-quality visualizations
   - Modular, extensible architecture

## 7.2 Key Findings and Insights

### 7.2.1 Platform Differences

The analysis reveals significant differences between platforms:
- **Target loudness variation**: Apple Music and TikTok target -16 LUFS, while Spotify and YouTube target -14 LUFS
- **Boost policies**: YouTube typically only attenuates, while others allow boosting
- **Codec choices**: All platforms support multiple codecs (AAC, Opus, OGG) at various bitrates
- **Limiter activation rates**: Vary significantly based on source material loudness distribution

### 7.2.2 Codec Impact

Codec simulation reveals:
- **Spectral distortion**: Codecs introduce measurable changes in spectral centroid, spread, and rolloff
- **Dynamic range compression**: Short-term LRA and dynamic range are affected by codec processing
- **True-peak overshoot**: Some codecs can introduce inter-sample peaks exceeding the original true-peak
- **Platform-specific effects**: Different platforms may use different codec implementations, leading to varying distortion patterns

### 7.2.3 Dialogue Metrics Utility

Dialogue-aware metrics provide valuable insights:
- **Speech ratio**: Helps identify content type (music vs. speech-heavy)
- **Dialogue Level Difference (LD)**: Flags content where dialogue may be masked
- **Risk assessment**: LD > 6 LU indicates potential intelligibility issues
- **Content optimization**: Enables targeted processing for dialogue-heavy content

### 7.2.4 True-Peak Sensitivity

True-peak measurement sensitivity analysis shows:
- **4× vs 8× oversampling**: Higher oversampling can reveal additional peaks
- **Flip-cases**: Some files change compliance status between 4× and 8× measurement
- **Borderline files**: Files near the -1.0 dBTP limit require careful attention
- **Practical recommendation**: 4× oversampling (EBU standard) is sufficient for most content, but 8× may be needed for critical applications

## 7.3 Limitations and Considerations

1. **FFmpeg dependency**: Codec simulation requires FFmpeg installation
   - Solution: Graceful degradation when FFmpeg unavailable
   - Core analysis functions work without FFmpeg

2. **Platform policy assumptions**: Platform normalization algorithms are simulated based on public documentation
   - Actual platform implementations may differ
   - Codec implementations may vary between platforms

3. **Computational complexity**: Codec simulation is time-intensive
   - Solution: Configurable file limit (default 10 files)
   - Can be run separately for full dataset

4. **VAD accuracy**: Voice Activity Detection may have false positives/negatives
   - Multiple VAD methods implemented for robustness
   - Fallback to energy-based method if advanced VAD fails

## 7.4 Comparison with Existing Tools

This framework offers several advantages over existing loudness measurement tools:

1. **Comprehensive platform analysis**: Most tools focus on single-platform compliance
2. **Codec simulation**: Unique capability to analyze codec-induced distortion
3. **Dialogue metrics**: Extends beyond basic loudness to dialogue-aware analysis
4. **Open-source and extensible**: MATLAB code allows customization and extension
5. **Batch processing**: Efficient processing of large audio libraries
6. **Comprehensive reporting**: HTML reports with embedded visualizations

# 8. Usage / Reproducibility

## 8.1 System Requirements

### 8.1.1 Software Requirements

- **MATLAB**: R2018b or later (tested on R2020a+)
  - Required toolboxes: Signal Processing Toolbox (for resample, filter functions)
  - Optional: Statistics and Machine Learning Toolbox (for some advanced features)

- **FFmpeg** (optional, for codec simulation):
  - Version 4.0 or later recommended
  - Must be in system PATH
  - Check availability: `isFFmpegAvailable()` or `system('ffmpeg -version')`

### 8.1.2 Hardware Requirements

- **RAM**: Minimum 4 GB, recommended 8 GB or more
- **Storage**: Sufficient space for input WAV files and output results
- **Processing time**: Varies with dataset size
  - Core analysis: ~1-2 seconds per file
  - Codec simulation: ~10-30 seconds per file (depending on codec and file length)

## 8.2 Installation and Setup

### 8.2.1 Project Structure Setup

1. **Extract project files** to a directory (e.g., `C:\elec5305project\`)
2. **Create directory structure**:
   ```
   project_root/
   ├── matlab/          # All .m files
   ├── data/
   │   └── wav/        # Place WAV files here
   ├── results/         # Created automatically
   └── figures/         # Created automatically
   ```

3. **Add MATLAB path**:
   ```matlab
   addpath(genpath('path/to/project_root/matlab'));
   ```

4. **Place audio files**: Copy WAV files to `data/wav/` directory

### 8.2.2 Optional: FFmpeg Installation

For codec simulation features:
1. Download FFmpeg from https://ffmpeg.org/
2. Install and add to system PATH
3. Verify installation: `system('ffmpeg -version')`
4. The system will automatically detect FFmpeg availability

## 8.3 Basic Usage

### 8.3.1 Quick Start

**Run complete analysis pipeline**:
```matlab
run_project()
```

This will:
1. Process all WAV files in `data/wav/`
2. Generate metrics.csv
3. Perform platform compliance analysis
4. Generate summary statistics
5. Create HTML report
6. Generate visualizations (if FFmpeg available, also runs codec analysis)

### 8.3.2 Advanced Usage

**Run all experiments (including optional modules)**:
```matlab
run_all_experiments()
```

**Custom configuration**:
```matlab
cfg = config();
cfg.truePeakOversample = 8;  cfg.streamTargetLUFS = -16;  run_project(cfg);
```

**Run specific analysis modules**:
```matlab
cfg = config();
compliance_platform(cfg);           analyze_codec_distortion(cfg, 5);     analyze_truepeak_sensitivity(cfg);    plot_helpers('all', cfg);          export_html_report(cfg);              ```

## 8.4 Output Files and Interpretation

### 8.4.1 CSV Data Files

All CSV files are located in `results/` directory:

- **metrics.csv**: Open in Excel, MATLAB, or any spreadsheet software
- **compliance_platform.csv**: Filter by platform to see per-platform results
- **summary_platform.csv**: Quick overview of platform statistics
- **codec_*.csv**: Codec analysis results (if FFmpeg available)

### 8.4.2 HTML Report

Open `results/report.html` in any web browser:
- **Executive Summary**: Key statistics at a glance
- **Data Tables**: Click "Show Full Table" to expand sections
- **Visualizations**: All generated figures with descriptions
- **File Links**: Direct links to CSV files

### 8.4.3 Figures

All figures saved as PNG (300 DPI) in `figures/` directory:
- Suitable for publication
- Can be imported into Word, LaTeX, or presentation software
- File names are descriptive (e.g., `platform_compliance.png`)

## 8.5 Reproducibility

### 8.5.1 Version Control

The project is designed for reproducibility:
- All parameters are configurable via `config.m`
- Random number generation uses fixed seeds (where applicable)
- File paths are relative and auto-detected
- No hardcoded absolute paths

### 8.5.2 Reproducing Results

To reproduce results:
1. Use the same WAV files
2. Use the same MATLAB version (or compatible)
3. Use default configuration (or document custom settings)
4. Run `run_project()` with the same parameters

### 8.5.3 Configuration Documentation

All configuration parameters are documented in `config.m`:
- Parameter names are self-explanatory
- Default values follow industry standards (EBU R128)
- Comments explain each parameter's purpose

## 8.6 Troubleshooting

### Common Issues

**Issue**: "No WAV files found"
- **Solution**: Check that WAV files are in `data/wav/` directory
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

# 9. Conclusions & Future Work

## 9.1 Conclusions

This project successfully implements a comprehensive, production-ready framework for audio loudness and true-peak analysis that:

1. **Fully complies with industry standards** (ITU-R BS.1770-4, EBU R128)
   - Accurate implementation of K-weighting filter
   - Standard-compliant loudness and true-peak measurement
   - Configurable parameters following EBU recommendations

2. **Extends beyond basic measurement**
   - Multi-platform compliance analysis
   - Dialogue-aware metrics for broadcast content
   - Codec distortion assessment
   - True-peak sensitivity analysis

3. **Provides practical tools for content creators and engineers**
   - Batch processing of large audio libraries
   - Comprehensive reporting and visualization
   - Platform-specific optimization guidance

4. **Offers robust, extensible architecture**
   - Modular design allows easy extension
   - Comprehensive error handling
   - Graceful degradation for missing dependencies

The framework has been validated through extensive testing and successfully processes real-world audio content, providing actionable insights for loudness optimization across multiple streaming platforms.

## 9.2 Future Work

### 9.2.1 Algorithmic Improvements

1. **Enhanced VAD algorithms**
   - Integration of deep learning-based VAD
   - Multi-method fusion for improved accuracy
   - Language-specific VAD models

2. **Advanced normalization strategies**
   - Machine learning-based gain prediction
   - Perceptual loudness models (e.g., ITU-R BS.1770-5)
   - Content-aware normalization (music vs. speech)

3. **Real-time processing**
   - Streaming loudness measurement
   - Real-time true-peak monitoring
   - Live compliance checking

### 9.2.2 Platform Extensions

1. **Additional platforms**
   - Amazon Music, Deezer, Tidal
   - Podcast platforms (Spotify Podcasts, Apple Podcasts)
   - Broadcast standards (ATSC, DVB)

2. **Platform policy updates**
   - Automatic policy update mechanism
   - Historical policy tracking
   - A/B testing of normalization strategies

### 9.2.3 Codec Analysis Enhancements

1. **Additional codecs**
   - MP3, FLAC, WMA
   - High-resolution codecs (MQA, aptX HD)
   - Spatial audio codecs (Dolby Atmos, Sony 360 Reality Audio)

2. **Perceptual codec assessment**
   - Perceptual evaluation of codec quality (PESQ, POLQA)
   - Listening test integration
   - Subjective quality prediction

### 9.2.4 User Interface and Workflow

1. **Graphical user interface**
   - MATLAB App Designer interface
   - Real-time visualization
   - Interactive parameter adjustment

2. **Cloud deployment**
   - Web-based interface
   - API for integration with other tools
   - Batch processing service

3. **Integration with DAWs**
   - VST/AU plugin for real-time monitoring
   - Pro Tools, Logic Pro, Reaper integration
   - Automated mastering workflows

### 9.2.5 Research Directions

1. **Loudness perception modeling**
   - Individual listener differences
   - Context-dependent loudness perception
   - Cross-cultural loudness preferences

2. **Content-adaptive processing**
   - Genre-specific loudness targets
   - Automatic content classification
   - Adaptive normalization based on content type

3. **Long-term loudness trends**
   - Historical analysis of loudness in music production
   - Platform policy impact assessment
   - Industry trend prediction

## 9.3 Impact and Applications

This framework has potential applications in:

1. **Audio production and mastering**
   - Pre-mastering loudness analysis
   - Multi-platform optimization
   - Quality control workflows

2. **Broadcast and streaming**
   - Compliance checking
   - Automated quality assurance
   - Content preparation pipelines

3. **Research and education**
   - Loudness measurement education
   - Audio processing research
   - Standard implementation reference

4. **Content delivery optimization**
   - Platform-specific encoding strategies
   - Codec selection optimization
   - Quality vs. file size trade-offs

---

## Appendix: Function Reference

### Core Functions

- `run_project(cfg)`: Main analysis pipeline
- `measure_loudness(x, Fs, cfg)`: BS.1770 loudness measurement
- `dialogue_metrics(x, Fs, cfg)`: Dialogue-aware analysis
- `compliance_platform(cfg)`: Platform compliance checking
- `normalize_streaming(...)`: Platform normalization simulation

### Advanced Analysis

- `analyze_codec_distortion(cfg, K)`: Comprehensive codec analysis
- `simulate_codec_chain(cfg, K)`: Codec overshoot analysis
- `analyze_truepeak_sensitivity(cfg)`: TP sensitivity analysis

### Visualization and Reporting

- `plot_helpers(kind, cfg)`: Generate publication-quality figures
- `export_html_report(cfg)`: Comprehensive HTML report
- `compliance_report()`: Text-based compliance report

### Utilities

- `config()`: Get configuration struct
- `platform_presets(name)`: Get platform configuration
- `force_write_table(T, filepath, ...)`: Robust CSV writing
- `isFFmpegAvailable()`: Check FFmpeg availability

---

*Document generated automatically by generate_project_documentation.m*
*For the most up-to-date information, refer to the source code and inline documentation.*
