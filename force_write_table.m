function success = force_write_table(T, filepath, varargin)
% FORCE_WRITE_TABLE
% 强制写入表格到CSV文件，处理只读、锁定等问题
%
% Usage:
%   success = force_write_table(T, filepath)
%   success = force_write_table(T, filepath, 'WriteMode', 'overwrite')
%
% This function uses multiple strategies to ensure file writing succeeds:
%   1. Delete existing file (multiple attempts)
%   2. Remove read-only attribute (Windows)
%   3. Write to temporary file then rename
%   4. Direct write as last resort

    success = false;
    
    if nargin < 2
        error('force_write_table: Need at least 2 arguments');
    end
    
    % Parse optional arguments
    p = inputParser;
    addParameter(p, 'WriteMode', 'overwrite', @ischar);
    parse(p, varargin{:});
    writeMode = p.Results.WriteMode;
    
    % Ensure directory exists
    [outDir, ~, ~] = fileparts(filepath);
    if ~isempty(outDir) && ~exist(outDir, 'dir')
        try
            mkdir(outDir);
        catch ME
            warning('force_write_table: Cannot create directory %s: %s', outDir, ME.message);
            return;
        end
    end
    
    % Strategy 1: Try to delete existing file (multiple attempts)
    if exist(filepath, 'file')
        deleted = false;
        maxAttempts = 5;
        
        for attempt = 1:maxAttempts
            try
                % Try to delete
                delete(filepath);
                % Wait for filesystem to update (optimized: 0.15s for first attempt)
                pause(0.15);
                if ~exist(filepath, 'file')
                    deleted = true;
                    break;
                end
            catch
                % Try to remove read-only attribute (Windows)
                if ispc
                    try
                        [status, ~] = system(sprintf('attrib -r "%s"', filepath));
                        if status == 0
                            pause(0.15);  % Wait after attrib change
                            try
                                delete(filepath);
                                pause(0.15);
                                if ~exist(filepath, 'file')
                                    deleted = true;
                                    break;
                                end
                            catch
                            end
                        end
                    catch
                    end
                end
                
                % Try to rename and delete
                if attempt < maxAttempts
                    try
                        oldFile = [filepath '.old' num2str(attempt)];
                        if exist(oldFile, 'file')
                            delete(oldFile);
                        end
                        movefile(filepath, oldFile);
                        pause(0.15);
                        delete(oldFile);
                        deleted = true;
                        break;
                    catch
                    end
                end
            end
            
            % Wait before next attempt (exponential backoff: 0.2, 0.3, 0.4, 0.5s)
            if attempt < maxAttempts
                pause(0.1 + 0.1 * attempt);
            end
        end
        
        if ~deleted && exist(filepath, 'file')
            warning('force_write_table: Could not delete existing file %s, will try to overwrite', filepath);
        end
    end
    
    % Strategy 2: Write to temporary file, then rename
    [outDir, outName, outExt] = fileparts(filepath);
    if isempty(outDir)
        outDir = pwd;
    end
    
    % Generate unique temporary filename
    tempFile = fullfile(outDir, [outName '_temp_' datestr(now, 'HHMMSS') '_' num2str(randi(1000)) outExt]);
    tempFileWritten = false;
    
    try
        % Write to temporary file
        writetable(T, tempFile, 'WriteMode', 'overwrite');
        tempFileWritten = true;
        
        % Wait for file system to flush (optimized: 0.2s)
        pause(0.2);
        
        % Verify temporary file was written (with retry)
        for verifyAttempt = 1:3
            if exist(tempFile, 'file')
                break;
            end
            if verifyAttempt < 3
                pause(0.1);
            else
                error('Temporary file was not created after %d attempts', verifyAttempt);
            end
        end
        
        % Check if temporary file has content (with retry)
        for checkAttempt = 1:3
            info = dir(tempFile);
            if ~isempty(info) && info.bytes > 0
                break;  % File has content
            end
            if checkAttempt < 3
                pause(0.1);
            else
                error('Temporary file is empty after %d checks', checkAttempt);
            end
        end
        
        % Now try to replace the original file
        if exist(filepath, 'file')
            % Try to delete original one more time (aggressive)
            for delAttempt = 1:2
                try
                    if ispc
                        system(sprintf('attrib -r "%s"', filepath));
                    end
                    delete(filepath);
                    pause(0.15);
                    if ~exist(filepath, 'file')
                        break;  % Successfully deleted
                    end
                catch
                    if delAttempt == 2 && ispc
                        % Last resort: force delete
                        try
                            system(sprintf('del /f /q "%s"', filepath));
                            pause(0.15);
                        catch
                        end
                    end
                end
            end
        end
        
        % Move temporary file to final location
        try
            movefile(tempFile, filepath);
            pause(0.2);  % Wait for move to complete
            success = true;
        catch ME_move
            % If move fails, try copy and delete
            try
                copyfile(tempFile, filepath);
                pause(0.2);
                delete(tempFile);
                success = true;
            catch
                error('Cannot move or copy temporary file: %s', ME_move.message);
            end
        end
        
    catch ME
        % Clean up temporary file
        if tempFileWritten && exist(tempFile, 'file')
            try
                delete(tempFile);
            catch
            end
        end
        
        % Strategy 3: Last resort - direct write
        try
            if ispc && exist(filepath, 'file')
                system(sprintf('attrib -r "%s"', filepath));
                pause(0.15);
            end
            
            writetable(T, filepath, 'WriteMode', writeMode);
            pause(0.2);  % Wait for write to complete
            success = true;
            
        catch ME2
            error('force_write_table: All write strategies failed.\n  Strategy 2 error: %s\n  Strategy 3 error: %s\n  File: %s\n  Please close the file if it is open in Excel or another program.', ...
                ME.message, ME2.message, filepath);
        end
    end
    
    % Final verification (with retry for file system delay)
    if success && exist(filepath, 'file')
        pause(0.15);  % Wait for file system to update
        for verifyAttempt = 1:3
            info = dir(filepath);
            if ~isempty(info) && info.bytes > 0
                % File has content, verify we can read it
                try
                    T_verify = readtable(filepath);
                    if height(T_verify) ~= height(T)
                        warning('force_write_table: File row count mismatch (expected %d, got %d)', ...
                            height(T), height(T_verify));
                    end
                catch ME_verify
                    warning('force_write_table: Cannot verify file content: %s', ME_verify.message);
                end
                break;  % Success
            end
            if verifyAttempt < 3
                pause(0.1);
            else
                warning('force_write_table: File was created but is empty after %d checks!', verifyAttempt);
                success = false;
            end
        end
        
        % Final check: ensure file is not read-only
        if ispc && success
            try
                [status, result] = system(sprintf('attrib "%s"', filepath));
                if contains(result, 'R')
                    % File is read-only, try to remove it
                    system(sprintf('attrib -r "%s"', filepath));
                end
            catch
                % Ignore attrib errors
            end
        end
    elseif success && ~exist(filepath, 'file')
        warning('force_write_table: Write reported success but file does not exist!');
        success = false;
    end
end

