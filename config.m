function cfg = config()
% ========================================================
% Global config for ELEC5305 project
% ========================================================
% Automatically detects project root directory based on this file's location
% Supports both absolute and relative paths

    % ====== Auto-detect project root path ======
    % Get the directory where this config.m file is located
    thisFile = mfilename('fullpath');
    thisDir = fileparts(thisFile);
    
    % Project root is the parent of 'matlab' directory
    % Structure: project_root/matlab/config.m
    % Check if current directory ends with 'matlab' (case-insensitive)
    [~, dirName, ~] = fileparts(thisDir);
    if strcmpi(dirName, 'matlab')
        root = fileparts(thisDir);
    else
        % Fallback: check if path contains 'matlab'
        if ~isempty(strfind(lower(thisDir), [filesep, 'matlab', filesep])) || ...
           ~isempty(strfind(lower(thisDir), [filesep, 'matlab']))
            root = fileparts(thisDir);
        else
            % Assume current directory is project root
            root = thisDir;
        end
    end
    
    % Normalize path (handle both / and \)
    root = fullfile(root);

    % ====== File paths ======
    cfg.rootDir    = root;
    cfg.dataDir    = fullfile(root, 'data', 'wav');
    cfg.resultsDir = fullfile(root, 'results');
    cfg.figDir     = fullfile(root, 'figures');
    cfg.htmlDir    = fullfile(root, 'html');
    
    % Also support matlab subdirectory structure
    cfg.matlabDir  = fullfile(root, 'matlab');

    if ~exist(cfg.resultsDir,'dir'), mkdir(cfg.resultsDir); end
    if ~exist(cfg.figDir,'dir'),    mkdir(cfg.figDir);    end
    if ~exist(cfg.htmlDir,'dir'),   mkdir(cfg.htmlDir);   end

    % ====== Platforms (must use platform_presets) ======
    cfg.platforms = [
        platform_presets("AppleMusic")
        platform_presets("Spotify")
        platform_presets("YouTube")
        platform_presets("TikTok")
    ];

    % ====== Basic processing parameters (used by normalize_streaming) ======
    cfg.tpMargin           = 1.0;   % True-peak safety margin (dB)
    cfg.truePeakOversample = 4;     % True-peak oversampling factor (4x recommended by EBU)
    cfg.tpCeil             = -1.0;  % True-peak ceiling (dBTP) - EBU R128 standard
    cfg.streamTargetLUFS  = -14.0;  % Default streaming loudness target (dB LUFS) - Spotify/YouTube standard
    
    % ====== Loudness measurement parameters (used by measure_loudness) ======
    cfg.loudnessBlockMs    = 400;   % Block size for loudness calculation (ms) - EBU R128 standard
    cfg.loudnessHopMs      = 100;   % Hop size for loudness calculation (ms) - EBU R128 standard
    cfg.shortTermSeconds   = 3.0;   % Short-term loudness window (seconds)
    
    % ====== VAD parameters (used by dialogue_VAD) ======
    cfg.vadFrameMs         = 10;    % VAD frame size (ms) - optimal for speech detection
    cfg.vadSmoothingSec    = 3.0;   % Temporal smoothing window (seconds)
    
    % ====== Limiter parameters (used by adaptive_normalizer) ======
    cfg.limiterAttackMs    = 3.0;   % Limiter attack time (ms) - fast enough to catch peaks
    cfg.limiterReleaseMs   = 50.0;  % Limiter release time (ms) - smooth recovery
    
    % ====== File I/O parameters ======
    cfg.fileWriteRetryDelay = 0.15; % Delay between file write retries (seconds)
    cfg.fileWriteMaxRetries = 5;    % Maximum retries for file operations

    % ====== Project control ======
    cfg.doOverwrite        = true;

    % ====== HTML report ======
    cfg.enableHTMLFigures = true;
    cfg.reportTitle = 'ELEC5305 Loudness & True-Peak Report';

end
