function test_functions()
% TEST_FUNCTIONS
% 测试 measure_loudness, simulate_platform (apply_platform_playback), row_comp

    fprintf('=== Testing Functions ===\n\n');
    
    % 1. 测试 measure_loudness 输出结构
    fprintf('1. Testing measure_loudness output structure:\n');
    try
        % Create test audio
        Fs = 48000;
        t = (0:Fs-1)' / Fs;
        x = 0.5 * sin(2*pi*440*t);  % 440 Hz tone
        
        cfg_test = config();
        M = measure_loudness(x, Fs, cfg_test);
        fprintf('   SUCCESS: measure_loudness returned struct\n');
        fprintf('   Fields:\n');
        fields = fieldnames(M);
        for k = 1:numel(fields)
            val = M.(fields{k});
            if isnumeric(val) && isscalar(val)
                fprintf('     %s = %.4f\n', fields{k}, val);
            else
                fprintf('     %s = %s\n', fields{k}, class(val));
            end
        end
        
        % 检查必需字段
        required = {'integratedLUFS', 'truePeak_dBTP'};
        missing = setdiff(required, fields);
        if ~isempty(missing)
            fprintf('   WARNING: Missing fields: %s\n', strjoin(missing, ', '));
        else
            fprintf('   ✓ All required fields present\n');
        end
        
    catch ME
        fprintf('   ERROR: %s\n', ME.message);
    end
    
    % 2. 测试 apply_platform_playback (simulate_platform) 返回值
    fprintf('\n2. Testing apply_platform_playback (simulate_platform) return:\n');
    try
        Fs = 48000;
        t = (0:Fs-1)' / Fs;
        x = 0.5 * sin(2*pi*440*t);
        
        % 创建测试平台
        plat = struct();
        plat.name = 'TestPlatform';
        plat.targetLUFS = -14.0;
        plat.tpLimit = -1.0;
        
        trackLUFS = -12.0;  % 比目标响
        trackTP = -0.5;
        
        cfg = struct();
        [y, meta] = apply_platform_playback(x, Fs, trackLUFS, trackTP, plat, cfg);
        
        fprintf('   SUCCESS: apply_platform_playback returned [y, meta]\n');
        fprintf('   y size: %s\n', mat2str(size(y)));
        fprintf('   meta fields:\n');
        if isstruct(meta)
            metaFields = fieldnames(meta);
            for k = 1:numel(metaFields)
                val = meta.(metaFields{k});
                if isnumeric(val) && isscalar(val)
                    fprintf('     %s = %.4f\n', metaFields{k}, val);
                else
                    fprintf('     %s = %s\n', metaFields{k}, class(val));
                end
            end
            
            % 检查必需字段
            requiredMeta = {'postLUFS', 'postTP', 'gain_dB'};
            missingMeta = setdiff(requiredMeta, metaFields);
            if ~isempty(missingMeta)
                fprintf('   WARNING: Missing meta fields: %s\n', strjoin(missingMeta, ', '));
            else
                fprintf('   ✓ All required meta fields present\n');
            end
        else
            fprintf('   ERROR: meta is not a struct!\n');
        end
        
    catch ME
        fprintf('   ERROR: %s\n', ME.message);
        fprintf('   Stack:\n');
        for k = 1:min(3, numel(ME.stack))
            fprintf('     %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
        end
    end
    
    % 3. 测试 row_comp
    fprintf('\n3. Testing row_comp:\n');
    try
        % 创建测试结构
        C = struct();
        C.platform = 'TestPlatform';
        C.postLUFS = -14.0;
        C.postTP = -1.0;
        C.gain_dB = -2.0;
        C.limited = 0;
        C.maxGR = 0.5;
        C.meanGR = 0.1;
        C.grTimeRatio = 0.05;
        
        T = row_comp('test.wav', C);
        
        fprintf('   SUCCESS: row_comp returned table\n');
        fprintf('   Table size: %d rows, %d columns\n', height(T), width(T));
        fprintf('   Columns: %s\n', strjoin(T.Properties.VariableNames, ', '));
        if height(T) > 0
            fprintf('   First row:\n');
            for k = 1:width(T)
                colName = T.Properties.VariableNames{k};
                val = T{1, colName};
                if isstring(val) || ischar(val)
                    fprintf('     %s = %s\n', colName, string(val));
                else
                    fprintf('     %s = %.4f\n', colName, double(val));
                end
            end
        end
        
    catch ME
        fprintf('   ERROR: %s\n', ME.message);
        fprintf('   Stack:\n');
        for k = 1:min(3, numel(ME.stack))
            fprintf('     %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
        end
    end
    
    % 4. 测试 normalize_streaming
    fprintf('\n4. Testing normalize_streaming function:\n');
    try
        Fs = 48000;
        t = (0:Fs-1)' / Fs;
        x = 0.5 * sin(2*pi*440*t);
        
        preLUFS = -12.0;
        preTP = -0.5;
        targetLUFS = -14.0;
        
        plat = struct();
        plat.name = 'TestPlatform';
        plat.targetLUFS = targetLUFS;
        plat.tpLimit = -1.0;
        
        cfg = struct();
        S = normalize_streaming(x, Fs, preLUFS, preTP, targetLUFS, cfg, plat, 'test.wav');
        
        fprintf('   SUCCESS: normalize_streaming returned struct\n');
        fprintf('   S fields:\n');
        fields = fieldnames(S);
        for k = 1:numel(fields)
            val = S.(fields{k});
            if isnumeric(val) && isscalar(val)
                fprintf('     %s = %.4f\n', fields{k}, val);
            elseif isvector(val)
                fprintf('     %s = vector [%d elements]\n', fields{k}, numel(val));
            else
                fprintf('     %s = %s\n', fields{k}, class(val));
            end
        end
        
        % 检查必需字段
        requiredS = {'y', 'postLUFS', 'postTP'};
        missingS = setdiff(requiredS, fields);
        if ~isempty(missingS)
            fprintf('   WARNING: Missing fields: %s\n', strjoin(missingS, ', '));
        else
            fprintf('   ✓ All required fields present\n');
        end
        
    catch ME
        fprintf('   ERROR: %s\n', ME.message);
        fprintf('   Stack:\n');
        for k = 1:min(3, numel(ME.stack))
            fprintf('     %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
        end
    end
    
    % 5. 测试 row_comp 与 apply_platform_playback 的兼容性
    fprintf('\n5. Testing row_comp with apply_platform_playback output:\n');
    try
        Fs = 48000;
        t = (0:Fs-1)' / Fs;
        x = 0.5 * sin(2*pi*440*t);
        
        plat = struct();
        plat.name = 'TestPlatform';
        plat.targetLUFS = -14.0;
        plat.tpLimit = -1.0;
        
        trackLUFS = -12.0;
        trackTP = -0.5;
        cfg = struct();
        
        [y, meta] = apply_platform_playback(x, Fs, trackLUFS, trackTP, plat, cfg);
        
        % 构造 row_comp 需要的结构
        C = struct();
        C.platform = plat.name;
        C.postLUFS = meta.postLUFS;
        C.postTP = meta.postTP;
        C.gain_dB = meta.playbackGain_dB;
        C.limited = double(meta.postTP > plat.tpLimit);
        C.maxGR = meta.maxGR;
        C.meanGR = meta.meanGR;
        C.grTimeRatio = meta.grTimeRatio;
        
        T = row_comp('test.wav', C);
        
        fprintf('   SUCCESS: row_comp works with apply_platform_playback output\n');
        fprintf('   Generated table: %d rows\n', height(T));
        
    catch ME
        fprintf('   ERROR: %s\n', ME.message);
    end
    
    fprintf('\n=== Test Complete ===\n');
end

