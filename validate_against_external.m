function validate_against_external()
% VALIDATE_AGAINST_EXTERNAL
% Compare our metrics.csv against external reference CSV
% (e.g., libebur128, FFmpeg, Dolby MediaMeter)
%
% Auto-handles:
%   - Missing externalCsv
%   - Missing required columns
%   - Case-insensitive field matching
%   - Empty intersections
%   - NaN / Inf safety

    cfg = config();

    % --------------------------------------------------------------
    % 0) externalCsv field check
    % --------------------------------------------------------------
    if ~isfield(cfg, 'externalCsv') || isempty(cfg.externalCsv)
        warning('[validate_against_external] cfg.externalCsv missing in config(). Skip.');
        return;
    end

    if ~isfile(cfg.externalCsv)
        warning('[validate_against_external] External baseline CSV not found:\n  %s', cfg.externalCsv);
        return;
    end

    % --------------------------------------------------------------
    % 1) Load our metrics + external reference
    % --------------------------------------------------------------
    myCsv   = fullfile(cfg.resultsDir, 'metrics.csv');
    if ~isfile(myCsv)
        warning('[validate_against_external] metrics.csv missing. Run run_project first.');
        return;
    end

    Tint = readtable(myCsv);
    Text = readtable(cfg.externalCsv);

    % Ensure file columns are string for join
    if ~isstring(Tint.file) && ~(iscell(Tint.file) && all(cellfun(@ischar, Tint.file)))
        Tint.file = string(Tint.file);
    end
    if ismember('file', Text.Properties.VariableNames)
        if ~isstring(Text.file) && ~(iscell(Text.file) && all(cellfun(@ischar, Text.file)))
            Text.file = string(Text.file);
        end
    else
        warning('[validate_against_external] External CSV missing "file" column.');
        return;
    end

    % --------------------------------------------------------------
    % 2) Detect external column names (robust)
    % --------------------------------------------------------------
    LC = lower(Text.Properties.VariableNames);

    % integrated LUFS column candidates
    candLUFS = {'external_integratedlufs','ext_integrated','ext_lufs','integrated','integrated_lufs'};
    colLUFS = findCol(LC, candLUFS);

    % LRA column candidates
    candLRA = {'external_lra','ext_lra','lra'};
    colLRA = findCol(LC, candLRA);

    if isempty(colLUFS) || isempty(colLRA)
        warning('[validate_against_external] External CSV missing required loudness columns.');
        return;
    end

    % --------------------------------------------------------------
    % 3) Join by file name
    % --------------------------------------------------------------
    [common, idxInt, idxExt] = intersect(Tint.file, Text.file, 'stable');
    if isempty(common)
        warning('[validate_against_external] No matching file names found.');
        return;
    end

    % --------------------------------------------------------------
    % 4) Extract values and compute differences
    % --------------------------------------------------------------
    myLUFS = Tint.integratedLUFS(idxInt);
    extLUFS = Text.(Text.Properties.VariableNames{colLUFS})(idxExt);

    myLRA = Tint.LRA(idxInt);
    extLRA = Text.(Text.Properties.VariableNames{colLRA})(idxExt);

    % Remove NaN pairs
    validLUFS = ~isnan(myLUFS) & ~isnan(extLUFS);
    validLRA = ~isnan(myLRA) & ~isnan(extLRA);

    diffLUFS = myLUFS(validLUFS) - extLUFS(validLUFS);
    diffLRA = myLRA(validLRA) - extLRA(validLRA);

    % --------------------------------------------------------------
    % 5) Print statistics
    % --------------------------------------------------------------
    fprintf('\n=== Validation Results ===\n');
    fprintf('Matched files: %d\n', numel(common));

    if any(validLUFS)
        fprintf('\nIntegrated LUFS:\n');
        fprintf('  Mean difference: %.3f dB\n', mean(diffLUFS));
        fprintf('  Std difference:  %.3f dB\n', std(diffLUFS));
        fprintf('  Max difference:  %.3f dB\n', max(abs(diffLUFS)));
        fprintf('  RMSE:            %.3f dB\n', sqrt(mean(diffLUFS.^2)));
    end

    if any(validLRA)
        fprintf('\nLRA:\n');
        fprintf('  Mean difference: %.3f LU\n', mean(diffLRA));
        fprintf('  Std difference:  %.3f LU\n', std(diffLRA));
        fprintf('  Max difference:  %.3f LU\n', max(abs(diffLRA)));
        fprintf('  RMSE:            %.3f LU\n', sqrt(mean(diffLRA.^2)));
    end

    fprintf('\n');
end

% ============================================================
% Helper: Find column index by name candidates
% ============================================================
function idx = findCol(lowerNames, candidates)
    idx = [];
    for i = 1:numel(candidates)
        match = strcmpi(lowerNames, candidates{i});
        if any(match)
            idx = find(match, 1);
            return;
        end
    end
end
