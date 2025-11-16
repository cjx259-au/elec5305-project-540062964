function test_force_write()
% TEST_FORCE_WRITE
% 测试 force_write_table 函数是否能正确处理只读文件

    fprintf('=== Testing force_write_table ===\n\n');
    
    cfg = config();
    testDir = cfg.resultsDir;
    testFile = fullfile(testDir, 'test_force_write.csv');
    
    % 创建测试表格
    T = table(string({'test1'; 'test2'}), [1; 2], [3; 4], ...
              'VariableNames', {'name', 'val1', 'val2'});
    
    fprintf('1. Creating test file: %s\n', testFile);
    
    % 测试1: 正常写入
    try
        success = force_write_table(T, testFile, 'WriteMode', 'overwrite');
        if success
            fprintf('   ✓ Normal write: SUCCESS\n');
        else
            fprintf('   ✗ Normal write: FAILED (returned false)\n');
        end
    catch ME
        fprintf('   ✗ Normal write: FAILED - %s\n', ME.message);
    end
    
    % 测试2: 设置为只读后写入
    if exist(testFile, 'file')
        fprintf('\n2. Testing write to read-only file:\n');
        try
            if ispc
                system(sprintf('attrib +r "%s"', testFile));
                fprintf('   Set file to read-only\n');
            end
            
            success = force_write_table(T, testFile, 'WriteMode', 'overwrite');
            if success
                fprintf('   ✓ Read-only write: SUCCESS\n');
            else
                fprintf('   ✗ Read-only write: FAILED (returned false)\n');
            end
        catch ME
            fprintf('   ✗ Read-only write: FAILED - %s\n', ME.message);
        end
    end
    
    % 测试3: 验证文件内容
    fprintf('\n3. Verifying file content:\n');
    if exist(testFile, 'file')
        try
            T_read = readtable(testFile);
            if height(T_read) == 2 && width(T_read) == 3
                fprintf('   ✓ File content: CORRECT (%d rows, %d cols)\n', height(T_read), width(T_read));
            else
                fprintf('   ✗ File content: INCORRECT (%d rows, %d cols)\n', height(T_read), width(T_read));
            end
            
            info = dir(testFile);
            if info.bytes > 0
                fprintf('   ✓ File size: %d bytes (not empty)\n', info.bytes);
            else
                fprintf('   ✗ File size: 0 bytes (EMPTY!)\n');
            end
        catch ME
            fprintf('   ✗ Cannot read file: %s\n', ME.message);
        end
    else
        fprintf('   ✗ File does not exist!\n');
    end
    
    % 清理
    if exist(testFile, 'file')
        try
            if ispc
                system(sprintf('attrib -r "%s"', testFile));
            end
            delete(testFile);
            fprintf('\n4. Cleanup: Test file deleted\n');
        catch
            fprintf('\n4. Cleanup: Could not delete test file\n');
        end
    end
    
    fprintf('\n=== Test Complete ===\n');
end

