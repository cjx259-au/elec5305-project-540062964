function summarize_for_writeup()
% SUMMARIZE_FOR_WRITEUP  


    cfg = config();
    resultsDir = cfg.resultsDir;

    metricsCsv  = fullfile(resultsDir, 'metrics.csv');
    platCsv_old = fullfile(resultsDir, 'summary_platform.csv');
    platCsv     = fullfile(resultsDir, 'compliance_platform.csv');

 
    platCsv_summary = fullfile(resultsDir, 'summary_platform.csv');
    if exist(platCsv_summary, 'file') == 2
        platCsv = platCsv_summary;
    elseif exist(platCsv,'file') == 2
        
        platCsv = platCsv;
    elseif exist(platCsv_old,'file') == 2
        platCsv = platCsv_old;
        warning('Using legacy summary_platform.csv');
    else
        error('No platform summary CSV found. Run make_dashboard_tables first.');
    end

    assert(exist(metricsCsv,'file')==2, 'metrics.csv missing.');
    Tm = readtable(metricsCsv);

    Tp = readtable(platCsv);

  
    outTxt = fullfile(resultsDir, 'summary.txt');
    fid = fopen(outTxt,'w');
    if fid < 0
        error('Cannot open %s for writing.', outTxt);
    end

    fprintf(fid, "==== ELEC5305 Summary ====\n\n");

    fprintf(fid, "Number of audio files: %d\n", height(Tm));

  
    if ismember("platform", string(Tp.Properties.VariableNames))
        platCount = numel(unique(Tp.platform));
    else
        platCount = height(Tp);
    end
    fprintf(fid, "Platform count: %d\n\n", platCount);

 
    fprintf(fid, "Mean Integrated Loudness : %.2f LUFS\n", ...
        mean(Tm.integratedLUFS, 'omitnan'));

    if ismember("LRA", string(Tm.Properties.VariableNames))
        fprintf(fid, "Mean Loudness Range     : %.2f LU\n\n", ...
            mean(Tm.LRA, 'omitnan'));
    else
        fprintf(fid, "Mean Loudness Range     : N/A\n\n");
    end

   
    fprintf(fid, "\n=== Platform Compliance Statistics ===\n\n");

    if ismember("limited", string(Tp.Properties.VariableNames))
      
        plats = unique(Tp.platform);
        for p = 1:numel(plats)
            platName = plats{p};
            if iscell(platName), platName = string(platName{1}); end
            idx = strcmp(string(Tp.platform), string(platName));
            
            total = sum(idx);
            limited = sum(Tp.limited(idx) ~= 0);
            rate = limited / total * 100;
            
            fprintf(fid, "%s:\n", string(platName));
            fprintf(fid, "  Total items    : %d\n", total);
            fprintf(fid, "  Limited items  : %d\n", limited);
            fprintf(fid, "  Limited rate   : %.2f%%\n", rate);
            
            if ismember("postLUFS", Tp.Properties.VariableNames)
                meanLUFS = mean(Tp.postLUFS(idx), 'omitnan');
                fprintf(fid, "  Mean postLUFS  : %.2f LUFS\n", meanLUFS);
            end
            if ismember("postTP", Tp.Properties.VariableNames)
                meanTP = mean(Tp.postTP(idx), 'omitnan');
                fprintf(fid, "  Mean postTP    : %.2f dBTP\n", meanTP);
            end
            fprintf(fid, "\n");
        end
    elseif ismember("limited_rate", string(Tp.Properties.VariableNames))
        
        for k = 1:height(Tp)
            platName = Tp.platform(k);
            if iscell(platName), platName = string(platName{1}); end
            
            fprintf(fid, "%s:\n", string(platName));
            fprintf(fid, "  Total items    : %d\n", Tp.num_items(k));
            fprintf(fid, "  Limited items  : %d\n", Tp.num_limited(k));
            fprintf(fid, "  Limited rate   : %.2f%%\n", Tp.limited_rate(k) * 100);
            
            if ismember("mean_postLUFS", Tp.Properties.VariableNames)
                fprintf(fid, "  Mean postLUFS  : %.2f LUFS\n", Tp.mean_postLUFS(k));
            end
            if ismember("mean_postTP", Tp.Properties.VariableNames)
                fprintf(fid, "  Mean postTP    : %.2f dBTP\n", Tp.mean_postTP(k));
            end
            fprintf(fid, "\n");
        end
    else
        fprintf(fid, "(No limiter statistics found)\n");
    end
    
    
    fprintf(fid, "\n=== Additional Statistics ===\n\n");
    
    if ismember("truePeak_dBTP", Tm.Properties.VariableNames)
        maxTP = max(Tm.truePeak_dBTP, [], 'omitnan');
        minTP = min(Tm.truePeak_dBTP, [], 'omitnan');
        fprintf(fid, "True Peak Range: %.2f to %.2f dBTP\n", minTP, maxTP);
    end
    
    if ismember("speechRatio", Tm.Properties.VariableNames)
        meanSpeechRatio = mean(Tm.speechRatio, 'omitnan');
        fprintf(fid, "Mean Speech Ratio: %.2f%%\n", meanSpeechRatio * 100);
    end
    
    if ismember("dialogueRisk", Tm.Properties.VariableNames)
        riskCount = sum(Tm.dialogueRisk ~= 0);
        riskRate = riskCount / height(Tm) * 100;
        fprintf(fid, "Dialogue Risk Files: %d (%.1f%%)\n", riskCount, riskRate);
    end

    fclose(fid);

    fprintf('[summarize_for_writeup] Wrote %s\n', outTxt);
end
