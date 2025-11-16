function tf = isFFmpegAvailable()
% ISFFMPEGAVAILABLE
% Check if FFmpeg is available in the system PATH
%
% Returns:
%   tf - true if FFmpeg is available, false otherwise

    persistent cached_result;
    persistent cached_check;
    
    % Cache the result to avoid repeated system calls
    if ~isempty(cached_check)
        tf = cached_result;
        return;
    end
    
    try
        % Try to run ffmpeg -version
        % Suppress output to avoid cluttering console
        if ispc
            [status, ~] = system('ffmpeg -version >nul 2>&1');
        else
            [status, ~] = system('ffmpeg -version >/dev/null 2>&1');
        end
        tf = (status == 0);
    catch
        tf = false;
    end
    
    % Cache the result
    cached_result = tf;
    cached_check = true;
end

