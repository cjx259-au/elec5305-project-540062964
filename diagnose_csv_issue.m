function diagnose_csv_issue()
% DIAGNOSE_CSV_ISSUE
% 诊断 compliance_platform.csv 为空或只读的问题

    fprintf('=== CSV File Diagnosis ===\n\n');
    
    cfg = config();
    resultsDir = cfg.resultsDir;
    outCsv = fullfile(resultsDir, 'compliance_platform.csv');
    
    % 1. 检查目录
    fprintf('1. Directory check:\n');
    fprintf('   resultsDir: %s\n', resultsDir);
    fprintf('   exists: %d\n', exist(resultsDir, 'dir'));
    if ~exist(resultsDir, 'dir')
        fprintf('   -> Creating directory...\n');
        mkdir(resultsDir);
    end
    
    % 2. 检查 metrics.csv
    fprintf('\n2. metrics.csv check:\n');
    metricsCsv = fullfile(resultsDir, 'metrics.csv');
    fprintf('   path: %s\n', metricsCsv);
    fprintf('   exists: %d\n', exist(metricsCsv, 'file'));
    if exist(metricsCsv, 'file')
        try
            T = readtable(metricsCsv);
            fprintf('   rows: %d\n', height(T));
            fprintf('   columns: %s\n', strjoin(T.Properties.VariableNames, ', '));
            if height(T) > 0
                fprintf('   first file: %s\n', string(T.file(1)));
                fprintf('   first integratedLUFS: %.2f\n', T.integratedLUFS(1));
            end
        catch ME
            fprintf('   ERROR reading: %s\n', ME.message);
        end
    else
        fprintf('   -> metrics.csv not found!\n');
    end
    
    % 3. 检查平台配置
    fprintf('\n3. Platform configuration:\n');
    if isfield(cfg, 'platforms')
        fprintf('   cfg.platforms exists: yes\n');
        fprintf('   count: %d\n', numel(cfg.platforms));
        for p = 1:min(4, numel(cfg.platforms))
            if isstruct(cfg.platforms) && isfield(cfg.platforms, 'name')
                fprintf('   Platform %d: %s\n', p, string(cfg.platforms(p).name));
            end
        end
    else
        fprintf('   cfg.platforms exists: no\n');
        plats = platform_presets();
        fprintf('   platform_presets() count: %d\n', numel(plats));
    end
    
    % 4. 检查输出文件
    fprintf('\n4. Output file check:\n');
    fprintf('   path: %s\n', outCsv);
    fprintf('   exists: %d\n', exist(outCsv, 'file'));
    if exist(outCsv, 'file')
        info = dir(outCsv);
        fprintf('   size: %d bytes\n', info.bytes);
        
        % 检查只读属性
        if ispc
            [status, result] = system(sprintf('attrib "%s"', outCsv));
            fprintf('   attributes: %s', result);
            if contains(result, 'R')
                fprintf('   -> FILE IS READ-ONLY!\n');
                fprintf('   Attempting to remove read-only...\n');
                system(sprintf('attrib -r "%s"', outCsv));
                pause(0.1);
            end
        end
        
        % 尝试读取
        try
            T = readtable(outCsv);
            fprintf('   rows in file: %d\n', height(T));
            if height(T) == 0
                fprintf('   -> FILE IS EMPTY!\n');
            end
        catch ME
            fprintf('   ERROR reading: %s\n', ME.message);
        end
    end
    
    % 5. 测试写入权限
    fprintf('\n5. Write permission test:\n');
    testFile = fullfile(resultsDir, 'test_write.csv');
    try
        testTable = table(string({'test'}), [1], 'VariableNames', {'col1', 'col2'});
        writetable(testTable, testFile);
        fprintf('   -> Write test: SUCCESS\n');
        delete(testFile);
    catch ME
        fprintf('   -> Write test: FAILED - %s\n', ME.message);
    end
    
    % 6. 运行 compliance_platform
    fprintf('\n6. Running compliance_platform():\n');
    try
        compliance_platform(cfg);
        fprintf('   -> Function completed\n');
        
        % 再次检查文件
        if exist(outCsv, 'file')
            info = dir(outCsv);
            fprintf('   Final file size: %d bytes\n', info.bytes);
            try
                T = readtable(outCsv);
                fprintf('   Final rows: %d\n', height(T));
            catch
                fprintf('   -> Cannot read final file\n');
            end
        else
            fprintf('   -> File still does not exist!\n');
        end
    catch ME
        fprintf('   -> Function FAILED: %s\n', ME.message);
        fprintf('   Stack trace:\n');
        for k = 1:numel(ME.stack)
            fprintf('     %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
        end
    end
    
    fprintf('\n=== Diagnosis Complete ===\n');
end

