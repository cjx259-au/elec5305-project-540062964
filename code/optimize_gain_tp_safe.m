function out = optimize_gain_tp_safe(x, Fs, tpCeil, cfg)
% OPTIMIZE_GAIN_TP_SAFE
% --------------------------------------------------------------
% Robust true-peak–safe gain optimizer (binary search).
%
% Finds the maximum gain_dB such that:
%
%      truepeak_ref( x * 10^(gain_dB/20), Fs, oversample ) <= tpCeil
%
% Inputs:
%   x        : mono audio
%   Fs       : sampling rate
%   tpCeil   : true-peak ceiling (dBTP), default −1
%   cfg      : config, must include cfg.truePeakOversample
%
% Output struct:
%   out.gain_dB    safe gain in dB
%   out.gain       same as gain_dB (compatibility)
%   out.postTP     final true peak of y
%   out.postLUFS   RMS-based LUFS approximation of y
%
% Fully safe for silence / NaN inputs.
% --------------------------------------------------------------

    % ------------------- argument defaults -------------------
    if nargin < 4 || isempty(cfg)
        cfg = struct();
    end
    if ~isfield(cfg, 'truePeakOversample')
        cfg.truePeakOversample = 4;       % default 4× TP oversampling
    end
    if nargin < 3 || isempty(tpCeil)
        tpCeil = -1;                      % −1 dBTP ceiling
    end

    oversample = cfg.truePeakOversample;

    % ensure column
    x = x(:);

    % ------------------- silence handling -------------------
    if ~any(isfinite(x))
        x(:) = 0;
    end

    if max(abs(x)) < 1e-8
        out = struct( ...
            'gain',        0, ...
            'gain_dB',     0, ...
            'postLUFS',    -Inf, ...
            'postTP',      -Inf);
        return;
    end

    % ------------------- search bounds -------------------
    gL = -40;   % min gain
    gR = +40;   % max gain

    tpCeil = double(tpCeil);
    if ~isfinite(tpCeil)
        tpCeil = -1;
    end

    % ------------------- binary search -------------------
    for it = 1:24     % high precision ≈ 6e-8
        gM = (gL + gR) / 2;
        test = x * 10^(gM/20);

        try
            tp = truepeak_ref(test, Fs, oversample);
        catch
            tp = 20*log10(max(abs(test))+eps);
        end

        if tp > tpCeil
            gR = gM;     % too loud, reduce gain
        else
            gL = gM;     % safe, increase gain
        end
    end

    % safe gain
    gain_dB = gL;

    % ------------------- apply gain -------------------
    y = x * 10^(gain_dB/20);

    % ------------------- post LUFS -------------------
    try
        rms = sqrt(mean(y.^2));
        postLUFS = -0.691 + 20*log10(rms + eps);
    catch
        postLUFS = NaN;
    end

    % ------------------- post True Peak -------------------
    try
        postTP = truepeak_ref(y, Fs, oversample);
    catch
        postTP = 20*log10(max(abs(y))+eps);
    end

    % ------------------- output struct -------------------
    out = struct( ...
        'gain',        gain_dB, ...
        'gain_dB',     gain_dB, ...
        'postLUFS',    postLUFS, ...
        'postTP',      postTP );
end
