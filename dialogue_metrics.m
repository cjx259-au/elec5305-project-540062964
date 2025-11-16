function D = dialogue_metrics(x, Fs, cfg)
% DIALOGUE_METRICS
% ---------------------------------------------------------
% Dialogue-aware metrics:
%   - speech ratio
%   - speech-only LUFS (approx.)
%   - programme LUFS
%   - Dialogue Loudness Difference (LD)
%
% Fully error-proof: any exception returns complete fields, won't affect main pipeline.
% ---------------------------------------------------------

    % Parameter handling
    if nargin < 3 || isempty(cfg)
        cfg = struct();
    end

    % Initialize output
    D = struct( ...
        'speechRatio', NaN, ...
        'speechLUFS',  NaN, ...
        'progLUFS',    NaN, ...
        'LD',          NaN, ...
        'flag_risky',  false, ...
        'flag_bad',    false );

    try
        if isempty(x)
            return;  % Empty input returns default D directly
        end

        x = x(:);  % Force column vector

        % ============================================================
        % 1) Voice Activity Detection
        % ============================================================
        try
            vad = dialogue_VAD(x, Fs, cfg);     % Returns sample-level logical mask (pass cfg)
            % Ensure it's a column vector of the correct size
            if numel(vad) ~= numel(x)
                warning('dialogue_VAD returned mask of size %d, expected %d. Using fallback.', ...
                    numel(vad), numel(x));
                vad = [];  % Trigger fallback
            end
        catch ME
            warning('dialogue_VAD failed: %s. Using fallback.', ME.message);
            vad = [];  % Trigger fallback
        end
        
        % Fallback: simple energy-based VAD if dialogue_VAD failed
        if isempty(vad) || numel(vad) ~= numel(x)
            frame = round(0.02 * Fs);      % 20 ms
            vad = false(size(x));
            for k = 1:frame:numel(x)
                seg = x(k : min(k+frame-1, end));
                e = mean(seg.^2);
                if e > 1e-4                % Simple threshold
                    vad(k : min(k+frame-1, end)) = true;
                end
            end
        end

        % Ensure boolean mask
        speechMask = logical(vad(:));

        speechRatio = mean(speechMask);
        D.speechRatio = speechRatio;

        % ============================================================
        % 2) Speech-only LUFS (approx)
        % ============================================================
        if any(speechMask)
            speechSeg = x(speechMask);
            D.speechLUFS = approx_LUFS(speechSeg);
        else
            D.speechLUFS = NaN;
        end

        % ============================================================
        % 3) Programme LUFS
        % ============================================================
        D.progLUFS = approx_LUFS(x);

        % ============================================================
        % 4) Dialogue Level Difference
        % ============================================================
        if ~isnan(D.speechLUFS)
            D.LD = D.speechLUFS - D.progLUFS;
        else
            D.LD = NaN;
        end

        % ============================================================
        % 5) Flags (used by your project)
        % ============================================================
        D.flag_risky = (D.speechRatio < 0.05);   % Too little speech
        D.flag_bad   = (D.LD < -5);              % Speech level too low

    catch
        % Fallback already initialized above, no need to handle again
    end
end

% ======================================================================
% Helper: Stable approx LUFS
% ======================================================================
function L = approx_LUFS(x)
    x = double(x(:));
    if isempty(x)
        L = NaN;
        return;
    end

    % Prevent overflow
    rmsVal = sqrt(mean(x.^2) + eps);
    L = -0.691 + 20*log10(rmsVal + eps);
end
