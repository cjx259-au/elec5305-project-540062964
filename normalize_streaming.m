function [y, info] = normalize_streaming(x, Fs, targetLUFS, cfg)
% 把音频“播放响度”对齐到 targetLUFS；若真峰值超限，做软限

m   = measure_loudness(x, Fs, cfg);
gain = targetLUFS - m.intLUFS;   % LU == dB
y0  = x * 10^(gain/20);

preTP  = truepeak_dbTP(x, Fs, cfg).dbTP;
postTP = truepeak_dbTP(y0,Fs, cfg).dbTP;

limited = false;
y = y0;
if postTP > cfg.tpCeil
    limited = true;
    thr = 10^(cfg.limiterKnee*cfg.tpCeil/20);  % 近似阈值（线性幅度）
    y = softLimiter(y0, thr);
    postTP = truepeak_dbTP(y,Fs, cfg).dbTP;
end

m2 = measure_loudness(y, Fs, cfg);

info = struct('startLUFS', m.intLUFS, ...
              'gain_dB', gain, ...
              'postLUFS', m2.intLUFS, ...
              'pre_dbTP', preTP, ...
              'post_dbTP', postTP, ...
              'limited', limited);
end

function y = softLimiter(x, thr)
% 简单软限器（tanh），thr 为线性幅度阈值
a = 3;                        % 曲线陡峭度
y = x;
idx = abs(x) > thr;
y(idx) = thr .* tanh(a * (x(idx)/thr));
% 重新归一防止偶发超出
y = y / max(1, max(abs(y)));
end
