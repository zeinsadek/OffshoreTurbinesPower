%%% Getting incident velocity from calibration data
% Zein Sadek
% 12/18/2023

clear; close all; clc;

farm_arrangement = "FWF_Staggered";
farm_spacing = 'WT60_SX30_AG0';

% Data path
mat_path = '/Users/zeinsadek/Desktop/Experiments/Offshore/Power/Data/Matfiles';
data = load(fullfile(mat_path, farm_arrangement, farm_spacing, 'Sweeps', strcat(farm_arrangement, '_', farm_spacing, '_PowerCurve.mat')));
data = data.output;

% Save path
save_path = fullfile(mat_path, farm_arrangement, farm_spacing, "IncidentVelocity");
if ~exist(save_path, 'dir')
    mkdir(save_path);
end


%% Plot power curve

clc; close all
figure('color', 'white')
t = tiledlayout(1,4);
row_colors = {'#521945', '#912F56', '#539987', '#2D7DD2'};

lw = 4;
sz = 40;


for row = 1:size(data,2)

    inst_resistors = data(row).R;
    resistors = unique(inst_resistors);
    % optimal is the resistor value, not the index
    optimal = data(row).optimal;
    optimal_index = find(resistors == optimal);

    avg_powers = data(row).P_avg;
    avg_tipspeeds = data(row).TS_avg;
    polynomial_fit = polyval(polyfit(avg_tipspeeds, avg_powers, 4), avg_tipspeeds);

    if row == 4
        vis = 'on';
    else
        vis = 'off';
    end

    h(row) = nexttile;
    title(sprintf('Row %1.0f', row))
    
    hold on
    % Plot actual power data
    scatter(avg_tipspeeds, avg_powers, sz, ...
            'filled', 'MarkerFaceColor', row_colors{row}, 'HandleVisibility', 'off')

    % Plot polynomial fit
    plot(avg_tipspeeds, polynomial_fit, ...
        'LineWidth', lw, 'linestyle', '--', 'color', row_colors{row}, 'HandleVisibility', 'off')


    % Highlight the top of the experimental curve
    scatter(avg_tipspeeds(optimal_index), polynomial_fit(optimal_index), 2 * sz, ...
            'filled', 'MarkerFaceColor', 'magenta', ...
            'Displayname', 'Measured Peak', 'HandleVisibility', vis)
    xline(avg_tipspeeds(optimal_index), 'color', 'magenta', 'linestyle', '--', 'HandleVisibility', 'off')

    % Highlight peak of polynomial fit
    [~, polymaxind] = max(polynomial_fit, [], 'all');
    scatter(avg_tipspeeds(polymaxind), polynomial_fit(polymaxind), 2 * sz, ...
            'filled', 'MarkerFaceColor', 'cyan', ...
            'Displayname', 'Polynomial Peak', 'HandleVisibility', vis)
    xline(avg_tipspeeds(polymaxind), 'color', 'cyan', 'linestyle', '--', 'HandleVisibility', 'off')


    %%% Save the polynomial max-resistor
    polynomial_setpoint(row) = resistors(polymaxind);

    fprintf('Row %1.0f\n', row)
    fprintf('Used Setpoint: R = %2.0f\nPolynomial Setpoint: R = %2.0f\n\n', optimal, resistors(polymaxind))
   
    hold off
    grid on
    legend('location', 'northoutside', 'box', 'off', 'fontsize', 12)

end

linkaxes(h, 'xy')
xlabel(t, 'Average Tip Speed [m/s]')
ylabel(t, 'Average Power [mW]')


%% Plot time series

% clc; close all
% figure('color', 'white')
% tiledlayout(4,1)
% 
% for row = 1:4
% 
%     time = tmp(row).time;
%     inst_power = tmp(row).P;
%     inst_tipspeed = tmp(row).TS;
%     inst_resistors = tmp(row).R;
%     avg_powers = tmp(row).P_avg;
% 
%     % Color code time-series based on resistors
%     resistors = unique(inst_resistors);
%     colors = parula(length(resistors));
% 
%     h(row) = nexttile;
%     title(sprintf('Row = %1.0f', row))
%     hold on
%     for i = 1:length(resistors)
%        plot(time(inst_resistors == resistors(i)), inst_power(inst_resistors == resistors(i)), ...
%             'color', colors(i,:))
%        xline(max(time(inst_resistors == resistors(i)), [], 'all', 'omitnan'))
%        scatter(mean(time(inst_resistors == resistors(i)), 'all', 'omitnan'), avg_powers(i), ...
%                50, 'filled', 'MarkerFaceColor', 'black')
%     end
%     hold off
%     xlim([0, max(time)])
%     % ylim([0, inf])
%     xlabel('Time [s]')
%     ylabel('Power [mW]')
% end
% 
% linkaxes(h, 'xy')

%% Only look at time-series of optimal resistor

clc; close all
ax = figure('color', 'white');
tiledlayout(size(data, 2),1)

for row = 1:size(data, 2)

    time = data(row).time;
    inst_power = data(row).P;
    inst_tipspeed = data(row).TS;
    inst_resistors = data(row).R;
    setpoint_resistor = data(row).optimal;
    
    % Color code time-series based on resistors
    resistors = unique(inst_resistors);
    % colors = parula(length(resistors));
    
    h(row) = nexttile;
    title(sprintf('Row = %1.0f', row))
    % Time-series of setpoint resistor
    hold on
    plot(time(inst_resistors == setpoint_resistor), inst_power(inst_resistors == setpoint_resistor), ...
         'color', 'red')

    % Time-series of +/-1 from setpoint resistor
    plot(time(inst_resistors == setpoint_resistor + 1), inst_power(inst_resistors == setpoint_resistor + 1), ...
         'color', 'blue')
    plot(time(inst_resistors == setpoint_resistor - 1), inst_power(inst_resistors == setpoint_resistor - 1), ...
         'color', 'blue')

    % Plot line to seperate them
    % xline(min(time(inst_resistors == setpoint_resistor + 1), [], 'all'))
    % xline(max(time(inst_resistors == setpoint_resistor - 1), [], 'all'))
    hold off

    g = gca;
    g.XAxis.Visible = 'off';

    % xlim([0, max(time)])
    % ylim([0, inf])
    set(gca,'xtick',[])
    ylim([0, 250])
    yticks(0:50:250)
    xlim([min(time(inst_resistors == setpoint_resistor - 1), [], 'all'), max(time(inst_resistors == setpoint_resistor + 1), [], 'all')])
    ylabel('Power [mW]')
end

linkaxes(h, 'y')

% Save figure
pause(2)
exportgraphics(ax, fullfile(save_path, strcat(farm_arrangement, '_', farm_spacing, '_PeakPowerSignals.png')), ...
               'Resolution', 300)
close all

%% Convert from power time-series [mW] into velocity [m/s]

D = 0.15;
rho = 1.225;
A = (pi / 4) * (D^2);

clc; close all
ax = figure('color', 'white');
t = tiledlayout(size(data, 2) + 1, 1);
sgtitle(sprintf('%s %s: $S_x = %1.1f D$', split(farm_arrangement, '_'), str2double(farm_spacing(8:9))/10), 'interpreter', 'latex')

for row = 1:size(data, 2)

    % Instantaneous
    time = data(row).time;
    inst_power = data(row).P;
    inst_tipspeed = data(row).TS;
    inst_resistors = data(row).R;

    % Averages
    avg_tipspeeds = data(row).TS_avg;
    avg_powers = data(row).P_avg;
    polynomial_fit = polyval(polyfit(avg_tipspeeds, avg_powers, 4), avg_tipspeeds);

    % Resistors
    setpoint_resistor = data(row).optimal;
    polynomial_resistor = polynomial_setpoint(row);
    resistors = unique(inst_resistors);

    % Find indicies for experimental/polynomial resistors
    optimal_index = find(resistors == setpoint_resistor);
    polynomial_index = find(resistors == polynomial_resistor);

   
    % Power signal centered at setpoint resistor used in experiments
    setpoint_power_signal = [inst_power(inst_resistors == setpoint_resistor - 1); ...
                             inst_power(inst_resistors == setpoint_resistor); ...
                             inst_power(inst_resistors == setpoint_resistor + 1)];

    % Power signal centered at peak resistor from polynomial fit
    polynomial_power_signal = [inst_power(inst_resistors == polynomial_resistor - 1); ...
                               inst_power(inst_resistors == polynomial_resistor); ...
                               inst_power(inst_resistors == polynomial_resistor + 1)];

    % Convert from mW to W
    setpoint_power_signal = setpoint_power_signal .* 1E-3;
    polynomial_power_signal = polynomial_power_signal .* 1E-3;
    
    % Calculate velocity
    setpoint_velocity_signal = ((2 * setpoint_power_signal) ./ (rho * A)).^(1/3);
    setpoint_mean_velocity = mean(setpoint_velocity_signal, 'all', 'omitnan');

    polynomial_velocity_signal = ((2 * polynomial_power_signal) ./ (rho * A)).^(1/3);
    polynomial_mean_velocity = mean(polynomial_velocity_signal, 'all', 'omitnan');


    h(row) = nexttile;
    title(sprintf('Row = %1.0f', row))

    % Time-series of incident velocity
    hold on
    set(gca,'xtick',[])
    g = gca;
    g.XAxis.Visible = 'off';
    plot(setpoint_velocity_signal)
    yline(setpoint_mean_velocity, 'color', 'black', 'linewidth', 1, 'linestyle', '--', ...
          'label', sprintf('$u = %1.2f$ m/s', setpoint_mean_velocity), 'Interpreter', 'latex')
    ylim([0, 3])
    hold off

    % Save
    fprintf('Row %1.0f:\nExperimental Incident velocity = %1.3f [m/s]\nPolynomial Incident velocity = %1.3f [m/s]\n', row, setpoint_mean_velocity, polynomial_mean_velocity);
    output.Experimental(row).incident_velocity = setpoint_mean_velocity;
    output.Experimental(row).power_signal = setpoint_power_signal;
    output.Experimental(row).velocity_signal = setpoint_velocity_signal;

    % Save average experimental tip speeds
    output.Experimental(row).tip_speed = avg_tipspeeds(optimal_index);

    output.Polynomial(row).incident_velocity = polynomial_mean_velocity;
    output.Polynomial(row).power_signal = polynomial_power_signal;
    output.Polynomial(row).velocity_signal = polynomial_velocity_signal;

    % Save average polynomial tip speeds
    output.Polynomial(row).tip_speed = avg_tipspeeds(polynomial_index);

    fprintf('Experimental Resistor: %2.0f w/ Index = %2.0f\n', setpoint_resistor, optimal_index)
    fprintf('Experimental Resistor: %2.0f w/ Index = %2.0f\n\n', polynomial_resistor, polynomial_index)

    % For plotting
    experimental_ptmp(row) = setpoint_mean_velocity;
    polynomial_ptmp(row) = polynomial_mean_velocity;
end

linkaxes(h, 'xy')
ylabel(t, 'Incident Velocity [m/s]')


h(5) = nexttile;
hold on
% Experimental
plot([1,2,3,4], experimental_ptmp, 'color', 'red', 'LineWidth', 2, 'DisplayName', 'Experimental')
scatter([1,2,3,4], experimental_ptmp, 50, 'filled', 'MarkerFaceColor', 'red', 'HandleVisibility', 'off')
% Polynomial
plot([1,2,3,4], polynomial_ptmp, 'color', 'blue', 'LineWidth', 2, 'DisplayName', 'Polynomial')
scatter([1,2,3,4], polynomial_ptmp, 50, 'filled', 'MarkerFaceColor', 'blue', 'HandleVisibility', 'off')
hold off
ylim([0, 3])
xlim([0.9, 4.1])
xticks(1:4)
xlabel('Rows')
%%
% Save figure
pause(2)
exportgraphics(ax, fullfile(save_path, strcat(farm_arrangement, '_', farm_spacing, '_IncidentVelocitySignals.png')), ...
               'Resolution', 300)
close all
clear experimental_ptmp

% Save incident velocities to matfile
save(fullfile(save_path, strcat(farm_arrangement, '_', farm_spacing, '_IncidentVelocity.mat')), 'output');
clc; fprintf('Saved incident velocity matfile! :)\n')