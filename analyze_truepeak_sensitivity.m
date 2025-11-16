function analyze_truepeak_sensitivity(cfg)
% ANALYZE_TRUEPEAK_SENSITIVITY
% ---------------------------------------------------------
% 对所有 WAV 文件分别进行 4× 与 8× oversampling true-peak 测量，
% 计算差异并识别：
%   - flip-case（合规性判断发生变化）
%   - borderline（接近 tpCeil 的临界情况）
%
% 输出: results/tp_sensitivity.csv
% ---------------------------------------------------------

if nargin < 1 || isempty(cfg)
    cfg = config();
end

dataDir    = cfg.dataDir;
resultsDir = cfg.resultsDir;

fList = dir(fullfile(dataDir, '**', '*.wav'));
if isempty(fList)
    % Try non-recursive search
    fList = dir(fullfile(dataDir, '*.wav'));
end
assert(~isempty(fList), 'No WAV files found under %s', dataDir);

fprintf('[analyze_truepeak_sensitivity] Processing %d files...\n', numel(fList));

rows = {};

for i = 1:numel(fList)
    if mod(i, 10) == 0 || i == 1
        fprintf('  [%d/%d] Processing %s...\n', i, numel(fList), fList(i).name);
    end

    fpath = fullfile(fList(i).folder, fList(i).name);
    try
        [x, Fs] = audioread(fpath);
    catch ME
        warning('Cannot read %s: %s, skipping...', fList(i).name, ME.message);
        continue;
    end

    % ----- Mono fold-down -----
    if size(x,2) > 1
        x = mean(x,2);
    end

    % ----- Resample to 48kHz to unify -----
    if Fs ~= 48000
        try
            x = resample(x, 48000, Fs);
            Fs = 48000;
        catch ME
            warning('Resampling failed for %s: %s, skipping...', fList(i).name, ME.message);
            continue;
        end
    end

    % ----- 4× true peak -----
    try
        tp4 = truepeak_ref(x, Fs, 4);
    catch ME
        warning('TP4 calculation failed for %s: %s, skipping...', fList(i).name, ME.message);
        continue;
    end

    % ----- 8× true peak -----
    try
        tp8 = truepeak_ref(x, Fs, 8);
    catch ME
        warning('TP8 calculation failed for %s: %s, skipping...', fList(i).name, ME.message);
        continue;
    end

    diffTP = tp8 - tp4;

    % ----- Platform / R128 ceiling -----
    if isfield(cfg, 'R128_maxTP')
        tpCeil = cfg.R128_maxTP;
    elseif isfield(cfg, 'tpCeil')
        tpCeil = cfg.tpCeil;
    else
        tpCeil = -1;   % 默认 -1 dBTP
    end

    pass4 = (tp4 <= tpCeil + 1e-12);
    pass8 = (tp8 <= tpCeil + 1e-12);

    % 判断 flip-case：合规判断不一致
    flip_case = (pass4 ~= pass8);

    % borderline：接近天花板 ±0.5 dB
    borderline = (abs(tp4 - tpCeil) < 0.5) | (abs(tp8 - tpCeil) < 0.5);

    rows = [rows; {
        fList(i).name, ...
        tp4, ...
        tp8, ...
        diffTP, ...
        tpCeil, ...
        logical(pass4), ...
        logical(pass8), ...
        logical(flip_case), ...
        logical(borderline)
    }];
end

% ---- Save CSV ----
if isempty(rows)
    warning('[analyze_truepeak_sensitivity] No data to write, skipping CSV generation');
    return;
end

try
    T = cell2table(rows, 'VariableNames', ...
        {'file','TP_4x','TP_8x','diffTP','tpCeil', ...
         'pass_4x','pass_8x','flip_case','borderline'});
catch ME
    warning('[analyze_truepeak_sensitivity] Failed to create table: %s', ME.message);
    return;
end

outCsv = fullfile(resultsDir, 'tp_sensitivity.csv');
% 使用强制写入函数
try
    success = force_write_table(T, outCsv, 'WriteMode', 'overwrite');
    if success
        fprintf('[analyze_truepeak_sensitivity] ✓ Wrote %s (%d rows)\n', outCsv, height(T));
        
        % 统计信息
        if height(T) > 0
            flipCount = sum(T.flip_case);
            borderlineCount = sum(T.borderline);
            fprintf('[analyze_truepeak_sensitivity]   - Flip cases: %d\n', flipCount);
            fprintf('[analyze_truepeak_sensitivity]   - Borderline cases: %d\n', borderlineCount);
        end
    else
        warning('[analyze_truepeak_sensitivity] Failed to write %s', outCsv);
    end
catch ME
    warning('[analyze_truepeak_sensitivity] Failed to write %s: %s', outCsv, ME.message);
end
end


% ============================================================
% Note: This function now uses truepeak_ref() instead of local truepeak_os()
% for consistency with the rest of the codebase.
% ============================================================
