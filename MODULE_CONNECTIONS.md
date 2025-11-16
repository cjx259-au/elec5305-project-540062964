# 模块连接图

## 完整数据流

```
WAV Files (data/wav/*.wav)
    ↓
[run_project] 或 [run_all_experiments]
    ↓
┌─────────────────────────────────────────────────────────┐
│ 1. 音频处理模块                                         │
├─────────────────────────────────────────────────────────┤
│ measure_loudness(x, Fs, cfg)                           │
│   → M: integratedLUFS, LRA, shortTermLUFS,             │
│       momentaryLUFS, truePeak_dBTP                     │
│                                                         │
│ dialogue_metrics(x, Fs, cfg)                           │
│   → dialogue_VAD(x, Fs, cfg)                          │
│   → D: speechLUFS, speechRatio, LD,                    │
│       flag_risky, flag_bad                              │
│                                                         │
│ row_metrics(fname, M, tp_ref)                          │
│   → 单行 table                                          │
└─────────────────────────────────────────────────────────┘
    ↓
metrics.csv (results/metrics.csv)
    ↓
┌─────────────────────────────────────────────────────────┐
│ 2. 平台合规分析模块                                     │
├─────────────────────────────────────────────────────────┤
│ compliance_platform(cfg)                                │
│   → 读取 metrics.csv                                    │
│   → 使用 cfg.platforms 或 platform_presets()          │
│   → 生成 compliance_platform.csv                       │
└─────────────────────────────────────────────────────────┘
    ↓
compliance_platform.csv (results/compliance_platform.csv)
    ↓
┌─────────────────────────────────────────────────────────┐
│ 3. 汇总统计模块                                         │
├─────────────────────────────────────────────────────────┤
│ make_dashboard_tables(cfg)                             │
│   → 读取 compliance_platform.csv                       │
│   → 按平台汇总统计                                      │
│   → 生成 summary_platform.csv                          │
└─────────────────────────────────────────────────────────┘
    ↓
summary_platform.csv (results/summary_platform.csv)
    ↓
┌─────────────────────────────────────────────────────────┐
│ 4. 报告生成模块                                         │
├─────────────────────────────────────────────────────────┤
│ compliance_report()                                   │
│   → 读取 summary_platform.csv                          │
│   → 生成 compliance_report.txt                          │
│                                                         │
│ export_html_report(cfg)                                │
│   → 读取 metrics.csv, summary_platform.csv,             │
│      codec_overshoot.csv, platform_listening.csv       │
│   → 生成 report.html                                    │
│                                                         │
│ summarize_for_writeup()                                 │
│   → 读取 metrics.csv, summary_platform.csv              │
│   → 生成 summary.txt                                    │
└─────────────────────────────────────────────────────────┘
```

## 可选模块（需要额外依赖）

```
┌─────────────────────────────────────────────────────────┐
│ 5. Codec 模拟模块（需要 FFmpeg）                        │
├─────────────────────────────────────────────────────────┤
│ simulate_codec_chain(cfg, K)                            │
│   → 使用 normalize_streaming()                          │
│   → 使用 FFmpeg 编码/解码                               │
│   → 生成 codec_overshoot.csv                            │
│                                                         │
│ simulate_platform_listening(cfg, K)                     │
│   → 使用 normalize_streaming()                           │
│   → 使用 FFmpeg 编码/解码                               │
│   → 生成 platform_listening.csv                        │
└─────────────────────────────────────────────────────────┘
    ↓
codec_overshoot.csv, platform_listening.csv

┌─────────────────────────────────────────────────────────┐
│ 6. 高级分析模块                                         │
├─────────────────────────────────────────────────────────┤
│ adaptive_mastering_profiles(cfg)                        │
│   → 读取 metrics.csv                                    │
│   → 使用 platform_presets()                             │
│   → 生成 adaptive_mastering.csv                         │
│                                                         │
│ analyze_truepeak_sensitivity(cfg)                       │
│   → 分析不同 oversample 因子的 TP 差异                  │
│   → 生成 tp_sensitivity.csv                             │
└─────────────────────────────────────────────────────────┘
```

## 函数调用关系

### 核心处理链
1. **run_project(cfg)**
   - measure_loudness(x, Fs, cfg)
   - dialogue_metrics(x, Fs, cfg)
     - dialogue_VAD(x, Fs, cfg)
   - row_metrics(fname, M, tp_ref)
   - compliance_platform(cfg)
   - make_dashboard_tables(cfg)
   - adaptive_mastering_profiles(cfg)
   - compliance_report()
   - export_html_report(cfg)
   - simulate_codec_chain(cfg, K) [可选]
   - simulate_platform_listening(cfg, K) [可选]
   - analyze_truepeak_sensitivity(cfg) [可选]

### 辅助函数
- **normalize_streaming(x, Fs, preLUFS, preTP, targetLUFS, cfg, plat, fname)**
  - measure_loudness(y, Fs)
  - truepeak_ref(y, Fs, oversample)
  
- **apply_platform_playback(x, Fs, trackLUFS, trackTP, plat, cfg)**
  - 返回 [y, meta]

- **row_comp(name, C)**
  - 处理 apply_platform_playback 的输出

## 配置文件依赖

所有模块都从 `config()` 获取配置：
- `cfg.platforms` - 平台列表
- `cfg.resultsDir` - 结果目录
- `cfg.dataDir` - 数据目录
- `cfg.figDir` - 图像目录
- 所有处理参数（响度、VAD、限制器等）

## 数据文件依赖

```
metrics.csv
    ↓
compliance_platform.csv
    ↓
summary_platform.csv
    ↓
compliance_report.txt, report.html, summary.txt
```

## 所有模块现在都已连通！

