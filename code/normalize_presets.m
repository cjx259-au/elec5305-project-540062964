function S = normalize_presets(Sraw)
% NORMALIZE_PRESETS
% -------------------------------------------------------------
% Normalize platform preset definitions from:
%   - struct
%   - struct array
%   - table
%   - cell of struct
%
% Output always: struct array with required fields:
%   · platform      (string)
%   · targetLUFS    (double)
%   · tpCeil        (double)
%
% Also supports field aliases:
%   platform/name/platformName
%   target,targetLUFS,LUFS,lufs
%   tpCeil,tpLimit,tpCeiling,truePeakCeil,maxTP,R128_maxTP,maxTruePeak
%
% Safe for malformed data; throws clear error if unusable.
% -------------------------------------------------------------

    % =============================
    % Step 1: Normalize container
    % =============================
    if istable(Sraw)
        S = table2struct(Sraw);
    elseif iscell(Sraw)
        if isempty(Sraw)
            S = struct([]);
        elseif all(cellfun(@isstruct, Sraw))
            S = [Sraw{:}];
        else
            error('normalize_presets:InvalidCell', ...
                'Cell input must contain only struct elements.');
        end
    elseif isstruct(Sraw)
        S = Sraw;
    else
        error('normalize_presets:InvalidType', ...
            'platform_presets() must return struct/table/cell-of-struct.');
    end

    if isempty(S)
        error('normalize_presets:Empty', ...
            'platform_presets returns empty set.');
    end

    % Must be struct array now
    if ~isstruct(S)
        error('normalize_presets:TypeError', ...
            'Internal error: S must be struct.');
    end

    % =============================
    % Step 2: Iterate & normalize
    % =============================
    for i = 1:numel(S)
        Si = S(i);

        % -------- PLATFORM NAME --------
        nameFields = {'platform','name','platformName'};
        S(i).platform = get_str(Si, nameFields, sprintf("platform_%d", i));

        % -------- TARGET LUFS ----------
        tgtFields = {'targetLUFS','target','LUFS','lufs'};
        S(i).targetLUFS = get_num(Si, tgtFields, -14);

        % -------- TRUE PEAK CEILING ----
        tpFields = {'tpCeil','tpLimit','tpCeiling','truePeakCeil','maxTP','R128_maxTP','maxTruePeak'};
        S(i).tpCeil = get_num(Si, tpFields, -1);

        % Type safety
        S(i).platform   = string(S(i).platform);
        S(i).targetLUFS = double(S(i).targetLUFS);
        S(i).tpCeil     = double(S(i).tpCeil);
    end
end


% ===========================================================
% Safe numeric getter w/ alias support
% ===========================================================
function v = get_num(S, names, defaultVal)
    v = defaultVal;
    for k = 1:numel(names)
        f = names{k};
        if isfield(S, f)
            x = S.(f);
            if isnumeric(x) && isscalar(x) && isfinite(x)
                v = double(x);
                return;
            elseif isstring(x) || ischar(x)
                tmp = str2double(x);
                if isfinite(tmp)
                    v = double(tmp);
                    return;
                end
            end
        end
    end
end

% ===========================================================
% Safe string getter w/ alias support
% ===========================================================
function s = get_str(S, names, defaultVal)
    s = string(defaultVal);
    for k = 1:numel(names)
        f = names{k};
        if isfield(S, f)
            v = S.(f);
            if isstring(v)
                s = v;
                return;
            elseif ischar(v)
                s = string(v);
                return;
            elseif iscategorical(v)
                s = string(v);
                return;
            end
        end
    end
end
