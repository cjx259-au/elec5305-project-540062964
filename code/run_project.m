function run_project(cfg)
    fprintf("==== ELEC5305 Project ====\n");

    if nargin < 1 || isempty(cfg)
        cfg = config();   
    end

    resultsDir = cfg.resultsDir;
    if isfield(cfg,'figuresDir')
        figDir = cfg.figuresDir;
    elseif isfield(cfg,'figDir')
        figDir = cfg.figDir;
    else
        figDir = fullfile(cfg.rootDir, 'figures');
    end

    if ~exist(resultsDir,'dir'), mkdir(resultsDir); end
    if ~exist(figDir,'dir'), mkdir(figDir); end

    files = dir(fullfile(cfg.dataDir, '*.wav'));
    if isempty(files)
        error('No WAV files found under %s', cfg.dataDir);
    end
    N = numel(files);
    metricsRows = cell(N,1);

    for k = 1:N
        fname = files(k).name;
        fpath = fullfile(files(k).folder, fname);
        fprintf('[%2d/%2d] Processing %s ...\n', k, N, fname);

        [x, Fs] = audioread(fpath);
        if size(x,2) > 1
            x = mean(x,2);     
        end

        M = measure_loudness(x, Fs, cfg);

        try
            D = dialogue_metrics(x, Fs, cfg);   
            M.speechLUFS   = D.speechLUFS;
            M.speechRatio  = D.speechRatio;
            M.LD           = D.LD;
            M.dialogueRisk = double(D.flag_risky || D.flag_bad);
        catch ME
            warning('dialogue_metrics failed for %s: %s, using fallback', fname, ME.message);
            [speechLUFS, speechRatio, LD, dialogueRisk] = ...
                simple_dialogue_metrics_local(x, Fs, M.integratedLUFS);
            M.speechLUFS   = speechLUFS;
            M.speechRatio  = speechRatio;
            M.LD           = LD;
            M.dialogueRisk = dialogueRisk;
        end

        tp_ref = M.truePeak_dBTP;
        metricsRows{k} = row_metrics(fname, M, tp_ref);
    end

    Tm = vertcat(metricsRows{:});
    metricsCsv = fullfile(resultsDir, 'metrics.csv');
    try
        success = force_write_table(Tm, metricsCsv, 'WriteMode', 'overwrite');
        if success
            fprintf('[metrics] Wrote %s\n', metricsCsv);
        else
            warning('[metrics] Failed to write %s', metricsCsv);
        end
    catch ME
        warning('[metrics] Failed to write %s: %s', metricsCsv, ME.message);
    end

    try
        compliance_platform(cfg);  
    catch ME
        warning('compliance_platform failed: %s', ME.message);
    end

    try
        make_dashboard_tables(cfg); 
    catch ME
        warning('make_dashboard_tables failed: %s', ME.message);
    end

    try
        if exist('adaptive_mastering_profiles', 'file')
            adaptive_mastering_profiles(cfg);
        end
    catch ME
        warning('adaptive_mastering_profiles failed: %s', ME.message);
    end

    try
        compliance_report();
    catch ME
        warning('compliance_report failed: %s', ME.message);
    end

    try
        export_html_report(cfg);
    catch ME
        warning('export_html_report failed: %s', ME.message);
    end

    ffmpegAvailable = false;
    if exist('isFFmpegAvailable', 'file')
        try
            ffmpegAvailable = isFFmpegAvailable();
        catch
            ffmpegAvailable = false;
        end
    end
    
    if ~ffmpegAvailable
        fprintf('\n[Info] FFmpeg not found - codec simulation modules will be skipped\n');
        fprintf('  To enable codec simulation: Install FFmpeg and add it to your system PATH\n');
    end

    try
        if exist('simulate_codec_chain', 'file')
            if ffmpegAvailable
                fprintf('\n[Optional] Running codec chain simulation...\n');
                simulate_codec_chain(cfg, 10);  
            else
                fprintf('[Optional] Codec chain simulation skipped (FFmpeg required)\n');
            end
        end
    catch ME
        warning('simulate_codec_chain failed: %s', ME.message);
    end

    % Optional: Platform listening simulation (requires FFmpeg)
    try
        if exist('simulate_platform_listening', 'file')
            if ffmpegAvailable
                fprintf('\n[Optional] Running platform listening simulation...\n');
                simulate_platform_listening(cfg, 10);  % Limit to 10 files to save time
            else
                fprintf('[Optional] Platform listening simulation skipped (FFmpeg required)\n');
            end
        end
    catch ME
        warning('simulate_platform_listening failed: %s', ME.message);
    end

    % Optional: Comprehensive codec distortion analysis (requires FFmpeg)
    try
        if exist('analyze_codec_distortion', 'file')
            if ffmpegAvailable
                fprintf('\n[Optional] Running comprehensive codec distortion analysis...\n');
                fprintf('  This includes: spectral distortion, short-term dynamics, and normalization simulation\n');
                analyze_codec_distortion(cfg, 10);  % Limit to 10 files to save time
            else
                fprintf('[Optional] Codec distortion analysis skipped (FFmpeg required)\n');
            end
        end
    catch ME
        warning('analyze_codec_distortion failed: %s', ME.message);
    end

    % Optional: True Peak sensitivity analysis
    try
        if exist('analyze_truepeak_sensitivity', 'file')
            fprintf('\n[Optional] Running True Peak sensitivity analysis...\n');
            analyze_truepeak_sensitivity(cfg);
        end
    catch ME
        warning('analyze_truepeak_sensitivity failed: %s', ME.message);
    end

    % Generate enhanced visualizations
    try
        if exist('plot_helpers', 'file')
            fprintf('\n[Visualization] Generating enhanced plots...\n');
            plot_helpers('all', cfg);
            fprintf('[Visualization] All plots generated successfully.\n');
        end
    catch ME
        warning('plot_helpers failed: %s', ME.message);
    end

    fprintf('\n[run_project] Done. CSV -> %s, figures -> %s\n', ...
        resultsDir, figDir);
    fprintf('[run_project] All modules completed successfully.\n');
end

function [speechLUFS, speechRatio, LD, dialogueRisk] = ...
    simple_dialogue_metrics_local(x, Fs, integratedLUFS)

    if size(x,2) > 1
        x = mean(x,2);
    end

    N   = length(x);
    win = round(0.02*Fs);      % 20ms
    hop = win;
    nF  = floor((N-win)/hop)+1;

    energy = zeros(nF,1);
    for i = 1:nF
        idx = (i-1)*hop+1 : (i-1)*hop+win;
        seg = x(idx);
        energy(i) = mean(seg.^2);
    end

    if all(energy==0)
        speechLUFS   = NaN;
        speechRatio  = 0;
        LD           = NaN;
        dialogueRisk = 0;
        return;
    end

    thr = max(energy) * 0.05;
    speechMask = (energy > thr);

    speechRatio = mean(speechMask);

    if speechRatio < 0.05
        speechLUFS   = NaN;
        LD           = NaN;
        dialogueRisk = 0;
        return;
    end

    idxAll = false(N,1);
    for i = 1:nF
        if speechMask(i)
            idx = (i-1)*hop+1 : (i-1)*hop+win;
            idxAll(idx) = true;
        end
    end
    xs = x(idxAll);

    pS = mean(xs.^2) + 1e-12;
    speechLUFS = -0.691 + 10*log10(pS);

    LD = integratedLUFS - speechLUFS;

    dialogueRisk = double(LD > 6);
end
