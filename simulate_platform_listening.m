function simulate_platform_listening(cfg, K)
% SIMULATE_PLATFORM_LISTENING
%   Produce *clean* CSV:
%     file, platform, codec, bitrate,
%     preLUFS, preTP, postLUFS, postTP,
%     tpCeil, overshoot

    if nargin < 1 || isempty(cfg), cfg = config(); end
    if nargin < 2, K = Inf; end

    resultsDir = cfg.resultsDir;
    dataDir    = cfg.dataDir;

    if ~exist(resultsDir,'dir'), mkdir(resultsDir); end
    if ~exist(dataDir,'dir'), error('No WAV files found'); end

    files = dir(fullfile(dataDir,'*.wav'));
    if isempty(files)
        warning('No wav files in %s', dataDir);
        return;
    end
    if isinf(K) || K > numel(files)
        K = numel(files);
    end

    % Use platforms from config if available, otherwise use platform_presets()
    if isfield(cfg, 'platforms') && ~isempty(cfg.platforms)
        plats = cfg.platforms;
    else
        plats = platform_presets();
    end
    
    tmpDir = fullfile(tempdir,'simulate_listen_tmp');
    if ~exist(tmpDir,'dir'), mkdir(tmpDir); end

    rows = {};

    for i = 1:K
        fname = files(i).name;
        fpath = fullfile(files(i).folder,fname);

        [x,Fs] = audioread(fpath);
        if size(x,2)>1, x = mean(x,2); end
        if Fs~=48000
            x = resample(x,48000,Fs); Fs = 48000;
        end

        M = measure_loudness(x,Fs,cfg);
        preLUFS = M.integratedLUFS;
        if isfield(cfg, 'truePeakOversample')
            oversample = cfg.truePeakOversample;
        else
            oversample = 4;
        end
        preTP   = truepeak_ref(x,Fs,oversample);

        for p = 1:numel(plats)
            plat = plats(p);

            % --- 1) 平台响度归一化 ---
            S = normalize_streaming(x,Fs,preLUFS,preTP,plat.targetLUFS,cfg,plat,fname);
            y = S.y;

            LUFS_preCodec = S.postLUFS;
            TP_preCodec   = S.postTP;

            % 保存到临时 wav
            [~,base,~] = fileparts(fname);
            normWav = fullfile(tmpDir,sprintf('%s_%s_norm.wav',base,plat.name));
            audiowrite(normWav,y,Fs);

            % --- 2) codec 处理 ---
            for c = 1:numel(plat.codecs)
                codec = plat.codecs(c);

                outCoded = fullfile(tmpDir,'tmp.bin');
                outWav   = fullfile(tmpDir,'tmp_dec.wav');

                cmd1 = sprintf('ffmpeg -y -v error -i "%s" -c:a %s -b:a %s "%s"', ...
                    normWav, codec.ffmpegCodec, codec.bitrate, outCoded);
                cmd2 = sprintf('ffmpeg -y -v error -i "%s" -c:a pcm_s16le "%s"', ...
                    outCoded, outWav);

                system(cmd1);
                system(cmd2);

                if ~isfile(outWav)
                    warning('Codec decode failed: %s / %s',plat.name,codec.name);
                    continue;
                end

                [z,Fs2] = audioread(outWav);
                if size(z,2)>1, z = mean(z,2); end
                if Fs2~=Fs, z = resample(z,Fs,Fs2); end

                Mz = measure_loudness(z,Fs,cfg);
                postLUFS = Mz.integratedLUFS;
                if isfield(cfg, 'truePeakOversample')
                    oversample = cfg.truePeakOversample;
                else
                    oversample = 4;
                end
                postTP   = truepeak_ref(z,Fs,oversample);

                overshoot = postTP - plat.tpLimit;

                rows(end+1,:) = { ...
                    fname, ...
                    plat.name, ...
                    codec.name, ...
                    codec.bitrate, ...
                    LUFS_preCodec, ...
                    TP_preCodec, ...
                    postLUFS, ...
                    postTP, ...
                    plat.tpLimit, ...
                    overshoot ...
                };
            end
        end
    end

    
    T = cell2table(rows, ...
        'VariableNames',{ ...
            'file','platform','codec','bitrate', ...
            'preLUFS','preTP','postLUFS','postTP', ...
            'tpCeil','overshoot'});

    outCsv = fullfile(resultsDir,'platform_listening.csv');
    try
        success = force_write_table(T, outCsv, 'WriteMode', 'overwrite');
        if success
            fprintf('[simulate_platform_listening] Wrote %s (%d rows)\n', outCsv, height(T));
        else
            warning('[simulate_platform_listening] Failed to write %s', outCsv);
        end
    catch ME
        warning('[simulate_platform_listening] Failed to write %s: %s', outCsv, ME.message);
    end
end
