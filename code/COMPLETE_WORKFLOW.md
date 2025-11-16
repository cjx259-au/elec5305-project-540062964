# 完整工作流程

## 主入口函数

### 1. `run_project(cfg)` - 主项目流程
完整的一键运行流程，包含所有核心模块：

```
输入: WAV 文件 (data/wav/*.wav)
  ↓
1. 音频处理
   - measure_loudness(x, Fs, cfg)
   - dialogue_metrics(x, Fs, cfg)
     - dialogue_VAD(x, Fs, cfg)
   - row_metrics(fname, M, tp_ref)
  ↓
2. 生成 metrics.csv
  ↓
3. 平台合规分析
   - compliance_platform(cfg)
  ↓
4. 生成 compliance_platform.csv
  ↓
5. 平台汇总统计
   - make_dashboard_tables(cfg)
  ↓
6. 生成 summary_platform.csv
  ↓
7. 自适应母带分析（可选）
   - adaptive_mastering_profiles(cfg)
  ↓
8. 生成报告
   - compliance_report()
   - export_html_report(cfg)
  ↓
9. Codec 模拟（可选，需要 FFmpeg）
   - simulate_codec_chain(cfg, 10)
   - simulate_platform_listening(cfg, 10)
  ↓
10. True Peak 敏感性分析（可选）
   - analyze_truepeak_sensitivity(cfg)
```

### 2. `run_all_experiments()` - 完整实验流程
包含所有可选模块的完整流程：

```
1. run_project() - 主流程
2. adaptive_mastering_profiles(cfg) - 自适应母带
3. validate_against_external() - 外部验证（可选）
4. export_html_report(cfg) - HTML 报告
5. TP-safe optimizer demo - 优化器演示
```

## 数据流

```
WAV Files
  ↓
metrics.csv (逐文件指标)
  ↓
compliance_platform.csv (逐文件×平台合规)
  ↓
summary_platform.csv (平台汇总统计)
  ↓
报告文件:
  - compliance_report.txt
  - report.html
  - summary.txt
```

## 可选模块数据流

```
WAV Files
  ↓
normalize_streaming() → 归一化音频
  ↓
FFmpeg 编码/解码
  ↓
codec_overshoot.csv (codec 引起的 TP overshoot)
platform_listening.csv (平台监听链完整模拟)
```

## 所有模块现在都已连通！

### 核心连接点：
1. ✅ `measure_loudness` 接收 `cfg` 参数
2. ✅ `dialogue_metrics` 接收 `cfg` 参数并传递给 `dialogue_VAD`
3. ✅ `normalize_streaming` 使用 `cfg` 中的参数
4. ✅ 所有 CSV 写入使用 `force_write_table`
5. ✅ 所有模块从 `config()` 获取统一配置
6. ✅ 所有可选模块已集成到主流程

### 使用方法：

```matlab
% 方法1: 运行完整项目（推荐）
run_project()

% 方法2: 运行所有实验（包含所有可选模块）
run_all_experiments()

% 方法3: 验证连接
verify_connections()
```

## 模块依赖关系

- **必需模块**（核心流程）：
  - config
  - measure_loudness
  - dialogue_metrics
  - dialogue_VAD
  - row_metrics
  - compliance_platform
  - make_dashboard_tables
  - force_write_table

- **可选模块**（增强功能）：
  - adaptive_mastering_profiles
  - simulate_codec_chain (需要 FFmpeg)
  - simulate_platform_listening (需要 FFmpeg)
  - analyze_truepeak_sensitivity
  - export_html_report
  - compliance_report
  - summarize_for_writeup

所有模块现在都已正确连接并可以正常工作！

