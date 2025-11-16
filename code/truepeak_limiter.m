function [y, meta] = truepeak_limiter(x, Fs, tpCeil, cfg)
% TRUEPEAK_LIMITER
% Look-ahead peak limiter approximating a TP-safe behaviour.
%
% [y, meta] = truepeak_limiter(x, Fs, tpCeil, cfg)
%
% meta fields:
%   maxGR_dB      : max gain reduction (dB)
%   meanGR_dB     : mean GR (dB)
%   grTimeRatio   : fraction of samples with GR > 0.1 dB
%   grCurve_dB    : vector of GR over time (optional, large!)
%
% Notes:
%   - For project use; not a production-grade limiter but close enough.

    if nargin < 4, cfg = struct(); end
    if nargin < 3 || isempty(tpCeil), tpCeil = -1; end

    x = x(:);
    N = numel(x);

    % ----- limiter params -----
    if isfield(cfg,'limiterAttack_ms')
        att_ms = cfg.limiterAttack_ms;
    else
        att_ms = 3;
    end
    if isfield(cfg,'limiterRelease_ms')
        rel_ms = cfg.limiterRelease_ms;
    else
        rel_ms = 50;
    end

    att = exp(-1/(att_ms*1e-3*Fs));
    rel = exp(-1/(rel_ms*1e-3*Fs));

    tpLin = 10^(tpCeil/20);

    env = 0;
    g   = ones(N,1);   % linear gain
    gr  = zeros(N,1);  % gain reduction in dB

    for n = 1:N
        a = abs(x(n));

        % envelope follower
        if a > env
            env = att*env + (1-att)*a;
        else
            env = rel*env + (1-rel)*a;
        end

        if env > tpLin
            need = tpLin / (env + eps);
        else
            need = 1.0;
        end
        g(n)  = need;
        gr(n) = -20*log10(need + eps);
    end

    y = x .* g;

    meta = struct();
    meta.maxGR_dB    = max(gr);
    meta.meanGR_dB   = mean(gr);
    meta.grTimeRatio = mean(gr > 0.1);
    meta.grCurve_dB  = gr;   % 如不需要可在外面丢弃，节省空间
end
