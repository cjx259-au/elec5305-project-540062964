function verify_connections()
% VERIFY_CONNECTIONS
% 验证所有模块之间的连接是否正确

    fprintf('=== Verifying Module Connections ===\n\n');
    
    % 1. 检查配置文件
    fprintf('1. Checking config...\n');
    try
        cfg = config();
        fprintf('   ✓ config() works\n');
        fprintf('   - resultsDir: %s\n', cfg.resultsDir);
        fprintf('   - dataDir: %s\n', cfg.dataDir);
        fprintf('   - platforms: %d\n', numel(cfg.platforms));
    catch ME
        fprintf('   ✗ config() failed: %s\n', ME.message);
        return;
    end
    
    % 2. 检查核心函数
    fprintf('\n2. Checking core functions...\n');
    coreFunctions = {
        'measure_loudness', ...
        'dialogue_metrics', ...
        'dialogue_VAD', ...
        'row_metrics', ...
        'compliance_platform', ...
        'make_dashboard_tables', ...
        'normalize_streaming', ...
        'force_write_table'
    };
    
    for i = 1:numel(coreFunctions)
        funcName = coreFunctions{i};
        if exist(funcName, 'file')
            fprintf('   ✓ %s exists\n', funcName);
        else
            fprintf('   ✗ %s NOT FOUND\n', funcName);
        end
    end
    
    % 3. 检查可选函数
    fprintf('\n3. Checking optional functions...\n');
    optionalFunctions = {
        'adaptive_mastering_profiles', ...
        'simulate_codec_chain', ...
        'simulate_platform_listening', ...
        'analyze_codec_distortion', ...
        'analyze_truepeak_sensitivity', ...
        'export_html_report', ...
        'compliance_report', ...
        'summarize_for_writeup', ...
        'plot_helpers'
    };
    
    for i = 1:numel(optionalFunctions)
        funcName = optionalFunctions{i};
        if exist(funcName, 'file')
            fprintf('   ✓ %s exists\n', funcName);
        else
            fprintf('   ⚠ %s not found (optional)\n', funcName);
        end
    end
    
    % 4. 测试函数调用链
    fprintf('\n4. Testing function call chain...\n');
    try
        % 创建测试音频
        Fs = 48000;
        t = (0:Fs-1)' / Fs;
        x = 0.5 * sin(2*pi*440*t);
        
        % Test measure_loudness
        M = measure_loudness(x, Fs, cfg);
        fprintf('   ✓ measure_loudness(x, Fs, cfg) works\n');
        
        % Test dialogue_metrics
        D = dialogue_metrics(x, Fs, cfg);
        fprintf('   ✓ dialogue_metrics(x, Fs, cfg) works\n');
        
        % Test row_metrics
        T = row_metrics('test.wav', M, M.truePeak_dBTP);
        fprintf('   ✓ row_metrics works\n');
        
        % Test normalize_streaming
        plat = cfg.platforms(1);
        S = normalize_streaming(x, Fs, M.integratedLUFS, M.truePeak_dBTP, ...
                                plat.targetLUFS, cfg, plat, 'test.wav');
        fprintf('   ✓ normalize_streaming works\n');
        
    catch ME
        fprintf('   ✗ Function chain test failed: %s\n', ME.message);
        fprintf('   Stack: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    end
    
    % 5. 检查数据流
    fprintf('\n5. Checking data flow...\n');
    dataFiles = {
        'metrics.csv', ...
        'compliance_platform.csv', ...
        'summary_platform.csv'
    };
    
    for i = 1:numel(dataFiles)
        filePath = fullfile(cfg.resultsDir, dataFiles{i});
        if exist(filePath, 'file')
            try
                T = readtable(filePath);
                fprintf('   ✓ %s exists (%d rows)\n', dataFiles{i}, height(T));
            catch ME
                fprintf('   ⚠ %s exists but cannot read: %s\n', dataFiles{i}, ME.message);
            end
        else
            fprintf('   ⚠ %s not found (will be created by pipeline)\n', dataFiles{i});
        end
    end
    
    fprintf('\n=== Verification Complete ===\n');
    fprintf('\nTo run the complete pipeline:\n');
    fprintf('  >> run_project()\n');
    fprintf('  or\n');
    fprintf('  >> run_all_experiments()\n');
end

