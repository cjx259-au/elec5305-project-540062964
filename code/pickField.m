function v = pickField(S, names, defaultVal)
% PICKFIELD  Robust struct-field extractor (case-insensitive)
% --------------------------------------------------------------------
%   v = pickField(S, {'LUFS','lufs','targetLUFS'}, default)
%
% Supports:
%   - struct
%   - scalar struct
%   - struct arrays (takes first)
%   - table (converted to struct)
%   - empty structs
%   - case-insensitive matching
%
% Returns defaultVal if no matching field found.
% --------------------------------------------------------------------

    % ------------------- Input safety -------------------
    if nargin < 3
        defaultVal = [];
    end
    v = defaultVal;

    % convert table -> struct
    if istable(S)
        S = table2struct(S);
    end

    % If S is struct array, take the first one
    if isstruct(S) && numel(S) > 1
        S = S(1);
    end

    % S must be a struct
    if ~isstruct(S) || isempty(S)
        return;
    end

    % Names must be a cellstr or string array
    if ischar(names)
        names = {names};
    elseif isstring(names)
        names = cellstr(names);
    elseif ~iscell(names)
        error('names must be char / string / cellstr.');
    end

    % ------------------- Prepare for case-insensitive match -------------------
    f  = fieldnames(S);
    lf = lower(f);

    for i = 1:numel(names)
        key = lower(names{i});

        % match
        idx = find(strcmp(lf, key), 1);

        if ~isempty(idx)
            val = S.(f{idx});

            % unify string types
            if ischar(val)
                v = string(val);
            elseif isstring(val)
                v = val;
            elseif iscategorical(val)
                v = string(val);
            else
                v = val;
            end

            return;
        end
    end
end
