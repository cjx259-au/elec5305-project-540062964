function adaptive_mastering_profiles(cfg)
% ADAPTIVE_MASTERING_PROFILES
% 基于 metrics（integratedLUFS、truePeak_dBTP）和平台 target，
% 估算更合适的母带 loudness 目标，使平台二次归一化的影响最小。
%
% 输出: results/adaptive_mastering.csv

if nargin < 1 || isempty(cfg)
    cfg = config();
end

resultsDir = cfg.resultsDir;
metricsCsv = fullfile(resultsDir, 'metrics.csv');
assert(isfile(metricsCsv), 'metrics.csv not found at %s. Run run_project first.', metricsCsv);

% 读 metrics.csv
M = readtable(metricsCsv);
assert(ismember('integratedLUFS', M.Properties.VariableNames), 'metrics.csv must contain integratedLUFS.');
assert(ismember('truePeak_dBTP',  M.Properties.VariableNames), 'metrics.csv must contain truePeak_dBTP.');

% 平台参数
Sraw = platform_presets();
Sp = normalize_presets_local(Sraw);

rows = {};

for i = 1:height(M)

    fname   = string(M.file(i));
    preLUFS = M.integratedLUFS(i);
    preTP   = M.truePeak_dBTP(i);

    % 动态范围指标（PLR = Peak – Loudness）
    plr = preTP - preLUFS;

    % 逐平台计算推荐母带 loudness
    for p = 1:numel(Sp)

        platName = getStr(Sp(p), ...
            {'platform','name','platformName'}, ...
            sprintf('platform_%d', p));

        tgtLUFS = getNum(Sp(p), ...
            {'targetLUFS','target','LUFS'}, ...
            -14);

        tpCeil = getNum(Sp(p), ...
            {'tpCeil','tpLimit','tpCeiling','truePeakCeil','R128_maxTP','maxTP','maxTruePeak'}, ...
            -1);

        % ===============================
        % 1. 根据平台 TP ceiling 推估合理母带 LUFS
        % ===============================

        % Get safety margins from config if available
        if isfield(cfg, 'tpMargin')
            safetyMargin = cfg.tpMargin;
        else
            safetyMargin = 1.0;   % Default: avoid platform brickwall limiter
        end
        codecHeadroom = 0.5;   % Lossy codec additional headroom (fixed)

        targetMasterTP = tpCeil - safetyMargin - codecHeadroom;

        % 估计母带 LUFS = 目标 TP - PLR
        masterLUFS_est = targetMasterTP - plr;

        % ===============================
        % 2. 与平台 target 的折中
        % ===============================
        alpha = 0.5;   % 0=完全按平台LUFS，1=完全按TP安全值
        masterLUFS = alpha * masterLUFS_est + (1 - alpha) * tgtLUFS;

        % 不能超过平台 LUFS target（避免变太亮）
        masterLUFS = min(masterLUFS, tgtLUFS);

        % ===============================
        % 3. 估算平台将会加多少 gain
        % ===============================
        gain_platform = tgtLUFS - masterLUFS;

        % ===============================
        % 4. 推估平台归一化后的 TP
        % ===============================
        % preTP + 母带增益 + 平台增益
        postTP_est = preTP + (masterLUFS - preLUFS) + gain_platform;

        limited_risk = postTP_est > tpCeil;

        rows = [rows; { ...
            fname, ...
            string(platName), ...
            preLUFS, ...
            preTP, ...
            tgtLUFS, ...
            tpCeil, ...
            plr, ...
            masterLUFS, ...
            gain_platform, ...
            postTP_est, ...
            logical(limited_risk) ...
        }];
    end
end

T = cell2table(rows, 'VariableNames', ...
    {'file','platform','preLUFS','preTP', ...
     'platform_targetLUFS','platform_tpCeil', ...
     'PLR', ...
     'recommended_masterLUFS', ...
     'platform_gain_needed', ...
     'postTP_est', ...
     'limited_risk_est'});

outCsv = fullfile(resultsDir,'adaptive_mastering.csv');
% 使用强制写入函数
try
    success = force_write_table(T, outCsv, 'WriteMode', 'overwrite');
    if success
        fprintf('[adaptive_mastering_profiles] Wrote %s\n', outCsv);
    else
        warning('[adaptive_mastering_profiles] Failed to write %s', outCsv);
    end
catch ME
    warning('[adaptive_mastering_profiles] Failed to write %s: %s', outCsv, ME.message);
end

end


% ============================================================
% Local Helper: normalize platform presets
% ============================================================
function S = normalize_presets_local(Sraw)

if istable(Sraw)
    S = table2struct(Sraw);
elseif iscell(Sraw)
    if ~isempty(Sraw) && all(cellfun(@(c)isstruct(c), Sraw))
        S = [Sraw{:}];
    elseif numel(Sraw)==1 && isstruct(Sraw{1})
        S = Sraw{1};
    else
        error('platform_presets returned cell, but wrong structure.');
    end
elseif isstruct(Sraw)
    S = Sraw;
else
    error('platform_presets returned unsupported type: %s', class(Sraw));
end

% 默认填补
for i = 1:numel(S)
    if ~isfield(S(i),'platform') && ~isfield(S(i),'name')
        S(i).platform = sprintf('platform_%d', i);
    end
    if ~isfield(S(i),'targetLUFS')
        S(i).targetLUFS = -14;
    end
    % 支持 tpCeil 和 tpLimit 字段名
    if ~isfield(S(i),'tpCeil') && ~isfield(S(i),'tpLimit')
        S(i).tpCeil = -1;
    elseif isfield(S(i),'tpLimit') && ~isfield(S(i),'tpCeil')
        S(i).tpCeil = S(i).tpLimit;
    elseif isfield(S(i),'tpCeil') && ~isfield(S(i),'tpLimit')
        S(i).tpLimit = S(i).tpCeil;
    end
end

end


% ============================================================
% Local Helper: get numeric field
% ============================================================
function v = getNum(rec, names, defaultVal)

r = rec;
if istable(r)
    r = table2struct(r);
elseif iscell(r)
    if numel(r)==1, r = r{1}; end
end

v = defaultVal;
for i = 1:numel(names)
    f = names{i};
    if isfield(r,f)
        val = r.(f);
        if isnumeric(val) && isscalar(val)
            v = double(val);
            return;
        end
    end
end

end


% ============================================================
% Local Helper: get string field
% ============================================================
function s = getStr(rec, names, defaultVal)

r = rec;
if istable(r)
    r = table2struct(r);
elseif iscell(r)
    if numel(r)==1, r = r{1}; end
end

s = defaultVal;
for i = 1:numel(names)
    f = names{i};
    if isfield(r,f)
        val = r.(f);
        if isstring(val) || ischar(val)
            s = string(val);
            return;
        elseif iscategorical(val)
            s = string(val);
            return;
        end
    end
end

end
