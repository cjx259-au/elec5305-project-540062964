function export_html_report(cfg)
% EXPORT_HTML_REPORT  Comprehensive HTML report for ELEC5305 project.
%
% Sections:
%   - Executive Summary
%   - Complete Metrics Table (all rows)
%   - Platform Compliance (all data)
%   - All Visualizations
%   - Additional Analysis Results
%
% Displays ALL results and ALL figures in a comprehensive report.

    if nargin < 1 || isempty(cfg), cfg = config(); end

    resultsDir = cfg.resultsDir;
    figDir     = cfg.figDir;

    if ~exist(resultsDir,'dir')
        error('Results dir %s does not exist.',resultsDir);
    end
    if ~exist(figDir,'dir'), mkdir(figDir); end

    % Read all available CSV files
    metricsCsv   = fullfile(resultsDir,'metrics.csv');
    normCsv      = fullfile(resultsDir,'normalization.csv');
    platCsv1     = fullfile(resultsDir,'summary_platform.csv');
    platCsv2     = fullfile(resultsDir,'compliance_platform.csv');
    codecCsv     = fullfile(resultsDir,'codec_overshoot.csv');
    listenCsv    = fullfile(resultsDir,'platform_listening.csv');
    adaptiveCsv  = fullfile(resultsDir,'adaptive_mastering.csv');
    tpSensCsv    = fullfile(resultsDir,'tp_sensitivity.csv');
    spectralCsv  = fullfile(resultsDir,'codec_spectral_distortion.csv');
    dynamicsCsv  = fullfile(resultsDir,'codec_dynamics_profile.csv');
    normSimCsv   = fullfile(resultsDir,'platform_normalization.csv');

    Tm  = safeRead(metricsCsv);
    Tn  = safeRead(normCsv);
    Tp  = safeRead(platCsv1);
    if isempty(Tp), Tp = safeRead(platCsv2); end
    Tc  = safeRead(codecCsv);
    Tl  = safeRead(listenCsv);
    Ta  = safeRead(adaptiveCsv);
    Tts = safeRead(tpSensCsv);
    Tsp = safeRead(spectralCsv);
    Tdy = safeRead(dynamicsCsv);
    Tns = safeRead(normSimCsv);

    htmlFile = fullfile(resultsDir,'report.html');
    fid = fopen(htmlFile,'w');
    assert(fid>0,'Cannot open %s for writing.',htmlFile);

    % Enhanced HTML with better styling
    fprintf(fid,'<!DOCTYPE html>\n<html>\n<head>\n');
    fprintf(fid,'<meta charset="UTF-8">\n');
    fprintf(fid,'<meta name="viewport" content="width=device-width, initial-scale=1.0">\n');
    fprintf(fid,'<title>%s</title>\n', cfg.reportTitle);
    fprintf(fid,'<style>\n');
    fprintf(fid,'body{font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Arial,sans-serif;margin:20px;background:#f5f5f5;}\n');
    fprintf(fid,'.container{max-width:1400px;margin:0 auto;background:white;padding:30px;box-shadow:0 2px 10px rgba(0,0,0,0.1);}\n');
    fprintf(fid,'h1{font-size:36px;margin-bottom:8px;color:#2c3e50;border-bottom:3px solid #3498db;padding-bottom:10px;}\n');
    fprintf(fid,'h2{margin-top:32px;border-bottom:2px solid #ccc;padding-bottom:8px;color:#34495e;font-size:24px;}\n');
    fprintf(fid,'h3{margin-top:24px;color:#555;font-size:18px;}\n');
    fprintf(fid,'.summary-box{background:#ecf0f1;border-left:4px solid #3498db;padding:15px;margin:15px 0;border-radius:4px;}\n');
    fprintf(fid,'.summary-box strong{color:#2c3e50;}\n');
    fprintf(fid,'table{border-collapse:collapse;width:100%%;margin:15px 0;font-size:12px;}\n');
    fprintf(fid,'table th{background:#34495e;color:white;padding:10px;text-align:left;font-weight:bold;}\n');
    fprintf(fid,'table td{padding:8px;border:1px solid #ddd;}\n');
    fprintf(fid,'table tr:nth-child(even){background:#f9f9f9;}\n');
    fprintf(fid,'table tr:hover{background:#e8f4f8;}\n');
    fprintf(fid,'pre{background:#f7f7f7;border:1px solid #ddd;padding:15px;overflow:auto;font-family:Consolas,monospace;font-size:11px;line-height:1.4;max-height:600px;}\n');
    fprintf(fid,'img{max-width:100%%;height:auto;margin:15px 0;display:block;border:1px solid #ddd;border-radius:4px;}\n');
    fprintf(fid,'figure{margin:25px 0;padding:15px;border:1px solid #ddd;background:#fafafa;border-radius:6px;}\n');
    fprintf(fid,'figcaption{margin-top:10px;font-weight:bold;color:#333;font-size:13px;}\n');
    fprintf(fid,'.toggle-btn{background:#3498db;color:white;border:none;padding:8px 15px;cursor:pointer;border-radius:4px;margin:10px 0;}\n');
    fprintf(fid,'.toggle-btn:hover{background:#2980b9;}\n');
    fprintf(fid,'.collapsible{display:none;}\n');
    fprintf(fid,'.collapsible.show{display:block;}\n');
    fprintf(fid,'.file-link{color:#3498db;text-decoration:none;}\n');
    fprintf(fid,'.file-link:hover{text-decoration:underline;}\n');
    fprintf(fid,'.stats-grid{display:grid;grid-template-columns:repeat(auto-fit, minmax(200px, 1fr));gap:15px;margin:20px 0;}\n');
    fprintf(fid,'.stat-card{background:white;border:1px solid #ddd;padding:15px;border-radius:6px;text-align:center;}\n');
    fprintf(fid,'.stat-value{font-size:28px;font-weight:bold;color:#3498db;}\n');
    fprintf(fid,'.stat-label{font-size:12px;color:#7f8c8d;margin-top:5px;}\n');
    fprintf(fid,'</style>\n');
    fprintf(fid,'<script>\n');
    fprintf(fid,'function toggleSection(id) {\n');
    fprintf(fid,'  var elem = document.getElementById(id);\n');
    fprintf(fid,'  elem.classList.toggle("show");\n');
    fprintf(fid,'  var btn = document.querySelector("[onclick=\\"toggleSection(''" + id + "'')\\"]");\n');
    fprintf(fid,'  if (elem.classList.contains("show")) {\n');
    fprintf(fid,'    btn.textContent = "Hide Full Table";\n');
    fprintf(fid,'  } else {\n');
    fprintf(fid,'    btn.textContent = "Show Full Table";\n');
    fprintf(fid,'  }\n');
    fprintf(fid,'}\n');
    fprintf(fid,'</script>\n');
    fprintf(fid,'</head>\n<body>\n');
    fprintf(fid,'<div class="container">\n');

    fprintf(fid,'<h1>%s</h1>\n', cfg.reportTitle);
    fprintf(fid,'<p style="color:#7f8c8d;"><em>Generated on: %s</em></p>\n', datestr(now, 31));

    % ============================================================
    % Executive Summary
    % ============================================================
    fprintf(fid,'<h2>Executive Summary</h2>\n');
    fprintf(fid,'<div class="summary-box">\n');
    
    if ~isempty(Tm) && height(Tm) > 0
        fprintf(fid,'<div class="stats-grid">\n');
        fprintf(fid,'<div class="stat-card"><div class="stat-value">%d</div><div class="stat-label">Audio Files</div></div>\n', height(Tm));
        
        if ismember('integratedLUFS', Tm.Properties.VariableNames)
            meanLUFS = mean(Tm.integratedLUFS, 'omitnan');
            stdLUFS = std(Tm.integratedLUFS, 'omitnan');
            fprintf(fid,'<div class="stat-card"><div class="stat-value">%.2f</div><div class="stat-label">Mean LUFS (σ=%.2f)</div></div>\n', meanLUFS, stdLUFS);
        end
        
        if ismember('LRA', Tm.Properties.VariableNames)
            meanLRA = mean(Tm.LRA, 'omitnan');
            fprintf(fid,'<div class="stat-card"><div class="stat-value">%.2f</div><div class="stat-label">Mean LRA (LU)</div></div>\n', meanLRA);
        end
        
        if ismember('truePeak_dBTP', Tm.Properties.VariableNames)
            meanTP = mean(Tm.truePeak_dBTP, 'omitnan');
            overCeil = sum(Tm.truePeak_dBTP > cfg.tpCeil);
            fprintf(fid,'<div class="stat-card"><div class="stat-value">%.2f</div><div class="stat-label">Mean TP (dBTP)</div></div>\n', meanTP);
            fprintf(fid,'<div class="stat-card"><div class="stat-value">%d</div><div class="stat-label">Files Over TP Ceiling</div></div>\n', overCeil);
        end
        
        if ~isempty(Tp) && height(Tp) > 0
            if ismember('limited_rate', Tp.Properties.VariableNames)
                avgLimited = mean(Tp.limited_rate, 'omitnan') * 100;
                fprintf(fid,'<div class="stat-card"><div class="stat-value">%.1f%%</div><div class="stat-label">Avg Limiter Rate</div></div>\n', avgLimited);
            end
        end
        
        fprintf(fid,'</div>\n');
    end
    
    fprintf(fid,'</div>\n');

    % ============================================================
    % Complete Metrics Table
    % ============================================================
    if ~isempty(Tm) && height(Tm) > 0
        fprintf(fid,'<h2>Complete Audio Metrics</h2>\n');
        fprintf(fid,'<p><strong>Total files:</strong> %d</p>\n', height(Tm));
        
        % Detailed statistics
        if ismember('integratedLUFS', Tm.Properties.VariableNames)
            meanLUFS = mean(Tm.integratedLUFS, 'omitnan');
            stdLUFS = std(Tm.integratedLUFS, 'omitnan');
            minLUFS = min(Tm.integratedLUFS, 'omitnan');
            maxLUFS = max(Tm.integratedLUFS, 'omitnan');
            fprintf(fid,'<div class="summary-box">\n');
            fprintf(fid,'<p><strong>Integrated Loudness:</strong> Mean = %.2f LUFS, Std = %.2f LUFS, Range = [%.2f, %.2f] LUFS</p>\n', ...
                meanLUFS, stdLUFS, minLUFS, maxLUFS);
            fprintf(fid,'</div>\n');
        end
        
        if ismember('LRA', Tm.Properties.VariableNames)
            meanLRA = mean(Tm.LRA, 'omitnan');
            stdLRA = std(Tm.LRA, 'omitnan');
            fprintf(fid,'<div class="summary-box">\n');
            fprintf(fid,'<p><strong>Loudness Range (LRA):</strong> Mean = %.2f LU, Std = %.2f LU</p>\n', meanLRA, stdLRA);
            fprintf(fid,'</div>\n');
        end
        
        if ismember('truePeak_dBTP', Tm.Properties.VariableNames)
            meanTP = mean(Tm.truePeak_dBTP, 'omitnan');
            stdTP = std(Tm.truePeak_dBTP, 'omitnan');
            overCeil = sum(Tm.truePeak_dBTP > cfg.tpCeil);
            fprintf(fid,'<div class="summary-box">\n');
            fprintf(fid,'<p><strong>True Peak:</strong> Mean = %.2f dBTP, Std = %.2f dBTP, Over ceiling (%.1f dBTP): %d files (%.1f%%)</p>\n', ...
                meanTP, stdTP, cfg.tpCeil, overCeil, overCeil/height(Tm)*100);
            fprintf(fid,'</div>\n');
        end
        
        % Full table with toggle
        fprintf(fid,'<button class="toggle-btn" onclick="toggleSection(''metrics-full'')">Show Full Table</button>\n');
        fprintf(fid,'<div id="metrics-full" class="collapsible">\n');
        fprintf(fid,'<h3>Complete Metrics Table (All %d Rows)</h3>\n', height(Tm));
        fprintf(fid,'<pre>%s</pre>\n', htmlize(table_to_string(Tm)));
        fprintf(fid,'</div>\n');
        
        % Preview (first 20 rows)
        fprintf(fid,'<h3>Preview (First 20 Rows)</h3>\n');
        fprintf(fid,'<pre>%s</pre>\n', htmlize(table_head(Tm,20)));
    else
        fprintf(fid,'<h2>Audio Metrics</h2>\n');
        fprintf(fid,'<p><em>No metrics data available</em></p>\n');
    end

    % ============================================================
    % Normalization Results
    % ============================================================
    if ~isempty(Tn) && height(Tn) > 0
        fprintf(fid,'<h2>Normalization Results</h2>\n');
        fprintf(fid,'<p><strong>Total entries:</strong> %d</p>\n', height(Tn));
        
        if ismember('limited', Tn.Properties.VariableNames)
            limitedCount = sum(Tn.limited);
            fprintf(fid,'<div class="summary-box">\n');
            fprintf(fid,'<p><strong>Files requiring limiting:</strong> %d (%.1f%%)</p>\n', ...
                limitedCount, limitedCount/height(Tn)*100);
            fprintf(fid,'</div>\n');
        end
        
        fprintf(fid,'<button class="toggle-btn" onclick="toggleSection(''norm-full'')">Show Full Table</button>\n');
        fprintf(fid,'<div id="norm-full" class="collapsible">\n');
        fprintf(fid,'<h3>Complete Normalization Table (All %d Rows)</h3>\n', height(Tn));
        fprintf(fid,'<pre>%s</pre>\n', htmlize(table_to_string(Tn)));
        fprintf(fid,'</div>\n');
        
        fprintf(fid,'<h3>Preview (First 20 Rows)</h3>\n');
        fprintf(fid,'<pre>%s</pre>\n', htmlize(table_head(Tn,20)));
    end

    % ============================================================
    % Platform Compliance
    % ============================================================
    if ~isempty(Tp) && height(Tp) > 0
        fprintf(fid,'<h2>Platform Compliance Analysis</h2>\n');
        
        % Check if this is summary_platform.csv or compliance_platform.csv
        if ismember('limited_rate', Tp.Properties.VariableNames)
            % summary_platform.csv format
            fprintf(fid,'<p><strong>Total platforms:</strong> %d</p>\n', height(Tp));
            fprintf(fid,'<table>\n');
            fprintf(fid,'<tr><th>Platform</th><th>Files</th><th>Limited</th><th>Limited Rate</th>');
            if ismember('mean_postLUFS', Tp.Properties.VariableNames)
                fprintf(fid,'<th>Mean Post-LUFS</th>');
            end
            if ismember('mean_postTP', Tp.Properties.VariableNames)
                fprintf(fid,'<th>Mean Post-TP</th>');
            end
            fprintf(fid,'</tr>\n');
            
            for i = 1:height(Tp)
                plat = Tp.platform(i);
                if iscell(plat), plat = string(plat{1}); end
                fprintf(fid,'<tr><td><strong>%s</strong></td><td>%d</td><td>%d</td><td>%.1f%%</td>', ...
                    string(plat), Tp.num_items(i), Tp.num_limited(i), Tp.limited_rate(i)*100);
                if ismember('mean_postLUFS', Tp.Properties.VariableNames)
                    fprintf(fid,'<td>%.2f LUFS</td>', Tp.mean_postLUFS(i));
                end
                if ismember('mean_postTP', Tp.Properties.VariableNames)
                    fprintf(fid,'<td>%.2f dBTP</td>', Tp.mean_postTP(i));
                end
                fprintf(fid,'</tr>\n');
            end
            fprintf(fid,'</table>\n');
        else
            % compliance_platform.csv format - show full table
            fprintf(fid,'<p><strong>Total entries:</strong> %d</p>\n', height(Tp));
            fprintf(fid,'<button class="toggle-btn" onclick="toggleSection(''plat-full'')">Show Full Table</button>\n');
            fprintf(fid,'<div id="plat-full" class="collapsible">\n');
            fprintf(fid,'<h3>Complete Platform Compliance Table (All %d Rows)</h3>\n', height(Tp));
            fprintf(fid,'<pre>%s</pre>\n', htmlize(table_to_string(Tp)));
            fprintf(fid,'</div>\n');
            
            fprintf(fid,'<h3>Preview (First 30 Rows)</h3>\n');
            fprintf(fid,'<pre>%s</pre>\n', htmlize(table_head(Tp,30)));
        end
    else
        fprintf(fid,'<h2>Platform Compliance Analysis</h2>\n');
        fprintf(fid,'<p><em>No platform data available</em></p>\n');
    end

    % ============================================================
    % Codec Overshoot
    % ============================================================
    if ~isempty(Tc) && height(Tc) > 0
        fprintf(fid,'<h2>Codec Overshoot Analysis</h2>\n');
        fprintf(fid,'<p><strong>Total entries:</strong> %d</p>\n', height(Tc));
        fprintf(fid,'<button class="toggle-btn" onclick="toggleSection(''codec-full'')">Show Full Table</button>\n');
        fprintf(fid,'<div id="codec-full" class="collapsible">\n');
        fprintf(fid,'<h3>Complete Codec Overshoot Table (All %d Rows)</h3>\n', height(Tc));
        fprintf(fid,'<pre>%s</pre>\n', htmlize(table_to_string(Tc)));
        fprintf(fid,'</div>\n');
        fprintf(fid,'<h3>Preview (First 30 Rows)</h3>\n');
        fprintf(fid,'<pre>%s</pre>\n', htmlize(table_head(Tc,30)));
    end

    % ============================================================
    % Platform Listening
    % ============================================================
    if ~isempty(Tl) && height(Tl) > 0
        fprintf(fid,'<h2>Platform Listening Chain Simulation</h2>\n');
        fprintf(fid,'<p><strong>Total entries:</strong> %d</p>\n', height(Tl));
        fprintf(fid,'<button class="toggle-btn" onclick="toggleSection(''listen-full'')">Show Full Table</button>\n');
        fprintf(fid,'<div id="listen-full" class="collapsible">\n');
        fprintf(fid,'<h3>Complete Platform Listening Table (All %d Rows)</h3>\n', height(Tl));
        fprintf(fid,'<pre>%s</pre>\n', htmlize(table_to_string(Tl)));
        fprintf(fid,'</div>\n');
        fprintf(fid,'<h3>Preview (First 30 Rows)</h3>\n');
        fprintf(fid,'<pre>%s</pre>\n', htmlize(table_head(Tl,30)));
    end

    % ============================================================
    % Adaptive Mastering
    % ============================================================
    if ~isempty(Ta) && height(Ta) > 0
        fprintf(fid,'<h2>Adaptive Mastering Profiles</h2>\n');
        fprintf(fid,'<p><strong>Total entries:</strong> %d</p>\n', height(Ta));
        fprintf(fid,'<button class="toggle-btn" onclick="toggleSection(''adaptive-full'')">Show Full Table</button>\n');
        fprintf(fid,'<div id="adaptive-full" class="collapsible">\n');
        fprintf(fid,'<h3>Complete Adaptive Mastering Table (All %d Rows)</h3>\n', height(Ta));
        fprintf(fid,'<pre>%s</pre>\n', htmlize(table_to_string(Ta)));
        fprintf(fid,'</div>\n');
        fprintf(fid,'<h3>Preview (First 20 Rows)</h3>\n');
        fprintf(fid,'<pre>%s</pre>\n', htmlize(table_head(Ta,20)));
    end

    % ============================================================
    % True Peak Sensitivity
    % ============================================================
    if ~isempty(Tts) && height(Tts) > 0
        fprintf(fid,'<h2>True Peak Sensitivity Analysis</h2>\n');
        fprintf(fid,'<p><strong>Total entries:</strong> %d</p>\n', height(Tts));
        fprintf(fid,'<button class="toggle-btn" onclick="toggleSection(''tpsens-full'')">Show Full Table</button>\n');
        fprintf(fid,'<div id="tpsens-full" class="collapsible">\n');
        fprintf(fid,'<h3>Complete TP Sensitivity Table (All %d Rows)</h3>\n', height(Tts));
        fprintf(fid,'<pre>%s</pre>\n', htmlize(table_to_string(Tts)));
        fprintf(fid,'</div>\n');
        fprintf(fid,'<h3>Preview (First 20 Rows)</h3>\n');
        fprintf(fid,'<pre>%s</pre>\n', htmlize(table_head(Tts,20)));
    end

    % ============================================================
    % Codec Spectral Distortion Analysis
    % ============================================================
    if ~isempty(Tsp) && height(Tsp) > 0
        fprintf(fid,'<h2>Codec Spectral Distortion Analysis</h2>\n');
        fprintf(fid,'<p><strong>Total entries:</strong> %d</p>\n', height(Tsp));
        
        % Summary statistics
        if ismember('spectralDistortion', Tsp.Properties.VariableNames)
            meanDist = mean(Tsp.spectralDistortion, 'omitnan');
            maxDist = max(Tsp.spectralDistortion, 'omitnan');
            fprintf(fid,'<div class="summary-box">\n');
            fprintf(fid,'<p><strong>Spectral Distortion:</strong> Mean = %.2f%%, Max = %.2f%%</p>\n', meanDist, maxDist);
            fprintf(fid,'</div>\n');
        end
        
        fprintf(fid,'<button class="toggle-btn" onclick="toggleSection(''spectral-full'')">Show Full Table</button>\n');
        fprintf(fid,'<div id="spectral-full" class="collapsible">\n');
        fprintf(fid,'<h3>Complete Spectral Distortion Table (All %d Rows)</h3>\n', height(Tsp));
        fprintf(fid,'<pre>%s</pre>\n', htmlize(table_to_string(Tsp)));
        fprintf(fid,'</div>\n');
        fprintf(fid,'<h3>Preview (First 20 Rows)</h3>\n');
        fprintf(fid,'<pre>%s</pre>\n', htmlize(table_head(Tsp,20)));
    end

    % ============================================================
    % Short-term Dynamics Profile
    % ============================================================
    if ~isempty(Tdy) && height(Tdy) > 0
        fprintf(fid,'<h2>Short-term Dynamics Profile</h2>\n');
        fprintf(fid,'<p><strong>Total entries:</strong> %d</p>\n', height(Tdy));
        
        % Summary statistics
        if ismember('meanLRA_change', Tdy.Properties.VariableNames)
            meanLRAChange = mean(Tdy.meanLRA_change, 'omitnan');
            fprintf(fid,'<div class="summary-box">\n');
            fprintf(fid,'<p><strong>Mean LRA Change:</strong> %.2f LU</p>\n', meanLRAChange);
            if ismember('dynamicRange_change', Tdy.Properties.VariableNames)
                meanDRChange = mean(Tdy.dynamicRange_change, 'omitnan');
                fprintf(fid,'<p><strong>Mean Dynamic Range Change:</strong> %.2f dB</p>\n', meanDRChange);
            end
            fprintf(fid,'</div>\n');
        end
        
        fprintf(fid,'<button class="toggle-btn" onclick="toggleSection(''dynamics-full'')">Show Full Table</button>\n');
        fprintf(fid,'<div id="dynamics-full" class="collapsible">\n');
        fprintf(fid,'<h3>Complete Dynamics Profile Table (All %d Rows)</h3>\n', height(Tdy));
        fprintf(fid,'<pre>%s</pre>\n', htmlize(table_to_string(Tdy)));
        fprintf(fid,'</div>\n');
        fprintf(fid,'<h3>Preview (First 20 Rows)</h3>\n');
        fprintf(fid,'<pre>%s</pre>\n', htmlize(table_head(Tdy,20)));
    end

    % ============================================================
    % Platform Normalization Simulation
    % ============================================================
    if ~isempty(Tns) && height(Tns) > 0
        fprintf(fid,'<h2>Platform Loudness Normalization Simulation</h2>\n');
        fprintf(fid,'<p><strong>Total entries:</strong> %d</p>\n', height(Tns));
        
        % Summary statistics
        if ismember('gain_dB', Tns.Properties.VariableNames)
            meanGain = mean(Tns.gain_dB, 'omitnan');
            limitedCount = sum(Tns.limited);
            fprintf(fid,'<div class="summary-box">\n');
            fprintf(fid,'<p><strong>Mean Gain:</strong> %.2f dB</p>\n', meanGain);
            fprintf(fid,'<p><strong>Files Requiring Limiting:</strong> %d (%.1f%%)</p>\n', ...
                limitedCount, limitedCount/height(Tns)*100);
            fprintf(fid,'</div>\n');
        end
        
        fprintf(fid,'<button class="toggle-btn" onclick="toggleSection(''norm-sim-full'')">Show Full Table</button>\n');
        fprintf(fid,'<div id="norm-sim-full" class="collapsible">\n');
        fprintf(fid,'<h3>Complete Normalization Simulation Table (All %d Rows)</h3>\n', height(Tns));
        fprintf(fid,'<pre>%s</pre>\n', htmlize(table_to_string(Tns)));
        fprintf(fid,'</div>\n');
        fprintf(fid,'<h3>Preview (First 20 Rows)</h3>\n');
        fprintf(fid,'<pre>%s</pre>\n', htmlize(table_head(Tns,20)));
    end

    % ============================================================
    % ALL Visualizations
    % ============================================================
    fprintf(fid,'<h2>Visualizations</h2>\n');
    figs = dir(fullfile(figDir,'*.png'));
    if isempty(figs)
        % Also check results/figures subdirectory
        altFigDir = fullfile(resultsDir, 'figures');
        if exist(altFigDir, 'dir')
            figs = dir(fullfile(altFigDir,'*.png'));
            if ~isempty(figs)
                figDir = altFigDir;
            end
        end
    end
    
    if isempty(figs)
        fprintf(fid,'<p><em>No figures found in %s</em></p>\n',figDir);
    else
        fprintf(fid,'<p><strong>Total figures:</strong> %d</p>\n', numel(figs));
        
        % Priority order for key visualizations
        priorityFigs = {'platform_compliance.png', 'loudness_distribution.png', ...
                       'truepeak_analysis.png', 'dialogue_metrics.png', ...
                       'codec_spectral_distortion.png', 'codec_dynamics_profile.png', ...
                       'platform_normalization.png', ...
                       'hist_LRA.png', 'scatter_deltaLU_TP.png'};
        
        % Separate priority and other figures
        figNames = {figs.name};
        priorityFound = {};
        otherFigs = {};
        
        for i = 1:numel(priorityFigs)
            idx = find(strcmpi(figNames, priorityFigs{i}), 1);
            if ~isempty(idx)
                priorityFound{end+1} = figs(idx);
            end
        end
        
        for i = 1:numel(figs)
            % Check if this figure is already in priorityFound
            isPriority = false;
            for j = 1:numel(priorityFound)
                if strcmpi(priorityFound{j}.name, figs(i).name)
                    isPriority = true;
                    break;
                end
            end
            if ~isPriority
                otherFigs{end+1} = figs(i);
            end
        end
        
        % Display priority figures first with descriptions
        if ~isempty(priorityFound)
            fprintf(fid,'<h3>Key Analysis Visualizations</h3>\n');
            for i = 1:numel(priorityFound)
                imgName = priorityFound{i}.name;
                [~, figRelPath] = fileparts(figDir);
                if strcmp(figRelPath, 'figures')
                    imgRelPath = ['figures/' imgName];
                else
                    imgRelPath = imgName;
                end
                
                desc = getFigureDescription(imgName);
                
                fprintf(fid,'<figure>\n');
                fprintf(fid,'<img src="%s" alt="%s">\n', imgRelPath, imgName);
                fprintf(fid,'<figcaption>%s</figcaption>\n', desc);
                fprintf(fid,'</figure>\n');
            end
        end
        
        % Display ALL other figures
        if ~isempty(otherFigs)
            fprintf(fid,'<h3>All Additional Visualizations</h3>\n');
            for i = 1:numel(otherFigs)
                imgName = otherFigs{i}.name;
                [~, figRelPath] = fileparts(figDir);
                if strcmp(figRelPath, 'figures')
                    imgRelPath = ['figures/' imgName];
                else
                    imgRelPath = imgName;
                end
                
                fprintf(fid,'<figure>\n');
                fprintf(fid,'<img src="%s" alt="%s">\n', imgRelPath, imgName);
                fprintf(fid,'<figcaption>%s</figcaption>\n', imgName);
                fprintf(fid,'</figure>\n');
            end
        end
    end

    % ============================================================
    % File Links Section
    % ============================================================
    fprintf(fid,'<h2>Data Files</h2>\n');
    fprintf(fid,'<p>The following CSV files are available in the results directory:</p>\n');
    fprintf(fid,'<ul>\n');
    csvFiles = {'metrics.csv', 'normalization.csv', 'compliance_platform.csv', ...
                'summary_platform.csv', 'codec_overshoot.csv', 'platform_listening.csv', ...
                'adaptive_mastering.csv', 'tp_sensitivity.csv', ...
                'codec_spectral_distortion.csv', 'codec_dynamics_profile.csv', ...
                'platform_normalization.csv'};
    for i = 1:numel(csvFiles)
        csvPath = fullfile(resultsDir, csvFiles{i});
        if isfile(csvPath)
            fprintf(fid,'<li><a href="%s" class="file-link">%s</a></li>\n', csvFiles{i}, csvFiles{i});
        end
    end
    fprintf(fid,'</ul>\n');

    fprintf(fid,'</div>\n');  % Close container
    fprintf(fid,'</body>\n</html>\n');
    fclose(fid);
    fprintf('[export_html_report] Wrote comprehensive report: %s\n', htmlFile);
end

% ---------- helpers ----------
function T = safeRead(csvPath)
    if isfile(csvPath)
        try
            T = readtable(csvPath);
        catch
            T = table();
        end
    else
        T = table();
    end
end

function txt = table_head(T,N)
    if isempty(T)
        txt = '(empty table)';
        return;
    end
    n = min(N,height(T));
    Tsub = T(1:n,:);
    txt = evalc('disp(Tsub)');
end

function txt = table_to_string(T)
    % Convert entire table to string
    if isempty(T)
        txt = '(empty table)';
        return;
    end
    txt = evalc('disp(T)');
end

function s = htmlize(s)
    s = strrep(s,'&','&amp;');
    s = strrep(s,'<','&lt;');
    s = strrep(s,'>','&gt;');
end

function desc = getFigureDescription(imgName)
    % Return descriptive text for key figures
    [~, name, ~] = fileparts(imgName);
    switch lower(name)
        case 'platform_compliance'
            desc = 'Platform Compliance Analysis: Comparison of limiter activation rates, mean True Peak, and loudness across different streaming platforms';
        case 'loudness_distribution'
            desc = 'Integrated Loudness Distribution: Distribution of measured loudness values with normal distribution overlay and common target references';
        case 'truepeak_analysis'
            desc = 'True Peak Analysis: Comprehensive analysis of True Peak measurements including distribution, box plot, and statistics';
        case 'dialogue_metrics'
            desc = 'Dialogue Metrics Analysis: Speech ratio, dialogue level difference (LD), and risk assessment visualization';
        case 'hist_lra'
            desc = 'Loudness Range (LRA) Distribution: Histogram showing the distribution of Loudness Range values across all files';
        case 'scatter_deltalu_tp'
            desc = 'Gain vs True Peak: Scatter plot showing the relationship between applied gain and resulting True Peak after normalization';
        case 'codec_spectral_distortion'
            desc = 'Codec Spectral Distortion: Analysis of spectral changes (centroid, spread, rolloff) introduced by codec encoding/decoding';
        case 'codec_dynamics_profile'
            desc = 'Short-term Dynamics Profile: Analysis of dynamic range and LRA changes in short-term windows after codec processing';
        case 'platform_normalization'
            desc = 'Platform Loudness Normalization Simulation: Comprehensive analysis of gain application, limiting, and post-normalization metrics';
        otherwise
            desc = imgName;
    end
end
