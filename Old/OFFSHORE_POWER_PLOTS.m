clc;
clear;
close all;
addpath('C:\Users\oferc\OneDrive\Documents\MATLAB\Functions');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open Data File
full_path       = "C:\Users\oferc\OneDrive\Documents\1_Projects\14_Downwind_Whisker_Turbines\Power_Data\POWER_RESULTS_ALL.mat";
data            = load(full_path).power;
data_sub        = [];

% Point to Figure Save Location
fig_save        = "C:\Users\oferc\OneDrive\Documents\1_Projects\14_Downwind_Whisker_Turbines\Power_Data\Power_Results_Figures\Final\";
fig_name        = 23;

% Check if File Exists
if isfile(strcat(fig_save, string(fig_name), '.tiff'))
     in         = input("Please Enter a New Number for Name: ");
     fprintf("Creating File: %d...\n", in)
     fig_name   = string(in);
else
     fprintf("Creating File: %d...\n", fig_name)
     fig_name   = string(fig_name);
end

% Input Direction   ['UW', 'DW']
for input_dir   = {'UW', 'DW'}

% Input Lambda      ['00', '1A', '1B', '2B', '4B']
for input_lam   = {'1B'}

% Input Coning      ['00', '05', '10', '20']
for input_con   = {'00', '05', '10', '20'}

% Input Wind Speed  [3]
input_spd       = 3;

% Input X-Variable to Plot
X_plot          = 'Ts_mean';

% Input Y-Variable to Plot
Y_plot          = 'Pv_mean';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARSE DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

match_direction     = strcmp({data.direction}, input_dir);  % Logical indices
idx_direction       = find(match_direction);                % Indices
data_direction      = data(idx_direction);                  % Faster with logical indexing

match_lambda        = strcmp({data.lambda}, input_lam);     % Logical indices
idx_lambda          = find(match_lambda);                   % Indices
data_lambda         = data(idx_lambda);                     % Faster with logical indexing

match_coning        = strcmp({data.coning}, input_con);     % Logical indices
idx_coning          = find(match_coning);                   % Indices
data_coning         = data(idx_coning);                     % Faster with logical indexing


[val_sub1, ~]       = intersect(idx_direction, idx_lambda);
[val_sub2, ~]       = intersect(val_sub1, idx_coning);

data_add            = data(val_sub2);
data_sub            = [data_sub, data(val_sub2)];

end
end
end

h = 8;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOT & SAVE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
scale_pos = 1.5;
f1 = figure('Renderer', 'painters', 'Position', [scale_pos*10 scale_pos*10 scale_pos*1000 scale_pos*600]);
hold on
for j = 1:length(data_sub)
    colors = jet(length(data_sub));
    if erase(data_sub(j).direction, 'W') == 'D'
        plot_direction      = "$$\Rightarrow$$ ";
    else
        plot_direction      = "$$\Leftarrow$$ ";
    end
    if data_sub(j).lambda(2) == 'A'
        whisker_direction   = "$$\downarrow$$ ";
    elseif data_sub(j).lambda(2) == 'B'
        whisker_direction   = "$$\uparrow$$ ";
    else
        whisker_direction   = "0 ";
    end
    plot(data_sub(j).(X_plot), data_sub(j).(Y_plot), 'DisplayName', strcat(plot_direction, data_sub(j).lambda(1), "$$\lambda$$ ", whisker_direction, data_sub(j).coning, "$$^{\circ}$$"), "Color", colors(j, :), 'linewidth', 3)
    scatter(data_sub(j).(X_plot), data_sub(j).(Y_plot), 'filled', 'handleVisibility', 'off', 'MarkerFaceColor', colors(j, :));

%     fit_x       = linspace(min(data_sub(j).(X_plot)), max(data_sub(j).(X_plot)), 1000);
%     fit_y       = polyfit(data_sub(j).(X_plot), data_sub(j).(Y_plot), 6);
%     fit_y       = polyval(fit_y, fit_x);
%     plot(fit_x, fit_y, 'color', colors(j, :), 'handleVisibility', 'off')
%     [max_y, I]  = max(fit_y);
%     max_x       = fit_x(I);
%     xline(max_x, '--', "Color", colors(j, :), 'handleVisibility', 'off')
%     tsr(j)      = max_x;

end
xlabel(X_plot, 'Interpreter', 'none')
ylabel(Y_plot, 'Interpreter', 'none')
lgd = legend;
set(lgd, 'textcolor', 'white', 'box', 'off', 'FontSize', 20, 'interpreter', 'latex', 'Location', 'NorthWest')

if strcmp(X_plot, 'TSR')
    xtick = linspace(2, 6.5, 10);
    xlim([2, 6.5])
end
if strcmp(X_plot, 'Ts_mean')
    xtick = linspace(2, 20, 19);
    xlim([2, 20])
end
if strcmp(Y_plot, 'Cp')
    ytick = linspace(0.08, 0.26, 7);
    ylim([0.08, 0.26])
end
if strcmp(Y_plot, 'Pv_mean')
    ytick = linspace(0, 0.08, 9);
    ylim([0.01, 0.08])
end

    set(gca,'xtick', xtick, 'ytick', ytick, 'fontsize', 22, 'color', 'black', 'GridColor', 'white') 
grid on
hold off

exportgraphics(f1, strcat(fig_save, fig_name, '.tiff'))
fprintf("File Save Complete!\n")

% % Plot TSR vs. ohm Data
% lookup      = [0.5 0.66 0.78 1 2 3.6 4.7 6.2 8.2 9.1 11 13 16 18 20.2 22 24 27 30 33 36 39 47 56 66];
% figure
% set(gca, 'color', 'black')
% set(gca, 'GridColor', 'white')
% hold on
% for j = 1:length(data_sub)
%     colors = jet(length(data_sub));
%     plot(lookup, data_sub(j).TSR, 'DisplayName', erase(data_sub(j).name, ".mat"), "Color", colors(j, :), 'linewidth', 3)
%     scatter(lookup, data_sub(j).TSR, 'filled', 'handleVisibility', 'off', 'MarkerFaceColor', colors(j, :));
% 
%     ohm         = linspace(min(lookup), max(lookup), 1000);
%     ts          = polyfit(lookup, data_sub(j).TSR, 6);
%     ts          = polyval(ts, ohm);
%     plot(ohm, ts, 'color', colors(j, :), 'handleVisibility', 'off')
% 
%     yline(tsr(j), '--', "Color", colors(j, :), 'handleVisibility', 'off')
% 
%     [d, ix]     = min(abs(ts - tsr(j)));
%     ohm_opt     = fprintf('[%d] ohm = %d\n', j, ohm(ix));
%     xline(ohm_opt, '-', "Color", colors(j, :), 'handleVisibility', 'off')
% 
%     resistor(j) = ohm_opt;
% 
% end
% xlabel('ohm')
% ylabel('TSR')
% lgd = legend('Interpreter', 'none', 'Location', 'NorthWest');
% set(lgd, 'textcolor', 'white', 'box', 'off', 'FontSize', 12)
% grid on
% hold off
%
% resistor(2) = [];
% resistor(3) = [];
% mean_ohm = mean(resistor);
