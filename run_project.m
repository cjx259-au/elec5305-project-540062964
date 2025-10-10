function run_project()
clc; close all;
addpath(pwd);

cfg = config();                   % 读取配置
rng(cfg.seed);

root = fileparts(pwd);
dataDir = fullfile(root,'data','wav');
resDir  = fullfile(root,'results'); if ~exist(resDir,'dir'), mkdir(resDir); end
figDir  = fullfile(root,'figures'); if ~exist(figDir,'dir'), mkdir(figDir); end

files = dir(fullfile(dataDir,'**','*.wav'));
assert(~isempty(files), 'data/wav 里没有 wav 文件。');

T = table();
for i = 1:numel(files)
    fpath = fullfile(files(i).folder, files(i).name);
    [x,Fs] = audioread(fpath);
    x = mean(x,2);

    m  = measure_loudness(x, Fs, cfg);
    tp = truepeak_dbTP(x, Fs, cfg);

    row = table(string(files(i).name), Fs, ...
        m.intLUFS, m.stLUFS, m.mtLUFS, m.LRA, tp.dbTP, ...
        'VariableNames',{'file','Fs','IntegratedLUFS','ShortTermLUFS','MomentaryLUFS','LRA','TruePeak_dBTP'});
    T = [T; row]; %#ok<AGROW>

    plot_helpers('lufs_timeline', m, files(i).name, figDir);
end
writetable(T, fullfile(resDir,'metrics.csv'));
fprintf('Saved metrics -> %s\n', fullfile(resDir,'metrics.csv'));

C = compliance_report(T, cfg);
writetable(C, fullfile(resDir,'compliance.csv'));
fprintf('Saved compliance -> %s\n', fullfile(resDir,'compliance.csv'));

N = table();
for i = 1:numel(files)
    fpath = fullfile(files(i).folder, files(i).name);
    [x,Fs] = audioread(fpath);
    x = mean(x,2);

    [y, info] = normalize_streaming(x, Fs, cfg.streamTargetLUFS, cfg);
    N = [N; table(string(files(i).name), info.startLUFS, info.gain_dB, info.postLUFS, ...
        info.pre_dbTP, info.post_dbTP, info.limited, ...
        'VariableNames',{'file','StartLUFS','Gain_dB','PlaybackLUFS','Pre_dBTP','Post_dBTP','LimiterTriggered'})]; %#ok<AGROW>
end
writetable(N, fullfile(resDir,'normalization.csv'));
fprintf('Saved normalization -> %s\n', fullfile(resDir,'normalization.csv'));

plot_helpers('scatter_LU_deltaTP', T, C, figDir);
plot_helpers('hist_LRA', T, [], figDir);

disp('All done.');
end
