function S = normalize_streaming(x, Fs, preLUFS, preTP, targetLUFS, cfg, plat, fname)
% NORMALIZE_STREAMING
% Normalize audio for streaming platform playback
%
% Inputs:
%   x          - audio signal (mono)
%   Fs         - sampling rate (Hz)
%   preLUFS    - pre-normalization loudness (LUFS)
%   preTP      - pre-normalization true peak (dBTP)
%   targetLUFS - target loudness (LUFS)
%   cfg        - config struct
%   plat       - platform struct (with tpLimit field)
%   fname      - filename (for logging, optional)
%
% Output struct S:
%   y       - normalized audio signal
%   postLUFS - post-normalization loudness (LUFS)
%   postTP   - post-normalization true peak (dBTP)
%   gain_dB  - applied gain (dB)
%   limited  - whether limiting was applied (0 or 1)
%   maxGR    - maximum gain reduction (dB)
%   meanGR   - mean gain reduction (dB)
%   grTimeRatio - fraction of time limiter active

    if nargin < 6, cfg = struct(); end
    if nargin < 7, plat = struct(); end
    if nargin < 8, fname = ''; end
    
    % Get TP limit from platform
    if isfield(plat, 'tpLimit')
        tpLimit = plat.tpLimit;
    elseif isfield(plat, 'tpCeil')
        tpLimit = plat.tpCeil;
    elseif isfield(cfg, 'tpCeil')
        tpLimit = cfg.tpCeil;
    else
        tpLimit = -1.0;  % Default
    end
    
    % Calculate gain
    gain_dB = targetLUFS - preLUFS;
    
    % Apply gain
    g = 10^(gain_dB/20);
    y = x * g;
    
    % Simple limiter (peak limiter)
    th_linear = 10^(tpLimit/20);
    gr = ones(size(y));
    
    peak = abs(y);
    idx = peak > th_linear;
    if any(idx)
        gr(idx) = th_linear ./ peak(idx);
        y = y .* gr;
    end
    
    % Calculate metrics
    S.y = y;
    S.gain_dB = gain_dB;
    
    % Post-processing metrics
    try
        M_post = measure_loudness(y, Fs, cfg);  % 传递 cfg 以使用配置参数
        S.postLUFS = M_post.integratedLUFS;
    catch
        % Fallback: estimate from gain
        S.postLUFS = preLUFS + gain_dB;
    end
    
    try
        % Use oversample factor from config if available
        if isfield(cfg, 'truePeakOversample')
            oversample = cfg.truePeakOversample;
        else
            oversample = 4;  % Default 4x - EBU R128 recommended
        end
        S.postTP = truepeak_ref(y, Fs, oversample);
    catch
        % Fallback: simple peak
        S.postTP = 20*log10(max(abs(y)) + 1e-12);
    end
    
    % Limiter metrics
    S.limited = double(S.postTP > tpLimit);
    S.maxGR = max(-20*log10(gr + 1e-12));
    S.meanGR = mean(-20*log10(gr + 1e-12));
    S.grTimeRatio = mean(gr < 1);
    
    % Ensure non-negative values
    S.maxGR = max(0, S.maxGR);
    S.meanGR = max(0, S.meanGR);
    S.grTimeRatio = max(0, min(1, S.grTimeRatio));
end
