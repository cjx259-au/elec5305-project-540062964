function plot_helpers(which, A, B, figDir)
switch which
    case 'lufs_timeline'
        % A: struct m, B: filename
        m = A; fname = B;
        f = figure('Visible','off'); hold on; grid on;

        h = []; lab = {};  % 收集已绘制曲线及标签

        if ~isempty(m.stCurve)
            h(end+1) = plot(m.t_st, m.stCurve, 'LineWidth',1.3); %#ok<AGROW>
            lab{end+1} = 'Short-term (3 s)';                       %#ok<AGROW>
        end
        if ~isempty(m.mtCurve)
            h(end+1) = plot(m.t_mt, m.mtCurve, '--', 'LineWidth',1.0); %#ok<AGROW>
            lab{end+1} = 'Momentary (400 ms)';                         %#ok<AGROW>
        end

        xlabel('Time (s)'); ylabel('LUFS');
        title(sprintf('LUFS Timeline — %s', fname),'Interpreter','none');

        % 只有当确实画了曲线时才加图例
        if ~isempty(h)
            legend(h, lab, 'Location','best');
        end

        saveas(f, fullfile(figDir, sprintf('lufs_%s.png',sanitize(fname))));
        close(f);

    case 'scatter_LU_deltaTP'
        % A: table T, B: table C
        T = A; %#ok<NASGU>
        f = figure('Visible','off'); grid on;
        if ~isempty(A)
            d = A.IntegratedLUFS - (-23); % 相对 R128 目标
            scatter(d, A.TruePeak_dBTP, 30, 'filled');
            xlabel('\Delta LU (vs -23 LUFS)'); ylabel('True Peak (dBTP)');
            title('Delta-LU vs True Peak (R128 ref)');
        else
            text(0.5,0.5,'No data','HorizontalAlignment','center');
        end
        saveas(f, fullfile(figDir,'scatter_deltaLU_TP.png')); close(f);

    case 'hist_LRA'
        % A: table T
        f = figure('Visible','off'); grid on;
        if ~isempty(A)
            histogram(A.LRA, 'BinWidth',1);
            xlabel('LRA'); ylabel('Count');
            title('Loudness Range (LRA) Distribution');
        else
            text(0.5,0.5,'No data','HorizontalAlignment','center');
        end
        saveas(f, fullfile(figDir,'hist_LRA.png')); close(f);
end
end

function s = sanitize(fname)
s = regexprep(fname,'[^a-zA-Z0-9]','_');
end

