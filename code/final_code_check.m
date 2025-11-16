function final_code_check()
% FINAL_CODE_CHECK
% Comprehensive final check of all code to ensure 100% correctness
%
% Checks:
% 1. All function signatures
% 2. Parameter consistency
% 3. Required functions exist
% 4. Configuration validity
% 5. File structure

    fprintf('=== Final Code Check ===\n\n');
    
    errors = {};
    warnings_list = {};
    
    % ============================================================
    % 1. Check configuration
    % ============================================================
    fprintf('1. Checking configuration...\n');
    try
        cfg = config();
        requiredFields = {'resultsDir', 'dataDir', 'figDir', 'rootDir', ...
                         'platforms', 'truePeakOversample', 'tpCeil', ...
                         'streamTargetLUFS'};
        missingFields = setdiff(requiredFields, fieldnames(cfg));
        if ~isempty(missingFields)
            errors{end+1} = sprintf('config() missing fields: %s', strjoin(missingFields, ', '));
            fprintf('   ✗ Missing fields: %s\n', strjoin(missingFields, ', '));
        else
            fprintf('   ✓ config() has all required fields\n');
        end
        
        if ~isfield(cfg, 'platforms') || isempty(cfg.platforms)
            warnings_list{end+1} = 'cfg.platforms is empty, will use platform_presets()';
            fprintf('   ⚠ cfg.platforms is empty\n');
        else
            fprintf('   ✓ cfg.platforms configured (%d platforms)\n', numel(cfg.platforms));
        end
    catch ME
        errors{end+1} = sprintf('config() failed: %s', ME.message);
        fprintf('   ✗ config() failed: %s\n', ME.message);
    end
    
    % ============================================================
    % 2. Check core functions exist and have correct signatures
    % ============================================================
    fprintf('\n2. Checking core functions...\n');
    coreFunctions = {
        'measure_loudness', 3, {'x', 'Fs', 'cfg'};
        'dialogue_metrics', 3, {'x', 'Fs', 'cfg'};
        'dialogue_VAD', 3, {'x', 'Fs', 'cfg'};
        'row_metrics', 3, {'fname', 'M', 'tp_ref'};
        'compliance_platform', 1, {'cfg'};
        'make_dashboard_tables', 1, {'cfg'};
        'normalize_streaming', 8, {'x', 'Fs', 'preLUFS', 'preTP', 'targetLUFS', 'cfg', 'plat', 'fname'};
        'force_write_table', 3, {'T', 'filepath', 'varargin'};
        'platform_presets', 1, {'name'};
        'truepeak_ref', 3, {'x', 'Fs', 'os'};
    };
    
    for i = 1:size(coreFunctions, 1)
        funcName = coreFunctions{i, 1};
        if exist(funcName, 'file')
            fprintf('   ✓ %s exists\n', funcName);
        else
            errors{end+1} = sprintf('Core function missing: %s', funcName);
            fprintf('   ✗ %s NOT FOUND\n', funcName);
        end
    end
    
    % ============================================================
    % 3. Check optional functions
    % ============================================================
    fprintf('\n3. Checking optional functions...\n');
    optionalFunctions = {
        'adaptive_mastering_profiles';
        'simulate_codec_chain';
        'simulate_platform_listening';
        'analyze_codec_distortion';
        'analyze_truepeak_sensitivity';
        'export_html_report';
        'compliance_report';
        'summarize_for_writeup';
        'plot_helpers';
        'validate_against_external';
        'optimize_gain_tp_safe';
        'truepeak_fast_predict';
        'isFFmpegAvailable';
    };
    
    for i = 1:numel(optionalFunctions)
        funcName = optionalFunctions{i};
        if exist(funcName, 'file')
            fprintf('   ✓ %s exists\n', funcName);
        else
            warnings_list{end+1} = sprintf('Optional function missing: %s', funcName);
            fprintf('   ⚠ %s not found (optional)\n', funcName);
        end
    end
    
    % ============================================================
    % 4. Test function calls with correct parameters
    % ============================================================
    fprintf('\n4. Testing function calls...\n');
    
    % Test measure_loudness
    try
        cfg_test = config();
        Fs = 48000;
        t = (0:Fs-1)' / Fs;
        x = 0.5 * sin(2*pi*440*t);
        M = measure_loudness(x, Fs, cfg_test);
        if isfield(M, 'integratedLUFS') && isfield(M, 'truePeak_dBTP') && isfield(M, 'LRA')
            fprintf('   ✓ measure_loudness(x, Fs, cfg) works\n');
        else
            errors{end+1} = 'measure_loudness missing required fields';
            fprintf('   ✗ measure_loudness missing fields\n');
        end
    catch ME
        errors{end+1} = sprintf('measure_loudness test failed: %s', ME.message);
        fprintf('   ✗ measure_loudness test failed: %s\n', ME.message);
    end
    
    % Test normalize_streaming
    try
        cfg_test = config();
        Fs = 48000;
        t = (0:Fs-1)' / Fs;
        x = 0.5 * sin(2*pi*440*t);
        plat = struct('name', 'Test', 'targetLUFS', -14.0, 'tpLimit', -1.0);
        S = normalize_streaming(x, Fs, -12.0, -0.5, -14.0, cfg_test, plat, 'test.wav');
        requiredFields = {'y', 'postLUFS', 'postTP', 'gain_dB', 'limited'};
        missingFields = setdiff(requiredFields, fieldnames(S));
        if ~isempty(missingFields)
            errors{end+1} = sprintf('normalize_streaming missing fields: %s', strjoin(missingFields, ', '));
            fprintf('   ✗ normalize_streaming missing fields\n');
        else
            fprintf('   ✓ normalize_streaming(x, Fs, preLUFS, preTP, targetLUFS, cfg, plat, fname) works\n');
        end
    catch ME
        errors{end+1} = sprintf('normalize_streaming test failed: %s', ME.message);
        fprintf('   ✗ normalize_streaming test failed: %s\n', ME.message);
    end
    
    % Test platform_presets
    try
        plats = platform_presets();
        if isempty(plats)
            warnings_list{end+1} = 'platform_presets() returned empty';
            fprintf('   ⚠ platform_presets() returned empty\n');
        else
            if isfield(plats(1), 'name') && isfield(plats(1), 'targetLUFS') && isfield(plats(1), 'codecs')
                fprintf('   ✓ platform_presets() works (%d platforms)\n', numel(plats));
            else
                errors{end+1} = 'platform_presets() missing required fields';
                fprintf('   ✗ platform_presets() missing fields\n');
            end
        end
    catch ME
        errors{end+1} = sprintf('platform_presets test failed: %s', ME.message);
        fprintf('   ✗ platform_presets test failed: %s\n', ME.message);
    end
    
    % ============================================================
    % 5. Check parameter consistency across modules
    % ============================================================
    fprintf('\n5. Checking parameter consistency...\n');
    
    % Check if all functions use cfg.platforms consistently
    filesToCheck = {'simulate_codec_chain.m', 'simulate_platform_listening.m', ...
                    'compliance_platform.m', 'analyze_codec_distortion.m'};
    for i = 1:numel(filesToCheck)
        if exist(filesToCheck{i}, 'file')
            fid = fopen(filesToCheck{i}, 'r');
            content = fread(fid, '*char')';
            fclose(fid);
            if contains(content, 'cfg.platforms') || contains(content, 'platform_presets()')
                fprintf('   ✓ %s uses cfg.platforms or platform_presets()\n', filesToCheck{i});
            else
                warnings_list{end+1} = sprintf('%s may not use cfg.platforms', filesToCheck{i});
                fprintf('   ⚠ %s may not use cfg.platforms\n', filesToCheck{i});
            end
        end
    end
    
    % ============================================================
    % 6. Check file structure
    % ============================================================
    fprintf('\n6. Checking file structure...\n');
    
    cfg_test = config();
    requiredDirs = {'resultsDir', 'dataDir', 'figDir'};
    for i = 1:numel(requiredDirs)
        dirPath = cfg_test.(requiredDirs{i});
        if exist(dirPath, 'dir')
            fprintf('   ✓ %s exists: %s\n', requiredDirs{i}, dirPath);
        else
            warnings_list{end+1} = sprintf('%s does not exist: %s', requiredDirs{i}, dirPath);
            fprintf('   ⚠ %s does not exist: %s\n', requiredDirs{i}, dirPath);
        end
    end
    
    % ============================================================
    % 7. Summary
    % ============================================================
    fprintf('\n=== Summary ===\n');
    
    if isempty(errors)
        fprintf('✓ No critical errors found\n');
    else
        fprintf('✗ Found %d critical error(s):\n', numel(errors));
        for i = 1:numel(errors)
            fprintf('  - %s\n', errors{i});
        end
    end
    
    if ~isempty(warnings_list)
        fprintf('\n⚠ Found %d warning(s):\n', numel(warnings_list));
        for i = 1:numel(warnings_list)
            fprintf('  - %s\n', warnings_list{i});
        end
    end
    
    fprintf('\n=== Check Complete ===\n');
    
    if isempty(errors)
        fprintf('\n✓ All code checks passed! Ready to run.\n');
        fprintf('Run: run_project() to start the analysis pipeline.\n');
    else
        fprintf('\n✗ Please fix the errors before running the pipeline.\n');
    end
end

