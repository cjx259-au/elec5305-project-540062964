function run_all_experiments()
% RUN_ALL_EXPERIMENTS
% One-click master pipeline:
%   1) Compute metrics + normalization + compliance
%   2) (Optional) validate against external CSV if present
%   3) Export HTML report
%   4) Run TP-safe optimizer demo for first few WAV files
%
%   This version is fully safe, avoids cd(), and never crashes
%   the entire pipeline due to missing optional modules.

    % -----------------------------------------------------------
    % Load config & important paths
    % -----------------------------------------------------------
    cfg = config();
    fprintf('\n=== ELEC5305 RUN_ALL_EXPERIMENTS START ===\n');

    % -----------------------------------------------------------
    % 1) FULL PIPELINE
    % -----------------------------------------------------------
    try
        fprintf('\n[1] Running main pipeline: run_project...\n');
        run_project();
        fprintf('[OK] run_project completed.\n');
    catch ME
        warning('[run_all_experiments] run_project failed: %s', ME.message);
    end

    % -----------------------------------------------------------
    % 2) ADAPTIVE MASTERING PROFILES (optional)
    % -----------------------------------------------------------
    try
        if exist('adaptive_mastering_profiles','file')
            fprintf('\n[2] Running adaptive mastering profiles analysis...\n');
            adaptive_mastering_profiles(cfg);
            fprintf('[OK] Adaptive mastering profiles completed.\n');
        else
            fprintf('[2] adaptive_mastering_profiles.m not found → skipped.\n');
        end
    catch ME
        warning('[run_all_experiments] adaptive_mastering_profiles failed: %s', ME.message);
    end

    % -----------------------------------------------------------
    % 3) OPTIONAL VALIDATION (safe)
    % -----------------------------------------------------------
    try
        if exist('validate_against_external','file')
            fprintf('\n[3] validate_against_external found -> running...\n');
            validate_against_external();
            fprintf('[OK] validation completed.\n');
        else
            fprintf('[3] validate_against_external.m not found → skipped.\n');
        end
    catch ME
        warning('[run_all_experiments] validation failed: %s', ME.message);
    end

    % -----------------------------------------------------------
    % 4) EXPORT HTML REPORT
    % -----------------------------------------------------------
    try
        fprintf('\n[4] Exporting HTML report...\n');
        export_html_report();
        fprintf('[OK] HTML report generated.\n');
    catch ME
        warning('[run_all_experiments] export_html_report failed: %s', ME.message);
    end

    % -----------------------------------------------------------
    % 5) TP-SAFE OPTIMIZER DEMO
    % -----------------------------------------------------------
    try
        fprintf('\n[5] Running TP-safe optimizer demo (first few WAV files)...\n');

        fs = dir(fullfile(cfg.dataDir, '**', '*.wav'));
        if isempty(fs)
            warning('No WAV files found under %s — demo skipped.', cfg.dataDir);
        else
            K = min(5, numel(fs));
            for i = 1:K
                fpath = fullfile(fs(i).folder, fs(i).name);

                [x,Fs] = audioread(fpath);
                if size(x,2) > 1
                    x = mean(x,2);
                end
                if Fs ~= 48000
                    x = resample(x,48000,Fs);
                    Fs = 48000;
                end

                % true-peak safe optimizer
                out = optimize_gain_tp_safe(x, Fs, cfg.tpCeil, cfg);

                % reference TP
                tp4 = truepeak_ref(x, Fs, 4);

                % fast TP estimate (your implementation = no tp anchor needed)
                try
                    tpf = truepeak_fast_predict(x, Fs);
                catch
                    tpf = tp4; % fallback
                end

                fprintf('[%s]\n  TP-safe gain=%.2f dB | postLUFS=%.2f | postTP=%.2f dBTP\n  fastTP=%.2f dBTP | TP4=%.2f\n\n', ...
                    fs(i).name, out.gain, out.postLUFS, out.postTP, tpf, tp4);
            end
        end

        fprintf('[OK] TP-safe demo done.\n');
    catch ME
        warning('[run_all_experiments] TP-safe demo failed: %s', ME.message);
    end

    fprintf('\n=== RUN_ALL_EXPERIMENTS END ===\n\n');
end
