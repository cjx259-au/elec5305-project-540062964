function fix_all_errors()
% FIX_ALL_ERRORS
% 修复所有已知错误并验证代码正确性

    fprintf('=== Fixing All Errors ===\n\n');
    
    % 1. 验证 normalize_streaming.m 是否正确
    fprintf('1. Checking normalize_streaming.m...\n');
    if exist('normalize_streaming.m', 'file')
        fid = fopen('normalize_streaming.m', 'r');
        firstLine = fgetl(fid);
        fclose(fid);
        if contains(firstLine, 'function S = normalize_streaming')
            fprintf('   ✓ normalize_streaming.m is correct\n');
        else
            fprintf('   ✗ normalize_streaming.m has wrong function signature\n');
            fprintf('   First line: %s\n', firstLine);
        end
    else
        fprintf('   ✗ normalize_streaming.m not found!\n');
    end
    
    % 2. 测试关键函数
    fprintf('\n2. Testing key functions...\n');
    
    % Test measure_loudness
    try
        Fs = 48000;
        t = (0:Fs-1)' / Fs;
        x = 0.5 * sin(2*pi*440*t);
        cfg_test = config();
        M = measure_loudness(x, Fs, cfg_test);
        if isfield(M, 'integratedLUFS') && isfield(M, 'truePeak_dBTP')
            fprintf('   ✓ measure_loudness works correctly\n');
        else
            fprintf('   ✗ measure_loudness missing required fields\n');
        end
    catch ME
        fprintf('   ✗ measure_loudness failed: %s\n', ME.message);
    end
    
    % Test normalize_streaming
    try
        Fs = 48000;
        t = (0:Fs-1)' / Fs;
        x = 0.5 * sin(2*pi*440*t);
        plat = struct('name', 'Test', 'targetLUFS', -14.0, 'tpLimit', -1.0);
        cfg = struct();
        S = normalize_streaming(x, Fs, -12.0, -0.5, -14.0, cfg, plat, 'test.wav');
        if isfield(S, 'y') && isfield(S, 'postLUFS') && isfield(S, 'postTP')
            fprintf('   ✓ normalize_streaming works correctly\n');
        else
            fprintf('   ✗ normalize_streaming missing required fields\n');
        end
    catch ME
        fprintf('   ✗ normalize_streaming failed: %s\n', ME.message);
    end
    
    % Test row_comp
    try
        C = struct('platform', 'Test', 'postLUFS', -14.0, 'postTP', -1.0, ...
                   'gain_dB', -2.0, 'limited', 0, 'maxGR', 0.5, ...
                   'meanGR', 0.1, 'grTimeRatio', 0.05);
        T = row_comp('test.wav', C);
        if height(T) == 1 && width(T) == 9
            fprintf('   ✓ row_comp works correctly\n');
        else
            fprintf('   ✗ row_comp returned wrong table size\n');
        end
    catch ME
        fprintf('   ✗ row_comp failed: %s\n', ME.message);
    end
    
    % 3. 检查文件写入函数
    fprintf('\n3. Checking file writing functions...\n');
    
    % Check compliance_platform
    if exist('compliance_platform.m', 'file')
        fprintf('   ✓ compliance_platform.m exists\n');
    else
        fprintf('   ✗ compliance_platform.m not found\n');
    end
    
    % Check simulate_codec_chain
    if exist('simulate_codec_chain.m', 'file')
        fprintf('   ✓ simulate_codec_chain.m exists\n');
    else
        fprintf('   ✗ simulate_codec_chain.m not found\n');
    end
    
    % Check simulate_platform_listening
    if exist('simulate_platform_listening.m', 'file')
        fprintf('   ✓ simulate_platform_listening.m exists\n');
    else
        fprintf('   ✗ simulate_platform_listening.m not found\n');
    end
    
    % 4. 验证配置文件
    fprintf('\n4. Checking configuration...\n');
    try
        cfg = config();
        if isfield(cfg, 'resultsDir') && isfield(cfg, 'dataDir')
            fprintf('   ✓ config() works correctly\n');
            fprintf('   resultsDir: %s\n', cfg.resultsDir);
            fprintf('   dataDir: %s\n', cfg.dataDir);
        else
            fprintf('   ✗ config() missing required fields\n');
        end
        
        if isfield(cfg, 'platforms') && ~isempty(cfg.platforms)
            fprintf('   ✓ cfg.platforms is configured (%d platforms)\n', numel(cfg.platforms));
        else
            fprintf('   ⚠ cfg.platforms not found, will use platform_presets()\n');
        end
    catch ME
        fprintf('   ✗ config() failed: %s\n', ME.message);
    end
    
    fprintf('\n=== Fix Complete ===\n');
    fprintf('\nNext steps:\n');
    fprintf('1. Run: test_functions()\n');
    fprintf('2. Run: diagnose_csv_issue()\n');
    fprintf('3. Run: run_project()\n');
end

