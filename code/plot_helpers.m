function plot_helpers(kind, cfg)
% PLOT_HELPERS
% ----------------------------------------------------------
% Generate enhanced, publication-quality figures for ELEC5305 project
%
% Available plots:
%   - 'hist_LRA' - Loudness Range histogram
%   - 'scatter_deltalu_tp' - Gain vs True Peak scatter
%   - 'platform_compliance' - Platform compliance comparison
%   - 'loudness_distribution' - Integrated loudness distribution
%   - 'truepeak_analysis' - True Peak analysis
%   - 'dialogue_metrics' - Dialogue metrics visualization
%   - 'all' - Generate all plots
%
% Usage:
%   plot_helpers('all');
%   plot_helpers('platform_compliance');
%
% Safe: missing files → warning only.
% ----------------------------------------------------------

    if nargin < 2 || isempty(cfg)
        cfg = config();
    end
    if nargin < 1 || isempty(kind)
        kind = 'all';
    end

    figDir = cfg.figDir;
    if ~exist(figDir, 'dir')
        mkdir(figDir);
    end

    % Set default figure style
    set(0, 'DefaultFigureColor', 'white');
    set(0, 'DefaultAxesFontSize', 11);
    set(0, 'DefaultAxesFontName', 'Arial');
    set(0, 'DefaultTextFontName', 'Arial');

    switch lower(kind)
        case 'hist_lra'
            do_hist_LRA(cfg, figDir);

        case 'scatter_deltalu_tp'
            do_scatter_deltaLU_TP(cfg, figDir);

        case 'platform_compliance'
            do_platform_compliance(cfg, figDir);

        case 'loudness_distribution'
            do_loudness_distribution(cfg, figDir);

        case 'truepeak_analysis'
            do_truepeak_analysis(cfg, figDir);

        case 'dialogue_metrics'
            do_dialogue_metrics_plot(cfg, figDir);

        case 'codec_spectral'
            do_codec_spectral_analysis(cfg, figDir);

        case 'codec_dynamics'
            do_codec_dynamics_analysis(cfg, figDir);

        case 'normalization_simulation'
            do_normalization_simulation_plot(cfg, figDir);

        case 'all'
            fprintf('Generating all plots...\n');
            do_hist_LRA(cfg, figDir);
            do_scatter_deltaLU_TP(cfg, figDir);
            do_platform_compliance(cfg, figDir);
            do_loudness_distribution(cfg, figDir);
            do_truepeak_analysis(cfg, figDir);
            do_dialogue_metrics_plot(cfg, figDir);
            
            % Codec analysis plots (only if FFmpeg was available and analyze_codec_distortion ran)
            fprintf('  Checking for codec analysis results...\n');
            do_codec_spectral_analysis(cfg, figDir);
            do_codec_dynamics_analysis(cfg, figDir);
            do_normalization_simulation_plot(cfg, figDir);
            
            fprintf('All plots generated successfully.\n');

        otherwise
            warning('plot_helpers:unknownKind', ...
                'Unknown plot type "%s". Available: hist_LRA, scatter_deltalu_tp, platform_compliance, loudness_distribution, truepeak_analysis, dialogue_metrics, codec_spectral, codec_dynamics, normalization_simulation, all', kind);
    end
end


% =====================================================================
% 1) Enhanced LRA Histogram
% =====================================================================
function do_hist_LRA(cfg, figDir)

    metricsCsv = fullfile(cfg.resultsDir, 'metrics.csv');
    if ~isfile(metricsCsv)
        warning('plot_helpers:missingMetrics', ...
            'Missing metrics.csv → skip LRA histogram.');
        return;
    end

    Tm = readtable(metricsCsv);

    if ~ismember('LRA', Tm.Properties.VariableNames)
        warning('plot_helpers:noLRA', ...
            'metrics.csv has no LRA column → skip hist_LRA.');
        return;
    end

    LRA = Tm.LRA;
    LRA = LRA(~isnan(LRA) & isfinite(LRA));

    if isempty(LRA)
        warning('plot_helpers:emptyLRA', ...
            'LRA column empty → skip hist.');
        return;
    end

    % Create figure with better styling
    f = figure('Position', [100, 100, 800, 600], 'Color', 'white', 'Visible', 'off');
    
    % Calculate optimal bin count
    nBins = min(20, max(10, round(sqrt(numel(LRA)))));
    
    % Create histogram with better colors
    h = histogram(LRA, nBins, 'FaceColor', [0.2, 0.5, 0.8], ...
                  'EdgeColor', 'white', 'LineWidth', 1.2, ...
                  'FaceAlpha', 0.7);
    
    % Add statistics
    meanLRA = mean(LRA);
    medianLRA = median(LRA);
    stdLRA = std(LRA);
    
    % Add vertical lines for statistics
    hold on;
    xline(meanLRA, '--r', 'LineWidth', 2, 'DisplayName', sprintf('Mean: %.2f LU', meanLRA));
    xline(medianLRA, '--g', 'LineWidth', 2, 'DisplayName', sprintf('Median: %.2f LU', medianLRA));
    hold off;
    
    % Enhanced labels and title
    xlabel('Loudness Range (LU)', 'FontSize', 13, 'FontWeight', 'bold');
    ylabel('Number of Files', 'FontSize', 13, 'FontWeight', 'bold');
    title(sprintf('Loudness Range (LRA) Distribution\n(n=%d files, Mean=%.2f±%.2f LU)', ...
        numel(LRA), meanLRA, stdLRA), 'FontSize', 14, 'FontWeight', 'bold');
    
    % Add grid and legend
    grid on;
    grid minor;
    legend('Location', 'best', 'FontSize', 10);
    
    % Add text box with statistics
    statsText = sprintf('Statistics:\nMean: %.2f LU\nMedian: %.2f LU\nStd: %.2f LU\nMin: %.2f LU\nMax: %.2f LU', ...
        meanLRA, medianLRA, stdLRA, min(LRA), max(LRA));
    annotation('textbox', [0.15, 0.7, 0.2, 0.15], ...
               'String', statsText, 'FontSize', 9, ...
               'BackgroundColor', 'white', 'EdgeColor', 'black', ...
               'LineWidth', 1, 'FitBoxToText', 'on');
    
    % Improve axes
    ax = gca;
    ax.FontSize = 11;
    ax.LineWidth = 1.5;
    ax.Box = 'on';
    
    outPng = fullfile(figDir, 'hist_LRA.png');
    try
        print(f, outPng, '-dpng', '-r300');
        fprintf('  ✓ Generated: %s\n', outPng);
    catch ME
        warning('plot_helpers:saveFail', ...
            'Failed saving %s: %s', outPng, ME.message);
    end
    close(f);
end


% =====================================================================
% 2) Enhanced ΔLUFS vs postTP Scatter
% =====================================================================
function do_scatter_deltaLU_TP(cfg, figDir)

    metricsCsv = fullfile(cfg.resultsDir, 'metrics.csv');
    compCsv = fullfile(cfg.resultsDir, 'compliance_platform.csv');

    if ~isfile(metricsCsv)
        warning('plot_helpers:missingMetrics', ...
            'Missing metrics.csv → skip scatter.');
        return;
    end

    Tm = readtable(metricsCsv);

    if ~ismember('file', Tm.Properties.VariableNames) || ...
       ~ismember('integratedLUFS', Tm.Properties.VariableNames)
        warning('plot_helpers:badMetricsCols', ...
            'metrics.csv missing required columns → skip scatter.');
        return;
    end

    % Try to get postTP from compliance_platform.csv if available
    if isfile(compCsv)
        Tc = readtable(compCsv);
        if ismember('file', Tc.Properties.VariableNames) && ...
           ismember('postTP', Tc.Properties.VariableNames) && ...
           ismember('gain_dB', Tc.Properties.VariableNames)
            % Use compliance_platform.csv data
            fnM = string(Tm.file);
            fnC = string(Tc.file);
            [common, idxM, idxC] = intersect(fnM, fnC, 'stable');
            
            if ~isempty(common)
                integLUFS = Tm.integratedLUFS(idxM);
                postTP = Tc.postTP(idxC);
                deltaLU = Tc.gain_dB(idxC);
                limited = Tc.limited(idxC);
            else
                % Fallback to simple calculation
                integLUFS = Tm.integratedLUFS;
                deltaLU = cfg.streamTargetLUFS - integLUFS;
                postTP = Tm.truePeak_dBTP + deltaLU;
                limited = postTP > cfg.tpCeil;
            end
        else
            % Fallback
            integLUFS = Tm.integratedLUFS;
            deltaLU = cfg.streamTargetLUFS - integLUFS;
            postTP = Tm.truePeak_dBTP + deltaLU;
            limited = postTP > cfg.tpCeil;
        end
    else
        % Simple calculation
        integLUFS = Tm.integratedLUFS;
        deltaLU = cfg.streamTargetLUFS - integLUFS;
        postTP = Tm.truePeak_dBTP + deltaLU;
        limited = postTP > cfg.tpCeil;
    end

    % Remove invalid data
    valid = isfinite(deltaLU) & isfinite(postTP);
    deltaLU = deltaLU(valid);
    postTP = postTP(valid);
    if exist('limited', 'var')
        limited = limited(valid);
    else
        limited = postTP > cfg.tpCeil;
    end

    if isempty(deltaLU)
        warning('plot_helpers:noValidData', ...
            'No valid data for scatter plot.');
        return;
    end

    % Create enhanced scatter plot
    f = figure('Position', [100, 100, 900, 700], 'Color', 'white', 'Visible', 'off');
    
    % Color code by limited status
    colors = [0.8, 0.2, 0.2; 0.2, 0.6, 0.2];  % Red for limited, green for safe
    if exist('limited', 'var') && numel(limited) == numel(deltaLU)
        limitedIdx = logical(limited);
        scatter(deltaLU(~limitedIdx), postTP(~limitedIdx), 80, colors(2,:), ...
                'filled', 'MarkerEdgeColor', 'white', 'LineWidth', 1.5, ...
                'DisplayName', 'Compliant');
        hold on;
        scatter(deltaLU(limitedIdx), postTP(limitedIdx), 80, colors(1,:), ...
                'filled', 'MarkerEdgeColor', 'white', 'LineWidth', 1.5, ...
                'DisplayName', 'Limited');
    else
        scatter(deltaLU, postTP, 80, [0.2, 0.5, 0.8], 'filled', ...
                'MarkerEdgeColor', 'white', 'LineWidth', 1.5);
    end
    
    % Add TP ceiling line
    hold on;
    yline(cfg.tpCeil, '--k', 'LineWidth', 2, ...
          'DisplayName', sprintf('TP Ceiling (%.1f dBTP)', cfg.tpCeil));
    
    % Add target LUFS line
    xline(0, '--', 'Color', [0.5, 0.5, 0.5], 'LineWidth', 1.5, ...
          'DisplayName', 'Target LUFS');
    
    hold off;
    
    % Enhanced labels
    xlabel('Gain Applied (ΔLUFS = Target - Measured) [dB]', ...
           'FontSize', 13, 'FontWeight', 'bold');
    ylabel('Post-Normalization True Peak [dBTP]', ...
           'FontSize', 13, 'FontWeight', 'bold');
    title(sprintf('Gain vs True Peak After Normalization\n(n=%d files)', numel(deltaLU)), ...
          'FontSize', 14, 'FontWeight', 'bold');
    
    % Add statistics
    if exist('limited', 'var')
        limitedRate = sum(limited) / numel(limited) * 100;
        statsText = sprintf('Compliance Rate: %.1f%%\nLimited: %d/%d files', ...
            (1-limitedRate/100)*100, sum(limited), numel(limited));
    else
        statsText = sprintf('Total Files: %d', numel(deltaLU));
    end
    
    annotation('textbox', [0.15, 0.15, 0.25, 0.1], ...
               'String', statsText, 'FontSize', 10, ...
               'BackgroundColor', 'white', 'EdgeColor', 'black', ...
               'LineWidth', 1, 'FitBoxToText', 'on');
    
    grid on;
    grid minor;
    legend('Location', 'best', 'FontSize', 10);
    
    ax = gca;
    ax.FontSize = 11;
    ax.LineWidth = 1.5;
    ax.Box = 'on';
    
    outPng = fullfile(figDir, 'scatter_deltaLU_TP.png');
    try
        print(f, outPng, '-dpng', '-r300');
        fprintf('  ✓ Generated: %s\n', outPng);
    catch ME
        warning('plot_helpers:saveFail', ...
            'Failed saving %s: %s', outPng, ME.message);
    end
    close(f);
end


% =====================================================================
% 3) Platform Compliance Comparison (NEW)
% =====================================================================
function do_platform_compliance(cfg, figDir)

    compCsv = fullfile(cfg.resultsDir, 'compliance_platform.csv');
    if ~isfile(compCsv)
        warning('plot_helpers:missingCompliance', ...
            'Missing compliance_platform.csv → skip platform compliance plot.');
        return;
    end

    Tc = readtable(compCsv);
    
    if ~ismember('platform', Tc.Properties.VariableNames) || ...
       ~ismember('limited', Tc.Properties.VariableNames)
        warning('plot_helpers:badComplianceCols', ...
            'compliance_platform.csv missing required columns.');
        return;
    end

    platforms = unique(string(Tc.platform), 'stable');
    nPlats = numel(platforms);
    
    if nPlats == 0
        warning('plot_helpers:noPlatforms', 'No platforms found.');
        return;
    end

    % Calculate statistics per platform
    limitedRates = zeros(nPlats, 1);
    meanPostTP = zeros(nPlats, 1);
    meanPostLUFS = zeros(nPlats, 1);
    nFiles = zeros(nPlats, 1);

    for p = 1:nPlats
        mask = string(Tc.platform) == platforms(p);
        nFiles(p) = sum(mask);
        if nFiles(p) > 0
            limitedRates(p) = sum(Tc.limited(mask)) / nFiles(p) * 100;
            if ismember('postTP', Tc.Properties.VariableNames)
                meanPostTP(p) = mean(Tc.postTP(mask), 'omitnan');
            end
            if ismember('postLUFS', Tc.Properties.VariableNames)
                meanPostLUFS(p) = mean(Tc.postLUFS(mask), 'omitnan');
            end
        end
    end

    % Create figure with subplots
    f = figure('Position', [100, 100, 1200, 800], 'Color', 'white', 'Visible', 'off');
    
    % Subplot 1: Limited rate bar chart
    subplot(2, 2, 1);
    bar(limitedRates, 'FaceColor', [0.8, 0.3, 0.3], 'EdgeColor', 'white', 'LineWidth', 1.5);
    set(gca, 'XTickLabel', platforms, 'XTickLabelRotation', 45);
    ylabel('Limited Rate [%]', 'FontSize', 12, 'FontWeight', 'bold');
    title('Platform Limiter Activation Rate', 'FontSize', 13, 'FontWeight', 'bold');
    grid on;
    grid minor;
    ylim([0, max(100, max(limitedRates)*1.1)]);
    
    % Add value labels on bars
    for p = 1:nPlats
        text(p, limitedRates(p) + 2, sprintf('%.1f%%', limitedRates(p)), ...
             'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold');
    end
    
    % Subplot 2: Mean post-TP
    subplot(2, 2, 2);
    bar(meanPostTP, 'FaceColor', [0.3, 0.6, 0.8], 'EdgeColor', 'white', 'LineWidth', 1.5);
    hold on;
    yline(cfg.tpCeil, '--r', 'LineWidth', 2, 'DisplayName', sprintf('TP Ceiling (%.1f dBTP)', cfg.tpCeil));
    hold off;
    set(gca, 'XTickLabel', platforms, 'XTickLabelRotation', 45);
    ylabel('Mean Post-TP [dBTP]', 'FontSize', 12, 'FontWeight', 'bold');
    title('Mean True Peak After Normalization', 'FontSize', 13, 'FontWeight', 'bold');
    grid on;
    grid minor;
    legend('Location', 'best', 'FontSize', 9);
    
    % Subplot 3: Mean post-LUFS
    subplot(2, 2, 3);
    bar(meanPostLUFS, 'FaceColor', [0.4, 0.7, 0.4], 'EdgeColor', 'white', 'LineWidth', 1.5);
    set(gca, 'XTickLabel', platforms, 'XTickLabelRotation', 45);
    ylabel('Mean Post-LUFS [LUFS]', 'FontSize', 12, 'FontWeight', 'bold');
    title('Mean Loudness After Normalization', 'FontSize', 13, 'FontWeight', 'bold');
    grid on;
    grid minor;
    
    % Subplot 4: Number of files per platform
    subplot(2, 2, 4);
    bar(nFiles, 'FaceColor', [0.7, 0.5, 0.3], 'EdgeColor', 'white', 'LineWidth', 1.5);
    set(gca, 'XTickLabel', platforms, 'XTickLabelRotation', 45);
    ylabel('Number of Files', 'FontSize', 12, 'FontWeight', 'bold');
    title('Files Analyzed per Platform', 'FontSize', 13, 'FontWeight', 'bold');
    grid on;
    grid minor;
    
    % Add value labels
    for p = 1:nPlats
        text(p, nFiles(p) + max(nFiles)*0.02, sprintf('%d', nFiles(p)), ...
             'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold');
    end
    
    sgtitle('Platform Compliance Analysis', 'FontSize', 16, 'FontWeight', 'bold');
    
    outPng = fullfile(figDir, 'platform_compliance.png');
    try
        print(f, outPng, '-dpng', '-r300');
        fprintf('  ✓ Generated: %s\n', outPng);
    catch ME
        warning('plot_helpers:saveFail', 'Failed saving %s: %s', outPng, ME.message);
    end
    close(f);
end


% =====================================================================
% 4) Loudness Distribution (NEW)
% =====================================================================
function do_loudness_distribution(cfg, figDir)

    metricsCsv = fullfile(cfg.resultsDir, 'metrics.csv');
    if ~isfile(metricsCsv)
        warning('plot_helpers:missingMetrics', 'Missing metrics.csv → skip loudness distribution.');
        return;
    end

    Tm = readtable(metricsCsv);
    
    if ~ismember('integratedLUFS', Tm.Properties.VariableNames)
        warning('plot_helpers:noLUFS', 'metrics.csv has no integratedLUFS column.');
        return;
    end

    LUFS = Tm.integratedLUFS;
    LUFS = LUFS(~isnan(LUFS) & isfinite(LUFS));

    if isempty(LUFS)
        warning('plot_helpers:emptyLUFS', 'No valid LUFS data.');
        return;
    end

    f = figure('Position', [100, 100, 900, 600], 'Color', 'white', 'Visible', 'off');
    
    % Create histogram with normal distribution overlay
    nBins = min(25, max(15, round(sqrt(numel(LUFS)))));
    histogram(LUFS, nBins, 'FaceColor', [0.3, 0.6, 0.9], ...
              'EdgeColor', 'white', 'LineWidth', 1.2, 'FaceAlpha', 0.7, ...
              'Normalization', 'pdf');
    hold on;
    
    % Overlay normal distribution
    mu = mean(LUFS);
    sigma = std(LUFS);
    x = linspace(min(LUFS), max(LUFS), 200);
    y = normpdf(x, mu, sigma);
    plot(x, y, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Normal Distribution');
    
    % Add reference lines for common targets
    commonTargets = [-16, -14, -12, -10];
    colors = lines(4);
    for i = 1:numel(commonTargets)
        xline(commonTargets(i), '--', 'Color', colors(i,:), 'LineWidth', 1.5, ...
              'DisplayName', sprintf('Target: %.0f LUFS', commonTargets(i)));
    end
    
    hold off;
    
    xlabel('Integrated Loudness (LUFS)', 'FontSize', 13, 'FontWeight', 'bold');
    ylabel('Probability Density', 'FontSize', 13, 'FontWeight', 'bold');
    title(sprintf('Integrated Loudness Distribution\n(n=%d files, Mean=%.2f±%.2f LUFS)', ...
        numel(LUFS), mu, sigma), 'FontSize', 14, 'FontWeight', 'bold');
    
    grid on;
    grid minor;
    legend('Location', 'best', 'FontSize', 10);
    
    % Add statistics box
    statsText = sprintf('Statistics:\nMean: %.2f LUFS\nMedian: %.2f LUFS\nStd: %.2f LUFS\nRange: [%.2f, %.2f] LUFS', ...
        mu, median(LUFS), sigma, min(LUFS), max(LUFS));
    annotation('textbox', [0.15, 0.7, 0.25, 0.15], ...
               'String', statsText, 'FontSize', 9, ...
               'BackgroundColor', 'white', 'EdgeColor', 'black', ...
               'LineWidth', 1, 'FitBoxToText', 'on');
    
    ax = gca;
    ax.FontSize = 11;
    ax.LineWidth = 1.5;
    ax.Box = 'on';
    
    outPng = fullfile(figDir, 'loudness_distribution.png');
    try
        print(f, outPng, '-dpng', '-r300');
        fprintf('  ✓ Generated: %s\n', outPng);
    catch ME
        warning('plot_helpers:saveFail', 'Failed saving %s: %s', outPng, ME.message);
    end
    close(f);
end


% =====================================================================
% 5) True Peak Analysis (NEW)
% =====================================================================
function do_truepeak_analysis(cfg, figDir)

    metricsCsv = fullfile(cfg.resultsDir, 'metrics.csv');
    if ~isfile(metricsCsv)
        warning('plot_helpers:missingMetrics', 'Missing metrics.csv → skip TP analysis.');
        return;
    end

    Tm = readtable(metricsCsv);
    
    if ~ismember('truePeak_dBTP', Tm.Properties.VariableNames)
        warning('plot_helpers:noTP', 'metrics.csv has no truePeak_dBTP column.');
        return;
    end

    TP = Tm.truePeak_dBTP;
    TP = TP(~isnan(TP) & isfinite(TP));

    if isempty(TP)
        warning('plot_helpers:emptyTP', 'No valid TP data.');
        return;
    end

    f = figure('Position', [100, 100, 1000, 700], 'Color', 'white', 'Visible', 'off');
    
    % Subplot 1: Histogram
    subplot(2, 2, 1);
    nBins = min(20, max(10, round(sqrt(numel(TP)))));
    histogram(TP, nBins, 'FaceColor', [0.8, 0.4, 0.2], ...
              'EdgeColor', 'white', 'LineWidth', 1.2, 'FaceAlpha', 0.7);
    hold on;
    xline(cfg.tpCeil, '--r', 'LineWidth', 2.5, ...
          'DisplayName', sprintf('TP Ceiling (%.1f dBTP)', cfg.tpCeil));
    hold off;
    xlabel('True Peak [dBTP]', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Count', 'FontSize', 12, 'FontWeight', 'bold');
    title('True Peak Distribution', 'FontSize', 13, 'FontWeight', 'bold');
    grid on;
    grid minor;
    legend('Location', 'best', 'FontSize', 9);
    
    % Subplot 2: Box plot
    subplot(2, 2, 2);
    boxplot(TP, 'Colors', [0.8, 0.4, 0.2], 'Widths', 0.6);
    hold on;
    yline(cfg.tpCeil, '--r', 'LineWidth', 2, ...
          'DisplayName', sprintf('TP Ceiling (%.1f dBTP)', cfg.tpCeil));
    hold off;
    ylabel('True Peak [dBTP]', 'FontSize', 12, 'FontWeight', 'bold');
    title('True Peak Box Plot', 'FontSize', 13, 'FontWeight', 'bold');
    grid on;
    grid minor;
    
    % Subplot 3: Violin plot approximation (histogram rotated)
    subplot(2, 2, 3);
    [counts, edges] = histcounts(TP, nBins);
    centers = (edges(1:end-1) + edges(2:end)) / 2;
    barh(centers, counts, 'FaceColor', [0.8, 0.4, 0.2], ...
         'EdgeColor', 'white', 'LineWidth', 1);
    hold on;
    xline(cfg.tpCeil, '--r', 'LineWidth', 2);
    hold off;
    xlabel('Count', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('True Peak [dBTP]', 'FontSize', 12, 'FontWeight', 'bold');
    title('True Peak Distribution (Horizontal)', 'FontSize', 13, 'FontWeight', 'bold');
    grid on;
    grid minor;
    
    % Subplot 4: Statistics
    subplot(2, 2, 4);
    axis off;
    statsText = sprintf(['True Peak Statistics (n=%d files)\n\n' ...
                        'Mean: %.2f dBTP\n' ...
                        'Median: %.2f dBTP\n' ...
                        'Std Dev: %.2f dBTP\n' ...
                        'Min: %.2f dBTP\n' ...
                        'Max: %.2f dBTP\n' ...
                        'Q1: %.2f dBTP\n' ...
                        'Q3: %.2f dBTP\n\n' ...
                        'TP Ceiling: %.1f dBTP\n' ...
                        'Over Ceiling: %d files (%.1f%%)'], ...
        numel(TP), mean(TP), median(TP), std(TP), ...
        min(TP), max(TP), prctile(TP, 25), prctile(TP, 75), ...
        cfg.tpCeil, sum(TP > cfg.tpCeil), sum(TP > cfg.tpCeil)/numel(TP)*100);
    text(0.1, 0.5, statsText, 'FontSize', 11, 'FontName', 'Courier', ...
         'VerticalAlignment', 'middle', 'FontWeight', 'bold');
    
    sgtitle('True Peak Analysis', 'FontSize', 16, 'FontWeight', 'bold');
    
    outPng = fullfile(figDir, 'truepeak_analysis.png');
    try
        print(f, outPng, '-dpng', '-r300');
        fprintf('  ✓ Generated: %s\n', outPng);
    catch ME
        warning('plot_helpers:saveFail', 'Failed saving %s: %s', outPng, ME.message);
    end
    close(f);
end


% =====================================================================
% 6) Dialogue Metrics Visualization (NEW)
% =====================================================================
function do_dialogue_metrics_plot(cfg, figDir)

    metricsCsv = fullfile(cfg.resultsDir, 'metrics.csv');
    if ~isfile(metricsCsv)
        warning('plot_helpers:missingMetrics', 'Missing metrics.csv → skip dialogue metrics.');
        return;
    end

    Tm = readtable(metricsCsv);
    
    requiredCols = {'speechLUFS', 'speechRatio', 'LD', 'dialogueRisk'};
    hasAll = all(ismember(requiredCols, Tm.Properties.VariableNames));
    
    if ~hasAll
        warning('plot_helpers:noDialogue', 'Missing dialogue metrics columns.');
        return;
    end

    speechLUFS = Tm.speechLUFS(~isnan(Tm.speechLUFS));
    speechRatio = Tm.speechRatio(~isnan(Tm.speechRatio));
    LD = Tm.LD(~isnan(Tm.LD));
    dialogueRisk = Tm.dialogueRisk;

    if isempty(speechLUFS) && isempty(speechRatio)
        warning('plot_helpers:emptyDialogue', 'No valid dialogue metrics.');
        return;
    end

    f = figure('Position', [100, 100, 1200, 800], 'Color', 'white', 'Visible', 'off');
    
    % Subplot 1: Speech Ratio distribution
    if ~isempty(speechRatio)
        subplot(2, 3, 1);
        histogram(speechRatio * 100, 15, 'FaceColor', [0.4, 0.7, 0.4], ...
                  'EdgeColor', 'white', 'LineWidth', 1.2, 'FaceAlpha', 0.7);
        xlabel('Speech Ratio [%]', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Count', 'FontSize', 11, 'FontWeight', 'bold');
        title(sprintf('Speech Ratio Distribution\n(Mean: %.1f%%)', mean(speechRatio)*100), ...
              'FontSize', 12, 'FontWeight', 'bold');
        grid on;
        grid minor;
    end
    
    % Subplot 2: LD (Dialogue Level Difference)
    if ~isempty(LD)
        subplot(2, 3, 2);
        histogram(LD, 15, 'FaceColor', [0.7, 0.5, 0.3], ...
                  'EdgeColor', 'white', 'LineWidth', 1.2, 'FaceAlpha', 0.7);
        hold on;
        xline(6, '--r', 'LineWidth', 2, 'DisplayName', 'Risk Threshold (6 LU)');
        xline(-5, '--r', 'LineWidth', 2, 'DisplayName', 'Bad Threshold (-5 LU)');
        hold off;
        xlabel('LD (Dialogue Level Difference) [LU]', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Count', 'FontSize', 11, 'FontWeight', 'bold');
        title(sprintf('Dialogue Level Difference\n(Mean: %.2f LU)', mean(LD)), ...
              'FontSize', 12, 'FontWeight', 'bold');
        grid on;
        grid minor;
        legend('Location', 'best', 'FontSize', 8);
    end
    
    % Subplot 3: Speech LUFS vs Integrated LUFS
    if ~isempty(speechLUFS) && ismember('integratedLUFS', Tm.Properties.VariableNames)
        integLUFS = Tm.integratedLUFS(~isnan(Tm.speechLUFS));
        subplot(2, 3, 3);
        scatter(integLUFS, speechLUFS, 60, [0.3, 0.6, 0.9], 'filled', ...
                'MarkerEdgeColor', 'white', 'LineWidth', 1.5);
        hold on;
        plot([min([integLUFS; speechLUFS]), max([integLUFS; speechLUFS])], ...
             [min([integLUFS; speechLUFS]), max([integLUFS; speechLUFS])], ...
             '--k', 'LineWidth', 1.5, 'DisplayName', 'y=x');
        hold off;
        xlabel('Integrated LUFS [LUFS]', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Speech LUFS [LUFS]', 'FontSize', 11, 'FontWeight', 'bold');
        title('Speech vs Integrated Loudness', 'FontSize', 12, 'FontWeight', 'bold');
        grid on;
        grid minor;
        legend('Location', 'best', 'FontSize', 9);
    end
    
    % Subplot 4: Dialogue Risk pie chart
    if any(dialogueRisk == 1) || any(dialogueRisk == 0)
        subplot(2, 3, 4);
        riskCount = [sum(dialogueRisk == 0), sum(dialogueRisk == 1)];
        pie(riskCount, {'Safe', 'At Risk'});
        colormap([0.2, 0.7, 0.2; 0.8, 0.2, 0.2]);
        title(sprintf('Dialogue Risk Assessment\n(At Risk: %.1f%%)', ...
            sum(dialogueRisk)/numel(dialogueRisk)*100), ...
            'FontSize', 12, 'FontWeight', 'bold');
    end
    
    % Subplot 5: Speech Ratio vs LD scatter
    if ~isempty(speechRatio) && ~isempty(LD) && numel(speechRatio) == numel(LD)
        subplot(2, 3, 5);
        scatter(speechRatio * 100, LD, 60, [0.5, 0.3, 0.7], 'filled', ...
                'MarkerEdgeColor', 'white', 'LineWidth', 1.5);
        xlabel('Speech Ratio [%]', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('LD [LU]', 'FontSize', 11, 'FontWeight', 'bold');
        title('Speech Ratio vs Dialogue Level', 'FontSize', 12, 'FontWeight', 'bold');
        grid on;
        grid minor;
    end
    
    % Subplot 6: Statistics summary
    subplot(2, 3, 6);
    axis off;
    if ~isempty(speechRatio) && ~isempty(LD)
        statsText = sprintf(['Dialogue Metrics Summary\n\n' ...
                            'Speech Ratio:\n  Mean: %.1f%%\n  Range: [%.1f, %.1f]%%\n\n' ...
                            'LD (Dialogue Level):\n  Mean: %.2f LU\n  Range: [%.2f, %.2f] LU\n\n' ...
                            'Risk Assessment:\n  Safe: %d files\n  At Risk: %d files'], ...
            mean(speechRatio)*100, min(speechRatio)*100, max(speechRatio)*100, ...
            mean(LD), min(LD), max(LD), ...
            sum(dialogueRisk == 0), sum(dialogueRisk == 1));
    else
        statsText = 'Insufficient dialogue metrics data';
    end
    text(0.1, 0.5, statsText, 'FontSize', 10, 'FontName', 'Courier', ...
         'VerticalAlignment', 'middle', 'FontWeight', 'bold');
    
    sgtitle('Dialogue Metrics Analysis', 'FontSize', 16, 'FontWeight', 'bold');
    
    outPng = fullfile(figDir, 'dialogue_metrics.png');
    try
        print(f, outPng, '-dpng', '-r300');
        fprintf('  ✓ Generated: %s\n', outPng);
    catch ME
        warning('plot_helpers:saveFail', 'Failed saving %s: %s', outPng, ME.message);
    end
    close(f);
end

% =====================================================================
% 7) Codec Spectral Distortion Analysis
% =====================================================================
function do_codec_spectral_analysis(cfg, figDir)
    spectralCsv = fullfile(cfg.resultsDir, 'codec_spectral_distortion.csv');
    if ~isfile(spectralCsv)
        % Silent skip if file doesn't exist (likely FFmpeg not available or analyze_codec_distortion not run)
        return;
    end

    T = readtable(spectralCsv);
    if isempty(T) || height(T) == 0
        warning('plot_helpers:emptySpectral', 'Spectral CSV is empty → skip.');
        return;
    end

    f = figure('Position', [100, 100, 1400, 900], 'Color', 'white');
    
    % Subplot 1: Centroid change
    subplot(2, 3, 1);
    if ismember('centroid_change', T.Properties.VariableNames)
        histogram(T.centroid_change, 30, 'FaceColor', [0.3, 0.6, 0.9], 'EdgeColor', 'white');
        xlabel('Centroid Change [Hz]', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Frequency', 'FontSize', 11, 'FontWeight', 'bold');
        title('Spectral Centroid Change', 'FontSize', 12, 'FontWeight', 'bold');
        grid on;
        grid minor;
    end
    
    % Subplot 2: Spread change
    subplot(2, 3, 2);
    if ismember('spread_change', T.Properties.VariableNames)
        histogram(T.spread_change, 30, 'FaceColor', [0.9, 0.6, 0.3], 'EdgeColor', 'white');
        xlabel('Spread Change [Hz]', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Frequency', 'FontSize', 11, 'FontWeight', 'bold');
        title('Spectral Spread Change', 'FontSize', 12, 'FontWeight', 'bold');
        grid on;
        grid minor;
    end
    
    % Subplot 3: Rolloff change
    subplot(2, 3, 3);
    if ismember('rolloff_change', T.Properties.VariableNames)
        histogram(T.rolloff_change, 30, 'FaceColor', [0.6, 0.3, 0.9], 'EdgeColor', 'white');
        xlabel('Rolloff Change [Hz]', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Frequency', 'FontSize', 11, 'FontWeight', 'bold');
        title('Spectral Rolloff Change', 'FontSize', 12, 'FontWeight', 'bold');
        grid on;
        grid minor;
    end
    
    % Subplot 4: SNR distribution
    subplot(2, 3, 4);
    if ismember('snr', T.Properties.VariableNames)
        histogram(T.snr, 30, 'FaceColor', [0.2, 0.7, 0.5], 'EdgeColor', 'white');
        xlabel('SNR [dB]', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Frequency', 'FontSize', 11, 'FontWeight', 'bold');
        title('Signal-to-Noise Ratio', 'FontSize', 12, 'FontWeight', 'bold');
        grid on;
        grid minor;
    end
    
    % Subplot 5: Platform comparison
    subplot(2, 3, 5);
    if ismember('platform', T.Properties.VariableNames) && ismember('spectralDistortion', T.Properties.VariableNames)
        platforms = unique(T.platform);
        distMeans = zeros(numel(platforms), 1);
        for i = 1:numel(platforms)
            mask = strcmp(T.platform, platforms{i});
            distMeans(i) = mean(T.spectralDistortion(mask), 'omitnan');
        end
        bar(distMeans, 'FaceColor', [0.4, 0.4, 0.8]);
        set(gca, 'XTickLabel', platforms);
        xlabel('Platform', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Mean Spectral Distortion [%]', 'FontSize', 11, 'FontWeight', 'bold');
        title('Spectral Distortion by Platform', 'FontSize', 12, 'FontWeight', 'bold');
        grid on;
        grid minor;
        xtickangle(45);
    end
    
    % Subplot 6: Statistics
    subplot(2, 3, 6);
    axis off;
    if ismember('spectralDistortion', T.Properties.VariableNames)
        statsText = sprintf(['Spectral Distortion Summary\n\n' ...
                            'Mean: %.2f%%\n' ...
                            'Median: %.2f%%\n' ...
                            'Std: %.2f%%\n' ...
                            'Min: %.2f%%\n' ...
                            'Max: %.2f%%'], ...
            mean(T.spectralDistortion, 'omitnan'), ...
            median(T.spectralDistortion, 'omitnan'), ...
            std(T.spectralDistortion, 'omitnan'), ...
            min(T.spectralDistortion, [], 'omitnan'), ...
            max(T.spectralDistortion, [], 'omitnan'));
    else
        statsText = 'Insufficient spectral data';
    end
    text(0.1, 0.5, statsText, 'FontSize', 10, 'FontName', 'Courier', ...
         'VerticalAlignment', 'middle', 'FontWeight', 'bold');
    
    sgtitle('Codec Spectral Distortion Analysis', 'FontSize', 16, 'FontWeight', 'bold');
    
    outPng = fullfile(figDir, 'codec_spectral_distortion.png');
    try
        print(f, outPng, '-dpng', '-r300');
        fprintf('  ✓ Generated: %s\n', outPng);
    catch ME
        warning('plot_helpers:saveFail', 'Failed saving %s: %s', outPng, ME.message);
    end
    close(f);
end

% =====================================================================
% 8) Codec Dynamics Profile Analysis
% =====================================================================
function do_codec_dynamics_analysis(cfg, figDir)
    dynamicsCsv = fullfile(cfg.resultsDir, 'codec_dynamics_profile.csv');
    if ~isfile(dynamicsCsv)
        % Silent skip if file doesn't exist (likely FFmpeg not available or analyze_codec_distortion not run)
        return;
    end

    T = readtable(dynamicsCsv);
    if isempty(T) || height(T) == 0
        warning('plot_helpers:emptyDynamics', 'Dynamics CSV is empty → skip.');
        return;
    end

    f = figure('Position', [100, 100, 1400, 900], 'Color', 'white');
    
    % Subplot 1: LRA change
    subplot(2, 3, 1);
    if ismember('meanLRA_change', T.Properties.VariableNames)
        histogram(T.meanLRA_change, 30, 'FaceColor', [0.3, 0.6, 0.9], 'EdgeColor', 'white');
        xlabel('Mean LRA Change [LU]', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Frequency', 'FontSize', 11, 'FontWeight', 'bold');
        title('Short-term LRA Change', 'FontSize', 12, 'FontWeight', 'bold');
        grid on;
        grid minor;
    end
    
    % Subplot 2: Dynamic range change
    subplot(2, 3, 2);
    if ismember('dynamicRange_change', T.Properties.VariableNames)
        histogram(T.dynamicRange_change, 30, 'FaceColor', [0.9, 0.6, 0.3], 'EdgeColor', 'white');
        xlabel('Dynamic Range Change [dB]', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Frequency', 'FontSize', 11, 'FontWeight', 'bold');
        title('Dynamic Range Change', 'FontSize', 12, 'FontWeight', 'bold');
        grid on;
        grid minor;
    end
    
    % Subplot 3: Crest factor comparison
    subplot(2, 3, 3);
    if ismember('crestFactor_pre', T.Properties.VariableNames) && ismember('crestFactor_post', T.Properties.VariableNames)
        scatter(T.crestFactor_pre, T.crestFactor_post, 60, [0.5, 0.3, 0.7], 'filled', ...
                'MarkerEdgeColor', 'white', 'LineWidth', 1.5);
        hold on;
        xlims = xlim;
        plot(xlims, xlims, '--k', 'LineWidth', 1.5);
        hold off;
        xlabel('Pre-codec Crest Factor', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Post-codec Crest Factor', 'FontSize', 11, 'FontWeight', 'bold');
        title('Crest Factor Comparison', 'FontSize', 12, 'FontWeight', 'bold');
        grid on;
        grid minor;
    end
    
    % Subplot 4: Platform comparison (LRA)
    subplot(2, 3, 4);
    if ismember('platform', T.Properties.VariableNames) && ismember('meanLRA_change', T.Properties.VariableNames)
        platforms = unique(T.platform);
        lraMeans = zeros(numel(platforms), 1);
        for i = 1:numel(platforms)
            mask = strcmp(T.platform, platforms{i});
            lraMeans(i) = mean(T.meanLRA_change(mask), 'omitnan');
        end
        bar(lraMeans, 'FaceColor', [0.4, 0.8, 0.4]);
        set(gca, 'XTickLabel', platforms);
        xlabel('Platform', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Mean LRA Change [LU]', 'FontSize', 11, 'FontWeight', 'bold');
        title('LRA Change by Platform', 'FontSize', 12, 'FontWeight', 'bold');
        grid on;
        grid minor;
        xtickangle(45);
    end
    
    % Subplot 5: Codec comparison
    subplot(2, 3, 5);
    if ismember('codec', T.Properties.VariableNames) && ismember('dynamicRange_change', T.Properties.VariableNames)
        codecs = unique(T.codec);
        drMeans = zeros(numel(codecs), 1);
        for i = 1:numel(codecs)
            mask = strcmp(T.codec, codecs{i});
            drMeans(i) = mean(T.dynamicRange_change(mask), 'omitnan');
        end
        bar(drMeans, 'FaceColor', [0.8, 0.4, 0.2]);
        set(gca, 'XTickLabel', codecs);
        xlabel('Codec', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Mean Dynamic Range Change [dB]', 'FontSize', 11, 'FontWeight', 'bold');
        title('Dynamic Range Change by Codec', 'FontSize', 12, 'FontWeight', 'bold');
        grid on;
        grid minor;
        xtickangle(45);
    end
    
    % Subplot 6: Statistics
    subplot(2, 3, 6);
    axis off;
    if ismember('meanLRA_change', T.Properties.VariableNames)
        statsText = sprintf(['Short-term Dynamics Summary\n\n' ...
                            'Mean LRA Change:\n  Mean: %.2f LU\n  Std: %.2f LU\n\n' ...
                            'Dynamic Range Change:\n  Mean: %.2f dB\n  Std: %.2f dB'], ...
            mean(T.meanLRA_change, 'omitnan'), std(T.meanLRA_change, 'omitnan'), ...
            mean(T.dynamicRange_change, 'omitnan'), std(T.dynamicRange_change, 'omitnan'));
    else
        statsText = 'Insufficient dynamics data';
    end
    text(0.1, 0.5, statsText, 'FontSize', 10, 'FontName', 'Courier', ...
         'VerticalAlignment', 'middle', 'FontWeight', 'bold');
    
    sgtitle('Short-term Dynamics Profile', 'FontSize', 16, 'FontWeight', 'bold');
    
    outPng = fullfile(figDir, 'codec_dynamics_profile.png');
    try
        print(f, outPng, '-dpng', '-r300');
        fprintf('  ✓ Generated: %s\n', outPng);
    catch ME
        warning('plot_helpers:saveFail', 'Failed saving %s: %s', outPng, ME.message);
    end
    close(f);
end

% =====================================================================
% 9) Platform Loudness Normalization Simulation
% =====================================================================
function do_normalization_simulation_plot(cfg, figDir)
    normSimCsv = fullfile(cfg.resultsDir, 'platform_normalization.csv');
    if ~isfile(normSimCsv)
        % Silent skip if file doesn't exist (likely FFmpeg not available or analyze_codec_distortion not run)
        return;
    end

    T = readtable(normSimCsv);
    if isempty(T) || height(T) == 0
        warning('plot_helpers:emptyNormSim', 'Normalization CSV is empty → skip.');
        return;
    end

    f = figure('Position', [100, 100, 1400, 900], 'Color', 'white');
    
    % Subplot 1: Gain distribution
    subplot(2, 3, 1);
    if ismember('gain_dB', T.Properties.VariableNames)
        histogram(T.gain_dB, 30, 'FaceColor', [0.3, 0.6, 0.9], 'EdgeColor', 'white');
        xlabel('Gain [dB]', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Frequency', 'FontSize', 11, 'FontWeight', 'bold');
        title('Applied Gain Distribution', 'FontSize', 12, 'FontWeight', 'bold');
        grid on;
        grid minor;
    end
    
    % Subplot 2: Pre vs Post LUFS
    subplot(2, 3, 2);
    if ismember('preLUFS', T.Properties.VariableNames) && ismember('postLUFS', T.Properties.VariableNames)
        scatter(T.preLUFS, T.postLUFS, 60, [0.9, 0.6, 0.3], 'filled', ...
                'MarkerEdgeColor', 'white', 'LineWidth', 1.5);
        hold on;
        xlims = xlim;
        plot(xlims, xlims, '--k', 'LineWidth', 1.5);
        hold off;
        xlabel('Pre-normalization LUFS [LUFS]', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Post-normalization LUFS [LUFS]', 'FontSize', 11, 'FontWeight', 'bold');
        title('Loudness Normalization', 'FontSize', 12, 'FontWeight', 'bold');
        grid on;
        grid minor;
    end
    
    % Subplot 3: Limiter activation rate
    subplot(2, 3, 3);
    if ismember('limited', T.Properties.VariableNames)
        limitedCount = [sum(T.limited == 0), sum(T.limited == 1)];
        pie(limitedCount, {'No Limiting', 'Limited'});
        colormap([0.2, 0.7, 0.2; 0.8, 0.2, 0.2]);
        title(sprintf('Limiter Activation\n(Limited: %.1f%%)', ...
            sum(T.limited)/numel(T.limited)*100), ...
            'FontSize', 12, 'FontWeight', 'bold');
    end
    
    % Subplot 4: Platform comparison (gain)
    subplot(2, 3, 4);
    if ismember('platform', T.Properties.VariableNames) && ismember('gain_dB', T.Properties.VariableNames)
        platforms = unique(T.platform);
        gainMeans = zeros(numel(platforms), 1);
        for i = 1:numel(platforms)
            mask = strcmp(T.platform, platforms{i});
            gainMeans(i) = mean(T.gain_dB(mask), 'omitnan');
        end
        bar(gainMeans, 'FaceColor', [0.4, 0.4, 0.8]);
        set(gca, 'XTickLabel', platforms);
        xlabel('Platform', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Mean Gain [dB]', 'FontSize', 11, 'FontWeight', 'bold');
        title('Average Gain by Platform', 'FontSize', 12, 'FontWeight', 'bold');
        grid on;
        grid minor;
        xtickangle(45);
    end
    
    % Subplot 5: True Peak before/after
    subplot(2, 3, 5);
    if ismember('preTP', T.Properties.VariableNames) && ismember('postTP', T.Properties.VariableNames)
        scatter(T.preTP, T.postTP, 60, [0.5, 0.3, 0.7], 'filled', ...
                'MarkerEdgeColor', 'white', 'LineWidth', 1.5);
        hold on;
        xlims = xlim;
        plot(xlims, xlims, '--k', 'LineWidth', 1.5);
        hold off;
        xlabel('Pre-normalization TP [dBTP]', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Post-normalization TP [dBTP]', 'FontSize', 11, 'FontWeight', 'bold');
        title('True Peak Normalization', 'FontSize', 12, 'FontWeight', 'bold');
        grid on;
        grid minor;
    end
    
    % Subplot 6: Statistics
    subplot(2, 3, 6);
    axis off;
    if ismember('gain_dB', T.Properties.VariableNames) && ismember('limited', T.Properties.VariableNames)
        meanGR = 0;
        if ismember('meanGR', T.Properties.VariableNames)
            meanGR = mean(T.meanGR(T.limited == 1), 'omitnan');
        end
        statsText = sprintf(['Normalization Summary\n\n' ...
                            'Gain:\n  Mean: %.2f dB\n  Range: [%.2f, %.2f] dB\n\n' ...
                            'Limiter:\n  Activation: %.1f%%\n  Mean GR: %.2f dB'], ...
            mean(T.gain_dB, 'omitnan'), min(T.gain_dB, [], 'omitnan'), max(T.gain_dB, [], 'omitnan'), ...
            sum(T.limited)/numel(T.limited)*100, meanGR);
    else
        statsText = 'Insufficient normalization data';
    end
    text(0.1, 0.5, statsText, 'FontSize', 10, 'FontName', 'Courier', ...
         'VerticalAlignment', 'middle', 'FontWeight', 'bold');
    
    sgtitle('Platform Loudness Normalization Simulation', 'FontSize', 16, 'FontWeight', 'bold');
    
    outPng = fullfile(figDir, 'platform_normalization.png');
    try
        print(f, outPng, '-dpng', '-r300');
        fprintf('  ✓ Generated: %s\n', outPng);
    catch ME
        warning('plot_helpers:saveFail', 'Failed saving %s: %s', outPng, ME.message);
    end
    close(f);
end
