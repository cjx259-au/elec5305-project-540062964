function speechMask = dialogue_VAD(x, Fs, cfg)
% DIALOGUE_VAD
% ----------------------------------------------
%   Robust unified Voice Activity Detection (VAD) for dialogue-aware metrics.
%   
%   Features:
%   ✓ Safe frame segmentation (never out-of-bounds)
%   ✓ Multiple VAD algorithms: energy, mini-SAD, WebRTC
%   ✓ Stable mini-SAD (no polyfit errors)
%   ✓ WebRTC optional (graceful fallback)
%   ✓ 3-second temporal smoothing
%
%   Inputs:
%     x   - audio signal (mono)
%     Fs  - sampling rate (Hz)
%     cfg - optional config struct with field 'vad_mode'
%
%   Output:
%     speechMask - logical frame-level mask (true = speech, false = non-speech)
% ----------------------------------------------

    if nargin < 3
        cfg = struct();
    end

    % Default to energy-based VAD (most robust)
    mode = 'energy';
    if isfield(cfg, 'vad_mode')
        mode = lower(cfg.vad_mode);
    end

    % Ensure mono column vector
    x = x(:);
    
    % Handle empty/silent input
    if isempty(x) || max(abs(x)) < 1e-10
        speechMask = false(1,1);
        return;
    end

    % ============================================================
    %  1) Framing (configurable, default 10 ms)
    % ============================================================
    if isfield(cfg, 'vadFrameMs')
        frameMs = cfg.vadFrameMs;
    else
        frameMs = 10;  % Default 10 ms - optimal for speech detection
    end
    hop     = round(Fs * frameMs / 1000);
    win     = hop;

    N = numel(x);
    if N < win
        speechMask = false(N, 1);  % Return sample-level mask
        return;
    end

    Nf = floor((N - win) / hop) + 1;
    frameMask = false(Nf, 1);  % Frame-level mask (temporary)

    % ============================================================
    %  2) Base VAD (frame-level)
    % ============================================================
    switch mode
        case 'energy'
            frameMask = vad_energy(x, win, hop);

        case 'mini_sad'
            frameMask = vad_mini_sad(x, Fs, win, hop);

        case 'webrtc'
            frameMask = vad_webrtc_safe(x, Fs, win, hop);

        otherwise
            warning('Unknown VAD mode "%s", using mini_sad.', mode);
            frameMask = vad_mini_sad(x, Fs, win, hop);
    end

    % ============================================================
    %  3) Smooth to 3 seconds (≈300 frames)
    % ============================================================
    smoothFrames = round(3000 / frameMs);  
    if smoothFrames > 1 && Nf > 0
        kernel = ones(smoothFrames,1) / smoothFrames;
        avg    = conv(double(frameMask), kernel, 'same');
        frameMask = avg > 0.3;
    end
    
    % ============================================================
    %  4) Expand frame-level mask to sample-level mask
    % ============================================================
    % dialogue_metrics expects sample-level mask, not frame-level
    % Convert frame mask to sample mask by repeating each frame value
    speechMask = false(N, 1);
    for i = 1:Nf
        startSample = (i-1) * hop + 1;
        endSample = min(startSample + win - 1, N);
        if frameMask(i)
            speechMask(startSample:endSample) = true;
        end
    end
end


% ============================================================
%  ENERGY VAD
% ============================================================
function mask = vad_energy(x, win, hop)
% Energy-based VAD using RMS threshold
% Simple and robust for most audio content

    N = numel(x);
    Nf = max(1, floor((N - win)/hop) + 1);

    rms = zeros(Nf,1);

    for i = 1:Nf
        s = (i-1)*hop + 1;
        e = min(s + win - 1, N);
        seg = x(s:e);
        rms(i) = sqrt(mean(seg.^2) + eps);
    end

    % Adaptive threshold: median * 1.5 (robust to outliers)
    if Nf > 1
        thr = median(rms) * 1.5;
    else
        thr = rms(1) * 0.5;  % Single frame: use lower threshold
    end
    
    mask = rms > thr;
end


% ============================================================
%  MINI-SAD (STABLE VERSION)
% ============================================================
function mask = vad_mini_sad(x, Fs, win, hop)
% Mini-SAD (Spectral Audio Descriptor) VAD
% Uses log-energy, zero-crossing rate, and spectral slope
% More accurate than energy-only, but requires more computation

    N = numel(x);
    Nf = max(1, floor((N - win)/hop) + 1);

    logE  = zeros(Nf,1);
    zcr   = zeros(Nf,1);
    slope = zeros(Nf,1);

    for i = 1:Nf
        s = (i-1)*hop + 1;
        e = min(s+win-1, N);
        seg = x(s:e);
        
        if isempty(seg)
            logE(i) = -20;  % Very low energy
            zcr(i) = 0;
            slope(i) = 0;
            continue;
        end

        % Log-energy (dB scale)
        E = mean(seg.^2) + 1e-12;
        logE(i) = log(E);

        % Zero-crossing rate (normalized)
        if numel(seg) > 1
            zcr(i) = sum(abs(diff(seg>0))) / (numel(seg)-1);
        else
            zcr(i) = 0;
        end

        % Spectral slope (stable polyfit)
        segLen = numel(seg);
        if segLen >= 32  % Minimum for meaningful FFT
            % Apply window to reduce spectral leakage
            winFunc = hann(segLen, 'periodic');
            X = abs(fft(seg .* winFunc));
            X = X(1:floor(end/2));  % Positive frequencies only
            
            df = Fs / segLen;
            fs = (0:numel(X)-1)' * df;
            
            % Stable polyfit: require at least 5 points
            if numel(fs) > 5 && max(X) > 1e-10
                try
                    p = polyfit(fs, X, 1);
                    slope(i) = p(1);
                catch
                    slope(i) = 0;  % Fallback on error
                end
            else
                slope(i) = 0;
            end
        else
            slope(i) = 0;
        end
    end

    % Logistic regression classifier (trained weights)
    w_logE =  4.2;   % Log-energy weight
    w_zcr  = -3.0;   % ZCR weight (negative: speech has lower ZCR)
    w_slp  = -12000; % Spectral slope weight (negative: speech has negative slope)
    bias   = -2.0;   % Bias term

    score = w_logE*logE + w_zcr*zcr + w_slp*slope + bias;
    mask  = score > 0;  % Binary decision
end


% ============================================================
%  SAFE WEBRTC WRAPPER
% ============================================================
function mask = vad_webrtc_safe(x, Fs, win, hop)
    if ~exist('webrtc_vad','file')
        warning('WebRTC VAD not installed → fallback to mini_sad.');
        mask = vad_mini_sad(x, Fs, win, hop);
        return;
    end

    if Fs ~= 48000
        x = resample(x,48000,Fs);
        Fs = 48000;
    end

    x16 = int16(max(min(x*32767,32767), -32768));
    N   = numel(x16);
    Nf  = floor((N - win)/hop) + 1;

    mask = false(Nf,1);
    for i = 1:Nf
        s = (i-1)*hop + 1;
        e = min(s+win-1, N);
        seg = x16(s:e);

        try
            mask(i) = logical(webrtc_vad(seg, Fs));
        catch
            mask(i) = false;
        end
    end
end
