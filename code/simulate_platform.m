function [y,meta] = apply_platform_playback(x,Fs,trackLUFS,trackTP,plat,cfg)

target = plat.targetLUFS;
tpCeil = plat.tpLimit;

% Playback gain: only attenuate, never boost
if trackLUFS > target
    gain_dB = target - trackLUFS;
else
    gain_dB = 0;
end

g = 10^(gain_dB/20);
u = x * g;

% Simple limiter
th = 10^(tpCeil/20);
gr = ones(size(u));

peek = abs(u);
idx = peek > th;
gr(idx) = th ./ peek(idx);
u = u .* gr;

meta.playbackGain_dB = gain_dB;
meta.maxGR  = max(-20*log10(gr));
meta.meanGR = mean(-20*log10(gr));
meta.grTimeRatio = mean(gr < 1);

tp_lin = max(abs(u));
meta.postTP = 20*log10(tp_lin + 1e-12);
meta.postLUFS = trackLUFS + gain_dB - meta.meanGR;

y = u;

end
