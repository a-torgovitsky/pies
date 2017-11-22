%*******************************************************************************
% PlotID.m
%
% Create plots of the identified set
%*******************************************************************************
function PlotID(IDSetBeta, MinATE, MaxATE, Settings, Type)
    close;
    figure('visible', 'off');

    if (Type == 1) % Grayscale
        colormap([1 1 1; Settings.Grayscale*ones(1,3)]);
        contourf(Settings.Beta0Grid, Settings.Beta1Grid, IDSetBeta,...
            'LineColor', 'none');

        Title = 'Identified Set (Shaded Area)';
        Filename = 'IDSetBeta';
    else % With colored partitions
        MinATE = round(MinATE,3);
        MinATE(abs(MinATE) == Inf) = nan;

        % Recode MinATE to help spread out the numbers
        % (so that the colors are more distinct)
        U = unique(MinATE);
        for k = 1:1:length(U)
            I = find(MinATE == U(k));
            MinATE(I) = k;
        end

        h = pcolor(Settings.Beta0Grid, Settings.Beta1Grid, MinATE);
        set(h, 'EdgeColor', 'none');
        colormap(jet)

        Title = 'Identified Set (Partitioned)';
        Filename = 'IDSetBetaPartitioned';
    end

    xlim([min(Settings.Beta0Grid) max(Settings.Beta0Grid)]);
    ylim([min(Settings.Beta1Grid) max(Settings.Beta1Grid)]);
    grid on;
    grid minor;
    hold on;

    if ~(Type == 1)
        set(gca, 'layer', 'top');
    end

    xlabel('$\beta_{0}$', 'Interpreter', 'Latex',...
            'FontSize', Settings.FontsizeLabel);
    ylabel('$\beta_{1}$', 'Rotation', 0, 'Interpreter', 'Latex',...
        'FontSize', Settings.FontsizeLabel);
    plot(Settings.Beta0, Settings.Beta1, 'k+',...
        'MarkerSize', Settings.MarkersizeBig);

    set(gca, 'XTick',...
        fix(min(Settings.Beta0Grid)):1:fix(max(Settings.Beta0Grid)));
    set(gca, 'YTick',...
        fix(min(Settings.Beta1Grid)):1:fix(max(Settings.Beta1Grid)));
    set(gca, 'FontSize', Settings.FontsizeAxis)

    daspect([1 Settings.FigWidth/Settings.FigHeight 1]);

    set(gcf, 'InvertHardcopy', 'on');
    set(gcf, 'PaperUnits', 'inches');
    papersize = get(gcf, 'PaperSize');
    left = (papersize(1) - Settings.FigWidth)/2;
    bottom = (papersize(2) - Settings.FigHeight)/2;
    myfiguresize = [left, bottom, Settings.FigWidth, Settings.FigHeight];
    set(gcf, 'PaperPosition', myfiguresize);
    % This gets rid of some extra whitespace
    set(gca,'LooseInset',[0 0 0 0]);

    fname = sprintf([Filename '-%s'], Settings.DirName);
    savefig(fname);
    print(fname, '-dpng', '-r300');
    print(fname,'-depsc','-tiff');

    title(Title, 'FontSize', Settings.FontsizeTitle);
    fname = sprintf([Filename '-Standalone-%s'], Settings.DirName);
    savefig(fname);
    print(fname, '-dpng');
    print(fname,'-depsc','-tiff');

end
