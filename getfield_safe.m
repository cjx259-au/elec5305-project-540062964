function v = getfield_safe(S, name, defaultVal)
% GETFIELD_SAFE (FINAL ROBUST VERSION)
% ------------------------------------------------------------
% Safe field access:
%   · Supports struct, table row, cell-of-struct
%   · name can be string/char
%   · Returns defaultVal if field missing/empty/invalid
%   · Ensures scalar numeric/string output when possible
% ------------------------------------------------------------

    % -------- default value --------
    if nargin < 3
        defaultVal = [];
    end

    % -------- normalize field name --------
    if isstring(name), name = char(name); end
    if ~ischar(name)
        error('Field name must be char/string.');
    end

    % ============================================================
    %  Case 1: S is a table (single row)
    % ============================================================
    if istable(S)
        if height(S) == 1 && ismember(name, S.Properties.VariableNames)
            v = S{1, name};
            if iscell(v), v = v{1}; end
            if isempty(v), v = defaultVal; end
            return;
        else
            v = defaultVal;
            return;
        end
    end

    % ============================================================
    %  Case 2: S is a cell containing one struct
    % ============================================================
    if iscell(S)
        if numel(S) == 1 && isstruct(S{1})
            S = S{1};
        else
            v = defaultVal;
            return;
        end
    end

    % ============================================================
    %  Case 3: S is a struct
    % ============================================================
    if isstruct(S)
        if isfield(S, name)
            v = S.(name);

            % unwrap cell
            if iscell(v)
                if numel(v)==1
                    v = v{1};
                else
                    % cannot unwrap multi-cell → fallback
                    returnIfEmpty();
                    return;
                end
            end

            returnIfEmpty();
            return;
        else
            v = defaultVal;
            return;
        end
    end

    % ============================================================
    % OTHER types → unsupported
    % ============================================================
    v = defaultVal;


    % ============================================================
    % INNER SAFE EMPTY CHECK
    % ============================================================
    function returnIfEmpty()
        % empty → default
        if isempty(v)
            v = defaultVal;
            return;
        end

        % NaN scalar → treat as empty
        if isnumeric(v) && isscalar(v) && isnan(v)
            v = defaultVal;
            return;
        end

        % categorical → convert to string
        if iscategorical(v)
            v = string(v);
            return;
        end

        % multi-element arrays are returned as-is
        % (caller decides whether to use)
    end
end
