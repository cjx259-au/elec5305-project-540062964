function make_dashboard_tables(cfg)
% MAKE_DASHBOARD_TABLES
% ---------------------------------------------------------
% Summarize compliance.csv by platform:
%   num_items, num_limited, limited_rate, mean_postLUFS, mean_postTP
% Write results/summary_platform.csv
% ---------------------------------------------------------

    if nargin < 1 || isempty(cfg)
        cfg = config();
    end

    resultsDir = cfg.resultsDir;
    % Prefer compliance_platform.csv, fallback to compliance.csv if not found
    inCsv1 = fullfile(resultsDir, 'compliance_platform.csv');
    inCsv2 = fullfile(resultsDir, 'compliance.csv');
    
    if isfile(inCsv1)
        inCsv = inCsv1;
    elseif isfile(inCsv2)
        inCsv = inCsv2;
        warning('Using compliance.csv instead of compliance_platform.csv');
    else
        error('make_dashboard_tables: Neither compliance_platform.csv nor compliance.csv found in %s', resultsDir);
    end
    
    outCsv = fullfile(resultsDir, 'summary_platform.csv');

    Tc = readtable(inCsv);

    % Ensure required columns exist
    requiredCols = {'platform','postLUFS','postTP','limited'};
    for i = 1:numel(requiredCols)
        if ~ismember(requiredCols{i}, Tc.Properties.VariableNames)
            error('make_dashboard_tables: column "%s" missing in compliance.csv', ...
                  requiredCols{i});
        end
    end

    plat = string(Tc.platform);
    uplat = unique(plat, 'stable');
    K = numel(uplat);

    platform      = strings(K,1);
    num_items     = zeros(K,1);
    num_limited   = zeros(K,1);
    limited_rate  = zeros(K,1);
    mean_postLUFS = NaN(K,1);
    mean_postTP   = NaN(K,1);

    for k = 1:K
        mask = (plat == uplat(k));
        platform(k)  = uplat(k);
        num_items(k) = sum(mask);
        if num_items(k) == 0
            continue;
        end

        L = Tc.limited(mask);
        if islogical(L), L = double(L); end
        num_limited(k)  = sum(L ~= 0);
        limited_rate(k) = num_limited(k) / num_items(k);

        mean_postLUFS(k) = mean(Tc.postLUFS(mask), 'omitnan');
        mean_postTP(k)   = mean(Tc.postTP(mask),   'omitnan');
    end

    Sout = table(platform, num_items, num_limited, limited_rate, ...
                 mean_postLUFS, mean_postTP);

    % Use force write function
    try
        success = force_write_table(Sout, outCsv, 'WriteMode', 'overwrite');
        if success
            fprintf('[make_dashboard_tables] Wrote %s\n', outCsv);
        else
            error('force_write_table returned false');
        end
    catch ME
        error('make_dashboard_tables: Failed to write CSV: %s\n  File: %s\n  Please close the file if it is open in Excel or another program.', ...
            ME.message, outCsv);
    end
end
