function simulate_codec_chain(cfg, K)
% SIMULATE_CODEC_CHAIN
% Encode → decode → measure codec-induced TP overshoot.
%
% simulate_codec_chain(cfg, K)
%   cfg : config()
%   K   : max number of files (default 20)

    if nargin < 1 || isempty(cfg), cfg = config(); end
    if nargin < 2, K = 20; end

    % Check FFmpeg availability (silent if already checked in parent)
    if exist('isFFmpegAvailable', 'file')
        if ~isFFmpegAvailable()
            warning('simulate_codec_chain:ffmpegMissing', ...
                    'FFmpeg not found, skip codec simulation.');
            return;
        end
    else
        % Fallback check if isFFmpegAvailable doesn't exist
        [status,~] = system('ffmpeg -version >nul 2>&1');
        if status ~= 0
            warning('simulate_codec_chain:ffmpegMissing', ...
                    'FFmpeg not found, skip codec simulation.');
            return;
        end
    end

    dataDir    = cfg.dataDir;
    resultsDir = cfg.resultsDir;

    fslist = dir(fullfile(dataDir,'*.wav'));
    if isempty(fslist)
        warning('No WAV files found under %s', dataDir);
        return;
    end

    K = min(K, numel(fslist));
    
    % Use platforms from config if available, otherwise use platform_presets()
    if isfield(cfg, 'platforms') && ~isempty(cfg.platforms)
        plats = cfg.platforms;
    else
        plats = platform_presets();
    end
    
    tmpDir = fullfile(tempdir,'codec_chain_tmp');
    if ~exist(tmpDir,'dir'), mkdir(tmpDir); end

    rows = {};

    for i = 1:K
        fpath = fullfile(fslist(i).folder, fslist(i).name);
        [x,Fs] = audioread(fpath);
        if size(x,2)>1, x = mean(x,2); end
        if Fs~=48000
            x = resample(x,48000,Fs); Fs = 48000;
        end

        % baseline TP
        tp_before = truepeak_ref(x,Fs,4);

        % for each platform + codec
        for p = 1:numel(plats)
            plat = plats(p);

            % normalise for this platform
            M = measure_loudness(x,Fs,cfg);  
            S = normalize_streaming(x,Fs,M.integratedLUFS,tp_before, ...
                                    plat.targetLUFS,cfg,plat,fslist(i).name);
            y = S.y;

            % pre-codec TP 
            if isfield(cfg, 'truePeakOversample')
                oversample = cfg.truePeakOversample;
            else
                oversample = 4;  
            end
            tp_pre = truepeak_ref(y,Fs,oversample);

            % temp WAV
            [~,base,~] = fileparts(fslist(i).name);
            wavNorm = fullfile(tmpDir, sprintf('%s_%s_norm.wav', ...
                                base, plat.name));
            audiowrite(wavNorm,y,Fs);

            for c = 1:numel(plat.codecs)
                codec   = plat.codecs(c);
                outCoded= fullfile(tmpDir, sprintf('%s_%s_%s.bin', ...
                                   base, plat.name, codec.name));
                outWav  = fullfile(tmpDir, sprintf('%s_%s_%s_dec.wav', ...
                                   base, plat.name, codec.name));

                encCmd = sprintf('ffmpeg -y -v error -i "%s" -c:a %s -b:a %s "%s"', ...
                                  wavNorm, codec.ffmpegCodec, codec.bitrate, outCoded);
                decCmd = sprintf('ffmpeg -y -v error -i "%s" -c:a pcm_s16le "%s"', ...
                                  outCoded, outWav);
                system(encCmd);
                system(decCmd);

                try
                    [z,Fs2] = audioread(outWav);
                catch
                    warning('Decode failed for %s / %s', plat.name, codec.name);
                    continue;
                end
                if size(z,2)>1, z = mean(z,2); end
                if Fs2~=Fs, z = resample(z,Fs,Fs2); end

                tp_post = truepeak_ref(z,Fs,oversample);  
                overshoot = tp_post - tp_pre;

                % Ensure all values are valid before adding
                if ~isfinite(tp_pre), tp_pre = NaN; end
                if ~isfinite(tp_post), tp_post = NaN; end
                if ~isfinite(overshoot), overshoot = NaN; end
                
                rows = [rows; { ...
                    string(fslist(i).name), ...
                    string(plat.name), ...
                    string(codec.name), ...
                    string(codec.bitrate), ...
                    double(tp_pre), ...
                    double(tp_post), ...
                    double(overshoot)}]; %#ok<AGROW>
            end
        end
    end

    if isempty(rows)
        warning('simulate_codec_chain: No codec rows produced. Check FFmpeg availability and codec settings.');
        return;
    end

    try
        T = cell2table(rows,'VariableNames', ...
            {'file','platform','codec','bitrate', ...
             'tp_preCodec','tp_postCodec','overshoot'});
    catch ME
        warning('simulate_codec_chain: Failed to create table: %s', ME.message);
        return;
    end

    outCsv = fullfile(resultsDir,'codec_overshoot.csv');
    
   
    try
        success = force_write_table(T, outCsv, 'WriteMode', 'overwrite');
        if success
            fprintf('[simulate_codec_chain] Wrote %s (%d rows)\n', outCsv, height(T));
        else
            error('force_write_table returned false');
        end
    catch ME
        error('simulate_codec_chain: Failed to write CSV: %s\n  File: %s\n  Please close the file if it is open in Excel or another program.', ...
            ME.message, outCsv);
    end
end
