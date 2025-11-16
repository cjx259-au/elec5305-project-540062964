function compliance_report()
% COMPLIANCE_REPORT

% ---------------------------------------------------------

    cfg = config();
    resultsDir = cfg.resultsDir;

    % 输入 CSV
    platCsv = fullfile(resultsDir, 'summary_platform.csv');
    assert(isfile(platCsv), 'summary_platform.csv not found. Run make_dashboard_tables first.');

    Tp = readtable(platCsv);

    % 输出 TXT
    outTxt = fullfile(resultsDir, 'compliance_report.txt');
    fid = fopen(outTxt, 'w');
    assert(fid ~= -1, 'Failed to create report file: %s', outTxt);

    % ============================================================
    % Header
    % ============================================================
    fprintf(fid, "======================================\n");
    fprintf(fid, "        PLATFORM COMPLIANCE REPORT     \n");
    fprintf(fid, "======================================\n\n");
    fprintf(fid, "Generated on: %s\n\n", datestr(now, 31));

    % ============================================================
    % Summary Overview
    % ============================================================
    total_items   = sum(Tp.num_items);
    total_limited = sum(Tp.num_limited);

    if total_items > 0
        limited_rate_total = total_limited / total_items * 100;
    else
        limited_rate_total = 0;
    end

    fprintf(fid, "---------- OVERALL SUMMARY ----------\n");
    fprintf(fid, "Total Items   : %d\n", total_items);
    fprintf(fid, "Total Limited : %d\n", total_limited);
    fprintf(fid, "Limited Rate  : %.2f%%\n\n", limited_rate_total);

    % ============================================================
    % Per-platform detailed overview
    % ============================================================
    fprintf(fid, "---------- PLATFORM DETAILS ----------\n\n");

    for i = 1:height(Tp)

        % 平台名统一 string
        plat = Tp.platform(i);
        if iscell(plat), plat = string(plat{1}); end
        plat = string(plat);

        % 数值容错处理
        n_items   = Tp.num_items(i);
        n_limited = Tp.num_limited(i);

        if n_items > 0
            limited_rate = Tp.limited_rate(i) * 100;
        else
            limited_rate = 0;
        end

        fprintf(fid, "%s\n", plat);
        fprintf(fid, "  Items       : %d\n", n_items);
        fprintf(fid, "  Limited     : %d\n", n_limited);
        fprintf(fid, "  LimitedRate : %.2f%%\n", limited_rate);

        % 可选字段：postLUFS
        if ismember('mean_postLUFS', Tp.Properties.VariableNames)
            fprintf(fid, "  Avg postLUFS: %.2f LUFS\n", Tp.mean_postLUFS(i));
        end

        % 可选字段：postTP
        if ismember('mean_postTP', Tp.Properties.VariableNames)
            fprintf(fid, "  Avg postTP  : %.2f dBTP\n", Tp.mean_postTP(i));
        end

        fprintf(fid, "\n");
    end

    fclose(fid);

    fprintf('[compliance_report] Wrote %s\n', outTxt);
end
