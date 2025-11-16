function [y, meta] = adaptive_normalizer(x, Fs, preLUFS, targetLUFS, M, cfg)
% ADAPTIVE_NORMALIZER
% ---------------------------------------------------------
% 1) Loudness-based gain estimation
% 2) True-peak–safe gain optimisation
% 3) Optional mastering-profile trim (simple, per-cfg)
% 4) Peak limiting with GR statistics
% 5) Post-normalisation true-peak estimate
% 6) Metadata for CSV / report
% ---------------------------------------------------------

    if nargin < 5 || isempty(M)
        M = struct(); %#ok<NASGU> 
    if nargin < 6 || isempty(cfg)
        cfg = struct();
    end

    % ----------- INIT ----------
    meta = struct();
    meta.preLUFS    = preLUFS;
    meta.targetLUFS = targetLUFS;

    preLUFS_num    = asNumeric(preLUFS,    NaN);
    targetLUFS_num = asNumeric(targetLUFS, -14);

    % ============================================================
    % 1) RAW GAIN (LUFS-based)
    % ============================================================
    rawGain_dB       = targetLUFS_num - preLUFS_num;
    meta.rawGain_dB  = rawGain_dB;
    gain_dB          = rawGain_dB;

    % ============================================================
    % 2) TRUE-PEAK-SAFE GAIN OPTIMISATION
    % ============================================================
    try
        tpCeil = getCfgNum(cfg, ...
            {'tpCeil','R128_maxTP','maxTP','maxTruePeak'}, -1);
        out    = optimize_gain_tp_safe(x, Fs, tpCeil, cfg);

        if isstruct(out)
            if isfield(out,'gain_dB')
                gain_dB = out.gain_dB;
            elseif isfield(out,'gain')
                gain_dB = out.gain;
            end
        elseif isnumeric(out) && isscalar(out) && isfinite(out)
            gain_dB = out;
        end
    catch
        % 若优化失败，退回原始 LUFS gain
        gain_dB = rawGain_dB;
    end
    meta.tpSafeGain_dB = gain_dB;

    % ============================================================
    % 3) ADAPTIVE MASTERING PROFILE 
    % ============================================================
   
    if isfield(cfg,'enableAdaptiveMastering') && cfg.enableAdaptiveMastering
        trim_dB = getCfgNum(cfg, {'profileTrim_dB','masterTrim_dB'}, 0);
        gain_dB = gain_dB + trim_dB;
        meta.profileTrim = trim_dB;
        meta.profileName = "cfg.profileTrim_dB";
    else
        meta.profileTrim = 0;
        meta.profileName = "none";
    end

    meta.gain_dB = gain_dB;

    
    g = 10^(gain_dB/20);
    u = x .* g;

    % ============================================================
    % 4) TRUE-PEAK LIMITING
    % ============================================================
    tpThresh_dB  = getCfgNum(cfg, ...
        {'tpCeil','R128_maxTP','maxTP','maxTruePeak'}, -1);
    tpThresh_lin = 10^(tpThresh_dB/20);

    % Get attack/release times from config if available
    if isfield(cfg, 'limiterAttackMs')
        attackMs = cfg.limiterAttackMs;
    else
        attackMs = 3.0;  % Default 3 ms
    end
    if isfield(cfg, 'limiterReleaseMs')
        releaseMs = cfg.limiterReleaseMs;
    else
        releaseMs = 50.0;  % Default 50 ms
    end
    attack  = max(1, round(attackMs / 1000 * Fs));
    release = max(1, round(releaseMs / 1000 * Fs));

    N  = numel(u);
    env = 0;
    gr  = zeros(N, 1); % gain factor (<=1)

   
    u_vec = u(:);
    for n = 1:N
        a = abs(u_vec(n));

        % attack / release smoothing
        if a > env
            env = env + (a - env) / attack;
        else
            env = env + (a - env) / release;
        end

        if env > tpThresh_lin
            need = tpThresh_lin / max(env, eps);
        else
            need = 1.0;
        end

        gr(n)    = need;
        u_vec(n) = u_vec(n) * need;
    end

    
    y = reshape(u_vec, size(u));

    % ============================================================
    % 5) LIMITER WORK STATISTICS
    % ============================================================
    gr_db = -20 * log10(max(gr, eps));  % 0dB = no reduction

    meta.gr_curve    = gr_db;
    meta.maxGR       = max(gr_db);
    meta.meanGR      = mean(gr_db);
    meta.grTimeRatio = mean(gr_db > 0.1);   % 

    meta.limiter          = meta.maxGR > 0.1;
    meta.limiterActive    = meta.limiter;
    meta.limiterTriggered = meta.limiter;

    % ============================================================
    % 6) POST METRICS: True Peak & rough LUFS
    % ============================================================
    try
        meta.postTP = truepeak_fast_predict(y, Fs);
    catch
        meta.postTP = 20*log10(max(abs(y(:))) + eps);
    end

    % 粗略估计：preLUFS + gain - 平均 GR
    meta.postLUFS = preLUFS_num + gain_dB - meta.meanGR;
end


% ============================================================
% Helpers
% ============================================================

function v = asNumeric(x, defaultVal)
    if nargin < 2, defaultVal = NaN; end
    if isnumeric(x) && isscalar(x) && isfinite(x)
        v = double(x);
    elseif isstring(x) || ischar(x)
        v = str2double(x);
        if ~isfinite(v), v = defaultVal; end
    else
        v = defaultVal;
    end
end

function v = getCfgNum(cfg, nameList, defaultVal)
    if nargin < 3, defaultVal = NaN; end
    v = defaultVal;
    if ~isstruct(cfg), return; end
    for k = 1:numel(nameList)
        n = nameList{k};
        if isfield(cfg,n)
            vv = cfg.(n);
            if isnumeric(vv) && isscalar(vv) && isfinite(vv)
                v = double(vv);
                return;
            end
        end
    end
end
