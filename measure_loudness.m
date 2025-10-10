function m = measure_loudness(x, Fs, cfg)
% 输出: m.intLUFS, m.stLUFS, m.mtLUFS, m.LRA，以及时间序列 m.stCurve/m.mtCurve

m = struct('intLUFS',nan,'stLUFS',nan,'mtLUFS',nan,'LRA',nan, ...
           'stCurve',[],'mtCurve',[],'t_st',[],'t_mt',[]);

try
    % ===== 优先：Audio Toolbox =====
    % loudnessMeter: 从 R2020b 起可用（需安装 Audio Toolbox）
    lm = audioLoudnessMeter('SampleRate',Fs); % 新版名称，如旧版为 loudnessMeter 请自行替换
    reset(lm);
    [L_momentary, L_shortTerm, L_integrated, L_range] = lm(x);
    m.intLUFS = L_integrated;
    m.stLUFS  = L_shortTerm(end);
    m.mtLUFS  = L_momentary(end);
    m.LRA     = L_range;

    % 拿到时间曲线（简单重算）
    [m.mtCurve, m.t_mt] = local_window_lufs(x, Fs, cfg.mtWindow);
    [m.stCurve, m.t_st] = local_window_lufs(x, Fs, cfg.stWindow);
    return;
catch
    % 没有 Toolbox，转简化实现
end

% ===== 简化实现（近似 BS.1770）=====
% 1) K-weighting（简化）：高通 + 高搁架
hp = designfilt('highpassiir','FilterOrder',2,'HalfPowerFrequency',60,'SampleRate',Fs);
xw = filtfilt(hp, x);
% 高搁架(1kHz, +4dB) 近似
G = 10^(4/20);
[b,a] = shelvingFilterCoeffs(Fs, 1000, G);
xw = filtfilt(b,a,xw);

% 2) 400ms 分块能量，计算未门限积分
blk = round(cfg.blockSec*Fs);
xpad = [xw; zeros(mod(-numel(xw),blk),1)];
X = reshape(xpad, blk, []);
E = mean(X.^2,1);                       % 均方
LUFS_ungated = -0.691 + 10*log10(mean(E)+eps);  % 常数 -0.691 近似

% 3) 绝对门限 -70 LUFS，+ 相对门限(相对未门限积分 -10 LU)
gateAbs = 10^((cfg.absGate+0.691)/10);
mask = E >= gateAbs;
E_gate1 = E(mask);
if isempty(E_gate1), m.intLUFS = -inf; else
    LUFS_rel = 10*log10(mean(E_gate1)+eps) - 0.691;
    gateRel = 10^(((LUFS_rel+cfg.relGate)+0.691)/10);
    mask2 = E >= max(gateAbs, gateRel);
    E_final = E(mask2);
    m.intLUFS = -0.691 + 10*log10(mean(E_final)+eps);
end

% 4) 短时/瞬时曲线（3s / 400ms）
[m.mtCurve, m.t_mt] = local_window_lufs(xw, Fs, cfg.mtWindow);
[m.stCurve, m.t_st] = local_window_lufs(xw, Fs, cfg.stWindow);

% 5) LRA（按 EBU 技术说明：短时分布的 10th–95th 百分位差）
if ~isempty(m.stCurve)
    p10 = prctile(m.stCurve,10); p95 = prctile(m.stCurve,95);
    m.LRA = p95 - p10;
else
    m.LRA = NaN;
end

% 简化估计的“代表值”
if ~isempty(m.stCurve), m.stLUFS = m.stCurve(end); end
if ~isempty(m.mtCurve), m.mtLUFS = m.mtCurve(end); end
end

% ---- helpers ----
function [curve, t] = local_window_lufs(x, Fs, winSec)
N = max(1, round(winSec*Fs));
w = hamming(N,'periodic');
step = round(0.100*Fs); % 每100ms 计算一次显示
idx = 1:step:(numel(x)-N+1);
curve = zeros(numel(idx),1); t = zeros(numel(idx),1);
for k=1:numel(idx)
    seg = x(idx(k):idx(k)+N-1).*w;
    lufs = -0.691 + 10*log10(mean(seg.^2)+eps);
    curve(k) = lufs; t(k) = (idx(k)+N/2)/Fs;
end
end

function [b,a] = shelvingFilterCoeffs(Fs, f0, G)
% 一阶高搁架近似
K = tan(pi*f0/Fs);
V0 = G;
if V0 < 1
    % cut
    b0 = 1; b1 = -1; b2 = 0;
    a0 = 1+K; a1 = -1+K; a2 = 0;
else
    % boost
    b0 = 1+V0*K; b1 = -1+V0*K; b2 = 0;
    a0 = 1+K;    a1 = -1+K;    a2 = 0;
end
b = [b0 b1 b2]/a0; a = [1 a1/a0 a2/a0];
end
