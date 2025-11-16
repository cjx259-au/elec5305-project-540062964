function compliance_platform(cfg)
% COMPLIANCE_PLATFORM
% 读取 metrics.csv → 生成 results/compliance_platform.csv
%
% This function generates platform compliance analysis for each audio file
% across all configured platforms (Apple Music, Spotify, YouTube, TikTok).
% Output CSV contains: file, platform, preLUFS, preTP, gain_dB, postLUFS, postTP, limited

    % ---- cfg ----
    if nargin < 1 || isempty(cfg)
        cfg = config();
    end

    metricsCsv = fullfile(cfg.resultsDir, 'metrics.csv');
    if ~exist(metricsCsv, 'file')
        warning('compliance_platform: metrics.csv not found: %s', metricsCsv);
        % 创建空表但包含正确的列名，避免创建完全空文件
        C = table(strings(0,1), strings(0,1), NaN(0,1), NaN(0,1), NaN(0,1), ...
                  NaN(0,1), NaN(0,1), zeros(0,1), ...
                  'VariableNames', {'file','platform','preLUFS','preTP','gain_dB', ...
                                  'postLUFS','postTP','limited'});
        outCsv = fullfile(cfg.resultsDir, 'compliance_platform.csv');
        try
            writetable(C, outCsv, 'WriteMode', 'overwrite');
            fprintf('[compliance_platform] Created empty %s (metrics.csv not found)\n', outCsv);
        catch
            warning('compliance_platform: Failed to create empty CSV');
        end
        return;
    end

    try
        T = readtable(metricsCsv);
    catch ME
        warning('compliance_platform: Failed to read metrics.csv: %s', ME.message);
        return;
    end
    
    % 验证必要的列存在
    requiredCols = {'file', 'integratedLUFS', 'truePeak_dBTP'};
    missingCols = setdiff(requiredCols, T.Properties.VariableNames);
    if ~isempty(missingCols)
        warning('compliance_platform: metrics.csv missing required columns: %s', strjoin(missingCols, ', '));
        return;
    end

    % ---- 从 cfg.platforms 读取平台列表（不再硬编码） ----
    if isfield(cfg, 'platforms') && ~isempty(cfg.platforms)
        % Use platforms from config
        plats = cfg.platforms;
        nPlats = numel(plats);
        fprintf('[compliance_platform] Using %d platforms from cfg.platforms\n', nPlats);
    else
        % Fallback: use default platforms
        warning('cfg.platforms not found, using default platforms');
        plats = platform_presets();  % Get all platforms
        nPlats = numel(plats);
        fprintf('[compliance_platform] Using %d platforms from platform_presets()\n', nPlats);
    end
    
    % 验证平台配置
    if nPlats == 0
        error('compliance_platform: No platforms configured! Check cfg.platforms or platform_presets().');
    end
    
    % 显示平台信息（调试）
    fprintf('[compliance_platform] Platform details:\n');
    for p = 1:min(4, nPlats)
        if isstruct(plats) && isfield(plats, 'name')
            tgt = NaN;
            tpl = NaN;
            if isfield(plats(p), 'targetLUFS')
                tgt = plats(p).targetLUFS;
            elseif isfield(plats(p), 'target')
                tgt = plats(p).target;
            end
            if isfield(plats(p), 'tpLimit')
                tpl = plats(p).tpLimit;
            elseif isfield(plats(p), 'tpCeil')
                tpl = plats(p).tpCeil;
            end
            fprintf('  Platform %d: %s (targetLUFS=%.1f, tpLimit=%.1f)\n', ...
                p, string(plats(p).name), tgt, tpl);
        end
    end

    rows = {};   % 最终 cell 行列表

    % ---- 验证表格不为空 ----
    if height(T) == 0
        warning('compliance_platform: metrics.csv is empty (0 rows)');
        % 创建空表但包含正确的列名
        C = table(strings(0,1), strings(0,1), NaN(0,1), NaN(0,1), NaN(0,1), ...
                  NaN(0,1), NaN(0,1), zeros(0,1), ...
                  'VariableNames', {'file','platform','preLUFS','preTP','gain_dB', ...
                                  'postLUFS','postTP','limited'});
        outCsv = fullfile(cfg.resultsDir, 'compliance_platform.csv');
        try
            writetable(C, outCsv, 'WriteMode', 'overwrite');
            fprintf('[compliance_platform] Created empty %s (metrics.csv has no data)\n', outCsv);
        catch
            warning('compliance_platform: Failed to create empty CSV');
        end
        return;
    end

    % ---- 遍历每条音频 ----
    rowsAdded = 0;
    rowsSkipped = 0;
    
    for i = 1:height(T)

        file = safeCell(T.file{i});
        pre = safeNum(T.integratedLUFS(i));
        tp  = safeNum(T.truePeak_dBTP(i));
        
        % 跳过无效行
        if isempty(file) || ~isfinite(pre) || ~isfinite(tp)
            rowsSkipped = rowsSkipped + 1;
            if rowsSkipped <= 3  % 只显示前3个警告
                warning('compliance_platform: Skipping row %d (invalid data: file="%s", pre=%.2f, tp=%.2f)', ...
                    i, string(file), pre, tp);
            end
            continue;
        end

        % --- 为每个平台生成记录 ---
        for p = 1:nPlats

            % Get platform struct (already from cfg.platforms or platform_presets)
            if isstruct(plats) && isfield(plats, 'name')
                plat = plats(p);
            else
                % Fallback: query by name
                plat = platform_presets(plats{p});
            end

            % Validate platform struct - 更宽松的检查
            hasTarget = isfield(plat, 'targetLUFS') || isfield(plat, 'target');
            hasTP = isfield(plat, 'tpLimit') || isfield(plat, 'tpCeil');
            
            if ~hasTarget || ~hasTP
                if rowsSkipped < 3
                    warning('compliance_platform: Platform %d missing required fields, skipping.', p);
                    fprintf('  Platform struct fields: %s\n', strjoin(fieldnames(plat), ', '));
                end
                rowsSkipped = rowsSkipped + 1;
                continue;
            end
            
            % 获取字段值（兼容多种字段名）
            if isfield(plat, 'targetLUFS')
                targetLUFS = plat.targetLUFS;
            elseif isfield(plat, 'target')
                targetLUFS = plat.target;
            else
                targetLUFS = -14;  % 默认值
            end
            
            if isfield(plat, 'tpLimit')
                tpLimit = plat.tpLimit;
            elseif isfield(plat, 'tpCeil')
                tpLimit = plat.tpCeil;
            else
                tpLimit = -1.0;  % 默认值
            end
            
            % 确保字段名正确（兼容 tpCeil 和 tpLimit）
            plat.targetLUFS = targetLUFS;
            plat.tpLimit = tpLimit;
            if ~isfield(plat, 'tpCeil')
                plat.tpCeil = tpLimit;
            end
            
            % 获取平台名称
            if isfield(plat, 'name')
                platName = string(plat.name);
            elseif isfield(plat, 'platform')
                platName = string(plat.platform);
            else
                platName = sprintf('platform_%d', p);
            end

            gain_dB = targetLUFS - pre;
            postLUFS = pre + gain_dB;
            postTP   = tp  + gain_dB;
            limited = postTP > tpLimit;

            % ---- 强制保证每一行有 8 列，确保数据类型正确 ----
            rows(end+1, :) = { ...
                string(file), ...        % (1) file
                platName, ...             % (2) platform
                double(pre), ...          % (3) preLUFS
                double(tp), ...           % (4) preTP
                double(gain_dB), ...      % (5) gain_dB
                double(postLUFS), ...     % (6) postLUFS
                double(postTP), ...       % (7) postTP
                double(limited) ...       % (8) limited (0 or 1)
            };
            rowsAdded = rowsAdded + 1;
        end

    end
    
    fprintf('[compliance_platform] Processed %d rows from metrics.csv, added %d compliance rows, skipped %d\n', ...
        height(T), rowsAdded, rowsSkipped);

    % ---- 检查 rows 是否为空 ----
    if isempty(rows)
        warning('compliance_platform: No rows generated!');
        fprintf('  Debug info:\n');
        fprintf('    - metrics.csv rows: %d\n', height(T));
        fprintf('    - platforms count: %d\n', nPlats);
        if height(T) > 0
            fprintf('    - First file: %s\n', string(T.file(1)));
            fprintf('    - First integratedLUFS: %.2f\n', T.integratedLUFS(1));
        end
        % 创建空表但包含正确的列名，避免创建完全空文件
        C = table(strings(0,1), strings(0,1), NaN(0,1), NaN(0,1), NaN(0,1), ...
                  NaN(0,1), NaN(0,1), zeros(0,1), ...
                  'VariableNames', {'file','platform','preLUFS','preTP','gain_dB', ...
                                  'postLUFS','postTP','limited'});
        fprintf('  WARNING: Creating empty table with headers only\n');
    else
        % ---- 构造表 ----
        try
            % 验证 rows 格式
            if ~iscell(rows)
                error('rows must be a cell array');
            end
            
            % 确保所有行都有相同的列数
            if ~isempty(rows)
                nCols = size(rows, 2);
                if nCols ~= 8
                    error('rows must have 8 columns, got %d', nCols);
                end
            end
            
            C = cell2table(rows, 'VariableNames', ...
                {'file','platform','preLUFS','preTP','gain_dB','postLUFS','postTP','limited'});
            
            % 验证表格
            if height(C) == 0
                warning('compliance_platform: Table created but has 0 rows');
            end
            if width(C) ~= 8
                error('compliance_platform: Table has wrong number of columns: %d', width(C));
            end
            
        catch ME
            warning('cell2table 失败: %s', ME.message);
            fprintf('Debug: rows size = %s\n', mat2str(size(rows)));
            if ~isempty(rows)
                fprintf('Debug: first row = %s\n', mat2str(rows(1,:)));
            end
            % 创建空表但包含正确的列名
            C = table(strings(0,1), strings(0,1), NaN(0,1), NaN(0,1), NaN(0,1), ...
                      NaN(0,1), NaN(0,1), zeros(0,1), ...
                      'VariableNames', {'file','platform','preLUFS','preTP','gain_dB', ...
                                      'postLUFS','postTP','limited'});
        end
    end

    outCsv = fullfile(cfg.resultsDir, 'compliance_platform.csv');
    
    % 使用强制写入函数
    try
        success = force_write_table(C, outCsv, 'WriteMode', 'overwrite');
        if success
            fprintf('[compliance_platform] Generated %s (%d rows)\n', outCsv, height(C));
        else
            error('force_write_table returned false');
        end
    catch ME
        error('compliance_platform: Failed to write CSV: %s\n  File: %s\n  Please close the file if it is open in Excel or another program.', ...
            ME.message, outCsv);
    end

end


% === 安全处理函数，防止空值破坏 cell2table ===
function s = safeCell(x)
    if isempty(x)
        s = "";
    elseif ischar(x)
        s = string(x);
    elseif isstring(x)
        s = x;
    else
        s = string(x);
    end
end

function n = safeNum(x)
    if isempty(x) || ~isnumeric(x)
        n = NaN;
    else
        n = x;
    end
end
