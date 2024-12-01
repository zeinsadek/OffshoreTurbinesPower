% Power Correlation
% 1/1/2024

clear; close all; clc;

waves         = {'0', 'A', 'B', 'C'};
wave_keys     = {'X', 'A', 'B', 'C' };
main_path     = "F:\Power\1_20_2024";
figure_folder = fullfile(main_path, "Figures");

for i = 1:length(waves)
    temp = load(strcat("F:\Power\1_20_2024\Matfiles\WT60_WV", waves{i}, ".mat"));
    temp = temp.output;
    data.(wave_keys{i}) = temp;
end
center_turbines = [2,5,8,11];
colors = cool(length(center_turbines));

%% Power Fluctuations
ax = figure('name', 'center turbine power signals', 'Position', [500, 500, 800, 400]);
t  = tiledlayout(4,1,'TileSpacing', 'compact');

wave_colors = winter(length(waves));
sgtitle('Center Turbine Power Fluctuations WT60')

for i = 1:4
    nexttile()
    hold on
    for w = 1:length(waves)
        window = 1;
        mean_P = mean(data.(wave_keys{w})(center_turbines(i)).P, 'all', 'omitnan');
        plot(data.(wave_keys{w})(center_turbines(i)).t, movmean(data.(wave_keys{w})(center_turbines(i)).P - mean_P, window), ...
            'LineWidth', 1, 'color', wave_colors(w,:), 'displayname', strcat('WV', waves{w}))
    end
    hold off
    xlim([0, 20])
    ylim([-30, 30])
    title(strcat('Row', num2str(i)))
    ylabel('Power [mW]')
    legend('Interpreter', 'none')
end
xlabel('Time [s]')
exportgraphics(ax, fullfile(figure_folder, 'WT60_WVX_center_power_fluctuations.png'), 'Resolution', 200)

%% Different Moving Average Windows
% windows = 1:2:20;
% 
% ax = figure('name', 'center turbine power signals', 'Position', [500, 500, 800, 400]);
% t  = tiledlayout(length(waves),1,'TileSpacing', 'compact');
% 
% window_colors = turbo(length(windows));
% wave_colors = winter(length(waves));
% sgtitle('Moving Average Windows WT60')
% 
% for i = 1:length(waves)
%     nexttile()
%     hold on
%     for w = 1:length(windows)
%         mean_P = mean(data.(wave_keys{i})(center_turbines(1)).P, 'all', 'omitnan');
%         plot(data.(wave_keys{i})(center_turbines(1)).t, movmean(data.(wave_keys{i})(center_turbines(1)).P - mean_P, windows(w)), ...
%             'LineWidth', 1, 'color', window_colors(w,:), 'displayname', strcat('Window', num2str(windows(w))))
%     end
%     hold off
%     title(strcat('WV', waves{i}))
%     xlim([0,5])
%     ylabel('Power [mW]')
%     % legend()
% end
% xlabel('Time [s]')


%% FFT
ax = figure('name', 'fft', 'Position', [100, 100, 1200, 800]);
t  = tiledlayout(4, 1, 'TileSpacing', 'compact');
linewith = 1;
% sgtitle('FFT of Power Fluctuations: WT6.0')

for i = 1:4
    nexttile()
    hold on
    for w = 1:length(waves)

        R0      = center_turbines(i);
        R0_mask = ~isnan(data.(wave_keys{w})(R0).P);
        dt      = data.(wave_keys{w})(R0).t(2) - data.(wave_keys{w})(R0).t(1);
        window  = 2;
    
        % Power
        R0_P    = data.(wave_keys{w})(R0).P(R0_mask);
        R0_mean = mean(data.(wave_keys{w})(R0).P, 'all', 'omitnan');
        R0_fluc = R0_P - R0_mean;
        R0_fluc_movmean = movmean(R0_fluc, window);
    
        % Time
        R0_t = data.(wave_keys{w})(R0).t;
        R0_t = R0_t(R0_mask);
    
        %%% From MATHWORKS
        Ts = mean(diff(R0_t), 'all', 'omitnan');
        Fs = 1/Ts;
        Fn = Fs/2;
        L  = length(R0_mask);
        % f  = Fs/L*(0:(L/2));
        f  = linspace(0, 1, fix(L/2) + 1) * Fn;
        Y  = fft(R0_fluc_movmean);
        P2 = abs(Y/L);
        P1 = P2(1:L/2+1);
        P1(2:end-1) = 2*P1(2:end-1);
        
        plot(f, P1, 'LineWidth', linewith, 'color', wave_colors(w,:), 'DisplayName', strcat('WV', waves{w})) 
        
    end
    hold off
    legend('location', 'northwest', 'Interpreter', 'none')
    grid on
    xlim([1, max(f)])
    ylabel("|P1(f)|")
    set(gca, 'XScale', 'log');%, 'YScale', 'log')
    tit = strcat('Row', {' '}, num2str(i));
    title(tit{1})
end

xlabel('Frequency [Hz]')
exportgraphics(ax, fullfile(figure_folder, 'WT60_WVX_center_power_FFT.png'), 'Resolution', 200)

%% PSD
ax = figure('name', 'psd', 'Position', [100, 100, 1200, 800]);
t  = tiledlayout(4, 1, 'TileSpacing', 'compact');
linewith = 1;
window   = 1;
% sgtitle('PSD of Power Fluctuations: WT6.0')

for i = 1:4
    nexttile()
    hold on
    for w = 1:length(waves)

        R0      = center_turbines(i);
        R0_mask = ~isnan(data.(wave_keys{w})(R0).P);
        dt      = data.(wave_keys{w})(R0).t(2) - data.(wave_keys{w})(R0).t(1);
    
        % Power
        R0_P    = data.(wave_keys{w})(R0).P(R0_mask);
        R0_mean = mean(data.(wave_keys{w})(R0).P, 'all', 'omitnan');
        R0_fluc = R0_P - R0_mean;
        R0_fluc_movmean = movmean(R0_fluc, window);
    
        % Time
        R0_t = data.(wave_keys{w})(R0).t;
        R0_t = R0_t(R0_mask);
    
        %%% From MATHWORKS
        Ts = mean(diff(R0_t), 'all', 'omitnan');
        Fs = 1/Ts;
        L  = length(R0_mask);

        [psd,f] = pwelch(R0_fluc_movmean, [], [], [], Fs);
        plot(f, 10 * log10(psd), 'LineWidth', linewith, 'color', wave_colors(w,:), 'DisplayName', strcat('WV', waves{w})) 
        
    end
    temp = linspace(1E-1,1E0,100);
    plot(temp, -5/3 * 10 * log10(temp) - 5, 'color', 'black', 'LineStyle', '--', 'LineWidth', 2, 'HandleVisibility', 'off')
    hold off
    % legend('location', 'northwest', 'interpreter', 'none')
    grid on
    % xlim([min(f), max(f)])
    xlim([1E-1, max(f)])
    ylim([-40, 25])
    ylabel("dB / Hz")
    set(gca, 'XScale', 'log');%, 'YScale', 'log')
    tit = strcat('Row', {' '}, num2str(i));
    title(tit{1})
end

leg = legend('Orientation', 'Horizontal');
leg.Layout.Tile = 'north';

xlabel('Frequency [Hz]')
exportgraphics(ax, fullfile(figure_folder, 'WT60_WVX_center_power_PSD.png'), 'Resolution', 200)

%% Auto Correlation
ax = figure('name', 'acorr', 'Position', [100, 100, 1200, 800]);
t  = tiledlayout(4, 1, 'TileSpacing', 'compact');

for i = 1:4
    nexttile()
    hold on
    for w = 1:length(waves)
        R0      = center_turbines(i);
        R0_mask = ~isnan(data.(wave_keys{w})(R0).P);
        
        dt     = data.(wave_keys{w})(R0).t(2) - data.(wave_keys{w})(R0).t(1);
        window = 1;
    
        R0_P    = data.(wave_keys{w})(R0).P(R0_mask);
        R0_mean = mean(data.(wave_keys{w})(R0).P, 'all', 'omitnan');
        R0_fluc = R0_P - R0_mean;
        R0_fluc_movmean = movmean(R0_fluc, window);
    
        [c,lags] = autocorr(R0_fluc_movmean);
        plot(dt * lags,c, 'linewidth', 2', 'color', wave_colors(w,:), 'displayname', strcat('WV', waves{w}))
        
    end
    hold off
    legend()
    xlim([min(dt * lags), max(dt * lags)])
    ylabel('Cross-Correlation')
    tit = strcat('Auto-Correlation of Power Fluctuations of Row', num2str(i));
    title(tit)
end

%% Cross-Correlation
ax = figure('name', 'xcorr', 'Position', [100, 100, 800, 800]);
t = tiledlayout(3, 1, 'TileSpacing', 'compact');

for i = 1:3
    nexttile()
    hold on
    for w = 1:length(waves)
        R0 = center_turbines(i);
        R1 = center_turbines(i + 1);
    
        R0_mask = ~isnan(data.(wave_keys{w})(R0).P);
        R1_mask = ~isnan(data.(wave_keys{w})(R1).P);
    
        if length(R0_mask) <= length(R1_mask)
            mask = R0_mask;
        else
            mask = R1_mask;
        end
    
        dt = data.(wave_keys{w})(R0).t(2) - data.(wave_keys{w})(R0).t(1);
        window = 1;
    
        R0_P    = data.(wave_keys{w})(R0).P(mask);
        R0_mean = mean(data.(wave_keys{w})(R0).P, 'all', 'omitnan');
        R0_fluc = R0_P - R0_mean;
        R0_fluc_movmean = movmean(R0_fluc, window);
    
        
        R1_P    = data.(wave_keys{w})(R1).P(mask);
        R1_mean = mean(data.(wave_keys{w})(R1).P, 'all', 'omitnan');
        R1_fluc = R1_P - R1_mean;
        R1_fluc_movmean = movmean(R1_fluc, window);
    
        [c,lags]          = xcorr(R0_fluc_movmean, R1_fluc_movmean, 'normalized');
        [peak, peak_inds] = findpeaks(abs(c), 'MinPeakDistance', 2000, 'MinPeakProminence', 5);

        plot(dt * lags,c, 'linewidth', 2', 'color', wave_colors(w,:), 'displayname', strcat('WV', waves{w}))
    end
    hold off
    legend()
    ylim([-1,1])
    xlim([min(dt * lags), max(dt * lags)])
    ylabel('Cross-Correlation')
    tit = strcat('Cross-Correlation of Power Fluctuations between Rows', num2str(i), ' and ', num2str(i + 1));
    title(tit)
end





