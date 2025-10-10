function tp = truepeak_dbTP(x, Fs, cfg)
% 过采样估计真峰值（dBTP）
os  = cfg.truePeakOversample; 
y   = resample(x, os, 1);              % 简单上采样（足够教学使用）
peak= max(abs(y));
tp.dbTP = 20*log10(max(peak, eps));
end
