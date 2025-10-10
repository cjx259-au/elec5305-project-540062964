function C = compliance_report(T, cfg)
% 输入: T = metrics.csv 的表
% 输出: 每条音频是否满足 R128 / A85，以及建议增益

n = height(T);
r128_pass = false(n,1);
a85_pass  = false(n,1);
gain_r128 = zeros(n,1);
gain_a85  = zeros(n,1);
tpRisk    = T.TruePeak_dBTP > cfg.R128_maxTP;

for i=1:n
    % 与目标差（正数表示比目标响，负数表示偏小）
    d_r128 = T.IntegratedLUFS(i) - cfg.R128_targetLUFS;
    d_a85  = T.IntegratedLUFS(i) - cfg.A85_targetLKFS;

    % 建议增益（LU == dB）
    gain_r128(i) = -d_r128;
    gain_a85(i)  = -d_a85;

    r128_pass(i) = (abs(d_r128) <= 1.0) && (T.TruePeak_dBTP(i) <= cfg.R128_maxTP);
    a85_pass(i)  = (abs(d_a85)  <= 1.0) && (T.TruePeak_dBTP(i) <= 0); % A/85 对 TP 实践多为 ≤0 dBTP，按需调整
end

C = T(:,{'file','IntegratedLUFS','LRA','TruePeak_dBTP'});
C.R128_target  = repmat(cfg.R128_targetLUFS, n,1);
C.R128_gainLU  = gain_r128;
C.R128_pass    = r128_pass;
C.A85_target   = repmat(cfg.A85_targetLKFS, n,1);
C.A85_gainLU   = gain_a85;
C.A85_pass     = a85_pass;
C.TP_overRisk  = tpRisk;
end
