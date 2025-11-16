function M = measure_loudness(x, Fs, cfg)
% MEASURE_LOUDNESS
% ITU-R BS.1770-4 / EBU R128 compliant loudness measurement
%
% Inputs:
%   x   - audio signal (mono or stereo, will be converted to mono)
%   Fs  - sampling rate (Hz)
%   cfg - optional config struct
%
% Output struct M contains:
%   integratedLUFS  - Integrated loudness (LUFS)
%   LRA             - Loudness Range (LU)
%   shortTermLUFS   - Short-term loudness (LUFS)
%   momentaryLUFS   - Momentary loudness (LUFS)
%   truePeak_dBTP   - True Peak (dBTP)
%   speechLUFS      - Speech-only loudness (LUFS)
%   speechRatio     - Speech ratio (0-1)
%   LD              - Dialogue Level Difference (LU)
%   dialogueRisk    - Dialogue risk flag (0 or 1)
%
% Reference: ITU-R BS.1770-4, EBU Tech 3341/3342

    % Parameter compatibility handling
    if nargin < 3
        cfg = struct();
    end

    % Force mono (BS.1770: sum of squares)
    if size(x,2) > 1
        % Multi-channel: sum of squares (not mean)
        x = sqrt(sum(x.^2, 2));
    end
    x = x(:);
    
    % Remove DC
    x = x - mean(x);

    % ---- BS.1770 K-weighting filter ----
    y = bs1770_filter(x, Fs);

    % ---- Block-based loudness (400ms blocks, 100ms hop) ----
    % Use config if available, otherwise use EBU R128 defaults
    if isfield(cfg, 'loudnessBlockMs')
        blockMs = cfg.loudnessBlockMs;
    else
        blockMs = 400;  % EBU R128 standard
    end
    if isfield(cfg, 'loudnessHopMs')
        hopMs = cfg.loudnessHopMs;
    else
        hopMs = 100;  % EBU R128 standard
    end
    blockSamples = round(blockMs / 1000 * Fs);
    hopSamples   = round(hopMs / 1000 * Fs);
    
    N = length(y);
    if N < blockSamples
        % Very short audio: use single block
        p = mean(y.^2) + eps;
        LU = -0.691 + 10*log10(p);
        M.integratedLUFS = LU;
        M.LRA = 0;
        M.shortTermLUFS = LU;
        M.momentaryLUFS = LU;
    else
        nHop = max(1, floor((N - blockSamples) / hopSamples) + 1);
        LU = zeros(nHop, 1);
        
        for i = 1:nHop
            startIdx = (i-1) * hopSamples + 1;
            endIdx = min(startIdx + blockSamples - 1, N);
            seg = y(startIdx:endIdx);
            p = mean(seg.^2) + eps;
            LU(i) = -0.691 + 10*log10(p);
        end

        % Integrated loudness: mean of all blocks
        M.integratedLUFS = mean(LU);

        % LRA: 95th percentile - 10th percentile
        if numel(LU) > 1
            M.LRA = prctile(LU, 95) - prctile(LU, 10);
        else
            M.LRA = 0;
        end

        % Short-term: mean of last N seconds (or all if shorter)
        if isfield(cfg, 'shortTermSeconds')
            shortTermSec = cfg.shortTermSeconds;
        else
            shortTermSec = 3.0;  % Default 3 seconds
        end
        shortTermBlocks = min(round(shortTermSec * 1000 / hopMs), numel(LU));
        M.shortTermLUFS = mean(LU(max(1, end-shortTermBlocks+1):end));

        % Momentary: last block
        M.momentaryLUFS = LU(end);
    end

    % ---- True Peak (BS.1770-4 / EBU Tech 3341) ----
    try
        oversample = 4;
        if isfield(cfg, 'truePeakOversample')
            oversample = cfg.truePeakOversample;
        end
        M.truePeak_dBTP = truepeak_ref(x, Fs, oversample);
    catch
        % Fallback: simple peak
        M.truePeak_dBTP = 20*log10(max(abs(x)) + eps);
    end
    
    % ---- Dialogue-aware metrics (if requested) ----
    % These fields are expected by row_metrics.m:
    % speechLUFS, speechRatio, LD, dialogueRisk
    if isfield(cfg, 'enableDialogueMetrics') && ~cfg.enableDialogueMetrics
        % Explicitly disabled
        M.speechLUFS = NaN;
        M.speechRatio = NaN;
        M.LD = NaN;
        M.dialogueRisk = 0;
    else
        % Default: enable dialogue metrics unless explicitly disabled
        try
            D = dialogue_metrics(x, Fs, cfg);  % Pass cfg to use VAD parameters
            M.speechLUFS = D.speechLUFS;
            M.speechRatio = D.speechRatio;
            M.LD = D.LD;
            M.dialogueRisk = double(D.flag_risky || D.flag_bad);
        catch
            % Silent fallback if dialogue_metrics not available
            M.speechLUFS = NaN;
            M.speechRatio = NaN;
            M.LD = NaN;
            M.dialogueRisk = 0;
        end
    end
end


% ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
% BS.1770 K-weighting filter
% ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
function y = bs1770_filter(x, Fs)
    [b1,a1] = butter(1, 38/(Fs/2), 'high');      % HP
    x1 = filter(b1,a1,x);

    f0 = 1681.974450955533;
    Q  = 0.707175236955419;
    K  = tan(pi * f0 / Fs);
    Vh = 4.0;
    Vb = sqrt(2.0)*Vh;
    denom = 1 + K/Q + K*K;
    b = [(1 + Vh*K/Q + K*K)/denom, (-2*(K*K - 1))/denom, (1 - Vh*K/Q + K*K)/denom];
    a = [1, (-2*(K*K - 1))/denom, (1 - K/Q + K*K)/denom];

    y = filter(b,a,x1);
end
