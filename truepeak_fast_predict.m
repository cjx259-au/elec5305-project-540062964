function tp_est = truepeak_fast_predict(x, Fs, tp4x)
% TRUEPEAK_FAST_PREDICT
% Fast + robust true-peak predictor using:
%   - 4× oversampled TP as anchor
%   - spectral centroid
%   - spectral spread
%   - crest factor (dB)
%
% Fully compatible with ELEC5305 project.

    % ------------------------------------------------------------
    % 0) input & fallback
    % ------------------------------------------------------------
    x = x(:);

    if nargin < 3 || isempty(tp4x)
        % compute 4× baseline TP
        try
            tp4x = truepeak_ref(x, Fs, 4);
        catch
            tp4x = 20*log10(max(abs(x)) + eps);
        end
    end

    if ~isfinite(tp4x)
        tp4x = 20*log10(max(abs(x)) + eps);
    end

    % ensure not silent
    if max(abs(x)) < 1e-10
        tp_est = tp4x;
        return;
    end

    % remove DC
    x = x - mean(x);


    % ------------------------------------------------------------
    % 1) Robust spectral features
    %    For long audio: randomly sample 4096 samples
    % ------------------------------------------------------------
    MAXLEN = 4096;
    N = numel(x);
    if N > MAXLEN
        st = randi(N-MAXLEN+1);
        x_seg = x(st:st+MAXLEN-1);
    else
        x_seg = x;
    end

    % Compute features with safe fallbacks
    try
        sc = spec_centroid_safe(x_seg, Fs);
        bw = spec_spread_safe(x_seg, Fs);
        cf = crest_factor_db_safe(x_seg);
    catch
        warning('[truepeak_fast_predict] feature extraction failed, fallback to tp4x.');
        tp_est = tp4x;
        return;
    end


    % ------------------------------------------------------------
    % 2) Fast true-peak regression model
    % ------------------------------------------------------------
    tp_est = ...
          0.72    * tp4x ...      % 4× anchor
        + 0.00040 * sc   ...      % centroid
        + 0.00015 * bw   ...      % spread
        + 0.10    * cf;           % crest factor


    % ------------------------------------------------------------
    % 3) Hard safety limits
    % ------------------------------------------------------------
    % prevent predictor from going too low
    tp_est = max(tp_est, tp4x - 0.5);

    % prevent predictor from going too high
    tp_est = min(tp_est, tp4x + 3.0);

    % enforce finite
    if ~isfinite(tp_est)
        tp_est = tp4x;
    end
end


% ============================================================
% Crest factor (safe version)
% ============================================================
function c = crest_factor_db_safe(x)
    peak = max(abs(x));
    rmsv = sqrt(mean(x.^2));

    if rmsv < 1e-12
        c = 0;     % silence → crest factor meaningless
        return;
    end

    c = 20 * log10((peak + eps) / (rmsv + eps));

    if ~isfinite(c)
        c = 0;
    end
end


% ============================================================
% Safe spectral centroid
% ============================================================
function sc = spec_centroid_safe(x, Fs)
    N = 2048;
    x = fix_length(x, N);

    win = hann(N, "periodic");
    [S, F] = periodogram(x, win, N, Fs);

    sc = sum(F .* S) / (sum(S) + eps);

    if ~isfinite(sc)
        sc = 2000;   % fallback
    end
end


% ============================================================
% Safe spectral spread
% ============================================================
function bw = spec_spread_safe(x, Fs)
    N = 2048;
    x = fix_length(x, N);

    win = hann(N, "periodic");
    [S, F] = periodogram(x, win, N, Fs);

    mu = sum(F .* S) / (sum(S) + eps);
    bw = sqrt( sum(((F - mu).^2).*S) / (sum(S) + eps) );

    if ~isfinite(bw)
        bw = 1500;  % fallback
    end
end


% ============================================================
% Utility: enforce length N
% ============================================================
function y = fix_length(x, N)
    x = x(:);
    nx = numel(x);
    if nx < N
        y = [x; zeros(N-nx,1)];
    else
        y = x(1:N);
    end
end
