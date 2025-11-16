function tp = truepeak_ref(x, Fs, os)
% TRUEPEAK_REF
% High-robustness oversampled true-peak estimator (BS.1770-style).
%
%   tp = truepeak_ref(x, Fs, os)
%
% INPUT:
%   x  - mono vector
%   Fs - sampling rate (any Fs ok)
%   os - oversampling factor in {1,2,4,8,16} (default 4)
%
% OUTPUT:
%   tp - True Peak in dBTP
%
% Notes:
% - Memory safe (uses chunk-OSF if needed)
% - DC-free
% - Fully compatible with ELEC5305 system

    % ------------------------------------------------------------
    % 0. Input handling
    % ------------------------------------------------------------
    x = x(:);

    if ~isfinite(Fs) || Fs <= 0
        error('[truepeak_ref] Invalid sampling rate.');
    end

    if nargin < 3 || isempty(os)
        os = 4;   % safer default than 8×
    end

    if ~isscalar(os) || os < 1 || mod(os,1)~=0
        warning('[truepeak_ref] Invalid os=%s. Using 4×.', num2str(os));
        os = 4;
    end

    if ~ismember(os, [1 2 4 8 16])
        warning('[truepeak_ref] os=%d not supported. Using 4×.', os);
        os = 4;
    end

    % Handle silence
    if max(abs(x)) < 1e-12
        tp = -Inf;  % true silence
        return;
    end

    % Remove DC
    x = x - mean(x);


    % ------------------------------------------------------------
    % 1. Oversampling (memory-safe)
    % ------------------------------------------------------------
    try
        % If audio extremely long → chunk OSF
        MAXLEN = 2e6;   % ~2M samples threshold
        if numel(x) > MAXLEN
            y = oversample_chunked(x, os);
        else
            y = resample(x, os, 1);
        end
    catch ME
        warning('[truepeak_ref] Oversample failed: %s → using non-OS.', ME.message);
        y = x;
        os = 1;
    end


    % ------------------------------------------------------------
    % 2. Compute True Peak
    % ------------------------------------------------------------
    peak_lin = max(abs(y));

    tp = 20 * log10(peak_lin + eps);

    % ------------------------------------------------------------
    % 3. Output safety
    % ------------------------------------------------------------
    if ~isfinite(tp)
        tp = 20*log10(max(abs(x)) + eps);
        warning('[truepeak_ref] Non-finite TP → fallback used.');
    end
end


% =====================================================================
% Chunked oversampling for memory safety
% =====================================================================
function y = oversample_chunked(x, os)
    N = numel(x);
    CH = 500000;  % chunk size (≈0.5M samples)
    nChunk = ceil(N / CH);

    y = [];

    for k = 1:nChunk
        idx = (k-1)*CH+1 : min(k*CH, N);
        seg = x(idx);

        try
            y_seg = resample(seg, os, 1);
        catch
            % Last fallback: no OSF for this chunk
            y_seg = seg;
        end

        y = [y; y_seg]; %#ok<AGROW>
    end
end
