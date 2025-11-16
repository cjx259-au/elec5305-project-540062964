function T = row_metrics(name, M, tp_ref)
% ROW_METRICS  
% Build one row for metrics.csv from loudness struct M.
%
% Inputs:
%   name   - file name (char/string)
%   M      - struct with loudness metrics
%   tp_ref - optional true peak reference (fallback if M doesn't have it)
%
% Output columns:
%   file, integratedLUFS, LRA, shortTermLUFS, momentaryLUFS,
%   truePeak_dBTP, speechLUFS, speechRatio, LD, dialogueRisk

    % ---------- safe getter with robust type handling ----------
    function v = pick(MS, names, defaultVal)
        v = defaultVal;
        if ~isstruct(MS), return; end

        for ii = 1:numel(names)
            f = names{ii};
            if isfield(MS, f)
                vv = MS.(f);
                
                % Handle empty
                if isempty(vv)
                    continue;
                end
                
                % Numeric scalar
                if isnumeric(vv) && isscalar(vv)
                    if isfinite(vv)
                        v = double(vv);
                        return;
                    end
                % Numeric array - take first element
                elseif isnumeric(vv) && ~isempty(vv)
                    vv = vv(1);
                    if isfinite(vv)
                        v = double(vv);
                        return;
                    end
                % String/char - try to convert
                elseif isstring(vv) || ischar(vv)
                    tmp = str2double(vv);
                    if isfinite(tmp)
                        v = tmp;
                        return;
                    end
                % Logical
                elseif islogical(vv)
                    v = double(vv);
                    return;
                end
            end
        end
    end

    % ---------- Extract fields with alias fallback ----------

    integrated = pick(M, {'integrated','integratedLUFS','I'}, NaN);

    LRA        = pick(M, {'LRA','lra','loudnessRange','loudness_range'}, NaN);

    shortTerm  = pick(M, {'shortTerm','shortTermLUFS','shortTerm_dB','short_term'}, NaN);

    momentary  = pick(M, {'momentary','momentaryLUFS','momentary_dB','momentary_lufs'}, NaN);

    % true-peak: prefer M.truePeak / M.truePeak_dBTP, else tp_ref
    if nargin >= 3 && ~isempty(tp_ref) && isfinite(tp_ref)
        tp_default = tp_ref;
    else
        tp_default = NaN;
    end
    tp = pick(M, {'truePeak','truePeak_dBTP','postTP','postTP_dBTP','tp','TP'}, tp_default);

    speechLUFS  = pick(M, {'speechLUFS','speech_lufs','speechLufs','dialogueLUFS'}, NaN);
    speechRatio = pick(M, {'speechRatio','speech_ratio','speechRatio','dialogueRatio'}, NaN);
    LD          = pick(M, {'LD','dialogueDiff','dialogueLevelDiff','dialogue_level_diff'}, NaN);

    % dialogue risk (fallback = 0)
    risk        = pick(M, {'dialogueRisk','flag_risky','risk','dialogue_risk','flag_bad'}, 0);
    
    % Ensure risk is 0 or 1
    if ~isnan(risk) && risk ~= 0
        risk = 1;
    else
        risk = 0;
    end

    % ---------- build table ----------
    T = table( string(name), ...
               integrated, LRA, shortTerm, momentary, tp, ...
               speechLUFS, speechRatio, LD, risk, ...
               'VariableNames', {'file','integratedLUFS','LRA', ...
               'shortTermLUFS','momentaryLUFS','truePeak_dBTP', ...
               'speechLUFS','speechRatio','LD','dialogueRisk'});
end
