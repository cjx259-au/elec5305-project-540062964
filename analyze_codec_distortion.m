function analyze_codec_distortion(cfg, K)
% ANALYZE_CODEC_DISTORTION
% Comprehensive codec distortion analysis including:
%   - Spectral distortion analysis
%   - Short-term dynamics profile
%   - Loudness normalization simulation
%   - Full codec chain simulation with detailed metrics
%
% Inputs:
%   cfg - config struct
%   K   - max number of files to process (default: 10)

    if nargin < 1 || isempty(cfg), cfg = config(); end
    if nargin < 2, K = 10; end

    % Check FFmpeg availability
    if exist('isFFmpegAvailable', 'file')
        if ~isFFmpegAvailable()
            warning('analyze_codec_distortion: FFmpeg not found, skipping analysis.');
            return;
        end
    else
        [status,~] = system('ffmpeg -version >nul 2>&1');
        if status ~= 0
            warning('analyze_codec_distortion: FFmpeg not found, skipping analysis.');
            return;
        end
    end

    resultsDir = cfg.resultsDir;
    dataDir = cfg.dataDir;
    
    if ~exist(resultsDir,'dir'), mkdir(resultsDir); end
    
    files = dir(fullfile(dataDir,'*.wav'));
    if isempty(files)
        warning('No WAV files found in %s', dataDir);
        return;
    end
    
    K = min(K, numel(files));
    
    % Use platforms from config if available
    if isfield(cfg, 'platforms') && ~isempty(cfg.platforms)
        plats = cfg.platforms;
    else
        plats = platform_presets();
    end
    
    tmpDir = fullfile(tempdir,'codec_distortion_tmp');
    if ~exist(tmpDir,'dir'), mkdir(tmpDir); end
    
    % Storage for all results
    codecRows = {};
    spectralRows = {};
    dynamicsRows = {};
    normalizationRows = {};
    
    fprintf('[analyze_codec_distortion] Processing %d files...\n', K);
    
    for i = 1:K
        fname = files(i).name;
        fpath = fullfile(files(i).folder, fname);
        
        fprintf('  [%d/%d] %s\n', i, K, fname);
        
        try
            [x, Fs] = audioread(fpath);
            if size(x,2) > 1, x = mean(x,2); end
            if Fs ~= 48000
                x = resample(x, 48000, Fs);
                Fs = 48000;
            end
            
            % Original metrics
            M_orig = measure_loudness(x, Fs, cfg);
            if isfield(cfg, 'truePeakOversample')
                oversample = cfg.truePeakOversample;
            else
                oversample = 4;  % Default
            end
            tp_orig = truepeak_ref(x, Fs, oversample);
            
            % Short-term dynamics profile (original)
            dyn_orig = compute_shortterm_dynamics(x, Fs, cfg);
            
            for p = 1:numel(plats)
                plat = plats(p);
                
                % ============================================================
                % 1. PLATFORM LOUDNESS NORMALIZATION SIMULATION
                % ============================================================
                S = normalize_streaming(x, Fs, M_orig.integratedLUFS, tp_orig, ...
                                      plat.targetLUFS, cfg, plat, fname);
                y_norm = S.y;
                
                % Store normalization results
                normalizationRows{end+1} = {
                    string(fname),
                    string(plat.name),
                    M_orig.integratedLUFS,
                    tp_orig,
                    plat.targetLUFS,
                    S.postLUFS,
                    S.postTP,
                    S.gain_dB,
                    S.limited,
                    S.maxGR,
                    S.meanGR,
                    S.grTimeRatio
                };
                
                % Short-term dynamics after normalization
                dyn_norm = compute_shortterm_dynamics(y_norm, Fs, cfg);
                
                % Save normalized audio for codec processing
                [~,base,~] = fileparts(fname);
                wavNorm = fullfile(tmpDir, sprintf('%s_%s_norm.wav', base, plat.name));
                audiowrite(wavNorm, y_norm, Fs);
                
                % ============================================================
                % 2. CODEC SIMULATION WITH SPECTRAL ANALYSIS
                % ============================================================
                if isfield(plat, 'codecs') && ~isempty(plat.codecs)
                    for c = 1:numel(plat.codecs)
                        codec = plat.codecs(c);
                        
                        % Spectral analysis of normalized audio
                        spec_norm = compute_spectral_features(y_norm, Fs);
                        
                        % Encode
                        outCoded = fullfile(tmpDir, sprintf('%s_%s_%s.bin', ...
                            base, plat.name, codec.name));
                        encCmd = sprintf('ffmpeg -y -v error -i "%s" -c:a %s -b:a %s "%s"', ...
                            wavNorm, codec.ffmpegCodec, codec.bitrate, outCoded);
                        [encStatus, ~] = system(encCmd);
                        
                        if encStatus ~= 0
                            warning('Encoding failed: %s / %s', plat.name, codec.name);
                            continue;
                        end
                        
                        % Decode
                        outWav = fullfile(tmpDir, sprintf('%s_%s_%s_dec.wav', ...
                            base, plat.name, codec.name));
                        decCmd = sprintf('ffmpeg -y -v error -i "%s" -c:a pcm_s16le "%s"', ...
                            outCoded, outWav);
                        [decStatus, ~] = system(decCmd);
                        
                        if decStatus ~= 0 || ~isfile(outWav)
                            warning('Decoding failed: %s / %s', plat.name, codec.name);
                            continue;
                        end
                        
                        % Read decoded audio
                        [z, Fs2] = audioread(outWav);
                        if size(z,2) > 1, z = mean(z,2); end
                        if Fs2 ~= Fs, z = resample(z, Fs, Fs2); end
                        
                        % Post-codec metrics
                        M_codec = measure_loudness(z, Fs, cfg);
                        if isfield(cfg, 'truePeakOversample')
                            oversample = cfg.truePeakOversample;
                        else
                            oversample = 4;  % Default
                        end
                        tp_codec = truepeak_ref(z, Fs, oversample);
                        
                        % Spectral analysis of decoded audio
                        spec_codec = compute_spectral_features(z, Fs);
                        
                        % Spectral distortion metrics
                        spectralDist = compute_spectral_distortion(spec_norm, spec_codec);
                        
                        % Short-term dynamics after codec
                        dyn_codec = compute_shortterm_dynamics(z, Fs, cfg);
                        
                        % Dynamics change
                        dynChange = struct();
                        dynChange.meanLRA_change = dyn_codec.meanLRA - dyn_norm.meanLRA;
                        dynChange.maxLRA_change = dyn_codec.maxLRA - dyn_norm.maxLRA;
                        dynChange.dynamicRange_change = dyn_codec.dynamicRange - dyn_norm.dynamicRange;
                        
                        % Store codec chain results
                        codecRows{end+1} = {
                            string(fname),
                            string(plat.name),
                            string(codec.name),
                            string(codec.bitrate),
                            S.postLUFS,
                            S.postTP,
                            M_codec.integratedLUFS,
                            tp_codec,
                            tp_codec - S.postTP,  % TP overshoot
                            M_codec.integratedLUFS - S.postLUFS  % LUFS change
                        };
                        
                        % Store spectral distortion results
                        spectralRows{end+1} = {
                            string(fname),
                            string(plat.name),
                            string(codec.name),
                            string(codec.bitrate),
                            spec_norm.centroid,
                            spec_codec.centroid,
                            spectralDist.centroidDiff,
                            spec_norm.spread,
                            spec_codec.spread,
                            spectralDist.spreadDiff,
                            spec_norm.rolloff,
                            spec_codec.rolloff,
                            spectralDist.rolloffDiff,
                            spectralDist.snr,
                            spectralDist.spectralDistortion
                        };
                        
                        % Store short-term dynamics results
                        dynamicsRows{end+1} = {
                            string(fname),
                            string(plat.name),
                            string(codec.name),
                            string(codec.bitrate),
                            dyn_norm.meanLRA,
                            dyn_codec.meanLRA,
                            dynChange.meanLRA_change,
                            dyn_norm.maxLRA,
                            dyn_codec.maxLRA,
                            dynChange.maxLRA_change,
                            dyn_norm.dynamicRange,
                            dyn_codec.dynamicRange,
                            dynChange.dynamicRange_change,
                            dyn_norm.crestFactor,
                            dyn_codec.crestFactor
                        };
                    end
                end
            end
            
        catch ME
            warning('Failed to process %s: %s', fname, ME.message);
            continue;
        end
    end
    
    % ============================================================
    % Write all CSV files
    % ============================================================
    
    % Codec chain results
    if ~isempty(codecRows)
        T_codec = cell2table(codecRows, 'VariableNames', {
            'file', 'platform', 'codec', 'bitrate', ...
            'preLUFS', 'preTP', 'postLUFS', 'postTP', ...
            'tpOvershoot', 'lufsChange'
        });
        outCsv = fullfile(resultsDir, 'codec_overshoot.csv');
        force_write_table(T_codec, outCsv, 'WriteMode', 'overwrite');
        fprintf('[analyze_codec_distortion] Wrote %s (%d rows)\n', outCsv, height(T_codec));
    end
    
    % Spectral distortion results
    if ~isempty(spectralRows)
        T_spectral = cell2table(spectralRows, 'VariableNames', {
            'file', 'platform', 'codec', 'bitrate', ...
            'centroid_pre', 'centroid_post', 'centroidDiff', ...
            'spread_pre', 'spread_post', 'spreadDiff', ...
            'rolloff_pre', 'rolloff_post', 'rolloffDiff', ...
            'snr', 'spectralDistortion'
        });
        outCsv = fullfile(resultsDir, 'codec_spectral_distortion.csv');
        force_write_table(T_spectral, outCsv, 'WriteMode', 'overwrite');
        fprintf('[analyze_codec_distortion] Wrote %s (%d rows)\n', outCsv, height(T_spectral));
    end
    
    % Short-term dynamics results
    if ~isempty(dynamicsRows)
        T_dynamics = cell2table(dynamicsRows, 'VariableNames', {
            'file', 'platform', 'codec', 'bitrate', ...
            'meanLRA_pre', 'meanLRA_post', 'meanLRA_change', ...
            'maxLRA_pre', 'maxLRA_post', 'maxLRA_change', ...
            'dynamicRange_pre', 'dynamicRange_post', 'dynamicRange_change', ...
            'crestFactor_pre', 'crestFactor_post'
        });
        outCsv = fullfile(resultsDir, 'codec_dynamics_profile.csv');
        force_write_table(T_dynamics, outCsv, 'WriteMode', 'overwrite');
        fprintf('[analyze_codec_distortion] Wrote %s (%d rows)\n', outCsv, height(T_dynamics));
    end
    
    % Normalization results
    if ~isempty(normalizationRows)
        T_norm = cell2table(normalizationRows, 'VariableNames', {
            'file', 'platform', ...
            'preLUFS', 'preTP', 'targetLUFS', ...
            'postLUFS', 'postTP', 'gain_dB', ...
            'limited', 'maxGR', 'meanGR', 'grTimeRatio'
        });
        outCsv = fullfile(resultsDir, 'platform_normalization.csv');
        force_write_table(T_norm, outCsv, 'WriteMode', 'overwrite');
        fprintf('[analyze_codec_distortion] Wrote %s (%d rows)\n', outCsv, height(T_norm));
    end
    
    fprintf('[analyze_codec_distortion] Analysis complete.\n');
end

% =====================================================================
% Helper Functions
% =====================================================================

function spec = compute_spectral_features(x, Fs)
    % Compute spectral features: centroid, spread, rolloff
    
    % Ensure mono
    if size(x,2) > 1, x = mean(x,2); end
    
    % Compute FFT
    N = length(x);
    X = fft(x);
    X = X(1:floor(N/2)+1);  % Positive frequencies only
    f = (0:floor(N/2)) * Fs / N;
    
    % Power spectrum
    P = abs(X).^2;
    P = P / sum(P);  % Normalize
    
    % Ensure P is a row vector
    if size(P,1) > size(P,2), P = P'; end
    
    % Spectral centroid
    spec.centroid = sum(f .* P) / sum(P);
    
    % Spectral spread
    spec.spread = sqrt(sum(((f - spec.centroid).^2) .* P) / sum(P));
    
    % Spectral rolloff (95% energy)
    cumP = cumsum(P);
    rolloffIdx = find(cumP >= 0.95 * cumP(end), 1);
    if ~isempty(rolloffIdx)
        spec.rolloff = f(rolloffIdx);
    else
        spec.rolloff = f(end);
    end
end

function dist = compute_spectral_distortion(spec1, spec2)
    % Compute spectral distortion metrics
    
    dist.centroidDiff = spec2.centroid - spec1.centroid;
    dist.spreadDiff = spec2.spread - spec1.spread;
    dist.rolloffDiff = spec2.rolloff - spec1.rolloff;
    
    % Approximate SNR (simplified)
    dist.snr = -20 * log10(abs(dist.centroidDiff) / (spec1.centroid + eps));
    
    % Overall spectral distortion (weighted combination)
    dist.spectralDistortion = sqrt( ...
        (dist.centroidDiff / (spec1.centroid + eps))^2 + ...
        (dist.spreadDiff / (spec1.spread + eps))^2 + ...
        (dist.rolloffDiff / (spec1.rolloff + eps))^2 ...
    ) * 100;  % Percentage
end

function dyn = compute_shortterm_dynamics(x, Fs, cfg)
    % Compute short-term dynamics profile
    
    if size(x,2) > 1, x = mean(x,2); end
    
    % Window parameters (3 seconds for short-term analysis)
    winLen = round(3 * Fs);
    hopLen = round(0.1 * Fs);  % 100ms hop
    
    N = length(x);
    nFrames = max(1, floor((N - winLen) / hopLen) + 1);
    
    lraVals = zeros(nFrames, 1);
    peakVals = zeros(nFrames, 1);
    rmsVals = zeros(nFrames, 1);
    
    for i = 1:nFrames
        startIdx = (i-1) * hopLen + 1;
        endIdx = min(startIdx + winLen - 1, N);
        seg = x(startIdx:endIdx);
        
        if length(seg) < winLen * 0.5  % Skip if too short
            lraVals(i) = NaN;
            peakVals(i) = NaN;
            rmsVals(i) = NaN;
            continue;
        end
        
        % Compute LRA for this segment
        try
            M_seg = measure_loudness(seg, Fs, cfg);
            lraVals(i) = M_seg.LRA;
        catch
            lraVals(i) = NaN;
        end
        
        % Peak and RMS
        peakVals(i) = max(abs(seg));
        rmsVals(i) = sqrt(mean(seg.^2));
    end
    
    % Remove NaN values
    lraVals = lraVals(~isnan(lraVals));
    peakVals = peakVals(~isnan(peakVals));
    rmsVals = rmsVals(~isnan(rmsVals));
    
    if isempty(lraVals)
        dyn.meanLRA = NaN;
        dyn.maxLRA = NaN;
        dyn.dynamicRange = NaN;
        dyn.crestFactor = NaN;
        return;
    end
    
    % Statistics
    dyn.meanLRA = mean(lraVals);
    dyn.maxLRA = max(lraVals);
    
    % Dynamic range (peak to RMS ratio in dB)
    if ~isempty(peakVals) && ~isempty(rmsVals)
        peak_db = 20*log10(max(peakVals) + eps);
        rms_db = 20*log10(mean(rmsVals) + eps);
        dyn.dynamicRange = peak_db - rms_db;
        
        % Crest factor
        dyn.crestFactor = peak_db - rms_db;
    else
        dyn.dynamicRange = NaN;
        dyn.crestFactor = NaN;
    end
end

