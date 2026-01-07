%% Comapre incident velocity across all cases

clc; close all; clear


% Data locations
projet_path = "/Users/zeinsadek/Desktop/Experiments/Offshore/Power";
mat_path = fullfile(projet_path, "Data/Matfiles");

% Which arangment to process and where to save
farm_type = 'FWF';
arrangements = {'Inline', 'Staggered'};
spacings = [50, 45, 40, 35, 30];

if strcmp(farm_type, 'FWF')
    fancy_title = 'Floating Wind Farm';
elseif strcmp(farm_type, 'FBF')
    fancy_title = 'Fixed-Bottom Wind Farm';
end

% Loop through and load power curve data
for a = 1:length(arrangements)
    arrangement = arrangements{a};
    farm = strcat(farm_type, '_', arrangement);

    for s = 1:length(spacings)
        caze = strcat('WT60_SX', num2str(spacings(s)), '_AG0');
        tmp = load(fullfile(mat_path, farm, caze, 'IncidentVelocity', strcat(farm, '_', caze, '_IncidentVelocity.mat')));
        tmp = tmp.output;

        % Save to data structure
        data.(arrangement).(caze) = tmp;

        clear s
    end

    clear a
end

clear tmp

%% Plot all first row power curves together

colors.Inline = parula(length(spacings));
colors.Staggered = cool(length(spacings));
lw = 2;
sz = 50;

% Use the incident velocity determined from the setpoint used in the
% experiments or from the polynomial fit
what_setpoint = 'Experimental';

clc;
figure('color', 'white')
title(fancy_title, 'interpreter', 'latex')

hold on
    
for a = 1:length(arrangements)
    arrangement = arrangements{a};
    farm = strcat(farm_type, '_', arrangement);

    for s = 1:length(spacings)
        caze = strcat('WT60_SX', num2str(spacings(s)), '_AG0');
        fprintf('%s: %s\n', farm, caze)
        % disp(data.(arrangement).(caze)(row).file)
        % fprintf('\n')

        % Plot
        label = sprintf('%s: $S_x = %1.1fD$', arrangement, spacings(s) / 10);
        for row = 1:4
            tmp(row) = data.(arrangement).(caze).(what_setpoint)(row).incident_velocity;
            scatter(row, data.(arrangement).(caze).(what_setpoint)(row).incident_velocity, ...
                    sz, 'filled', 'MarkerFaceColor', colors.(arrangement)(s,:), 'HandleVisibility', 'off')
        end
        plot(1:4, tmp, 'linewidth', lw, 'color', colors.(arrangement)(s,:), 'DisplayName', label)
        
        clear s
    end
    clear a
end


% Fitting a line to all the curves
x_all = [];
y_all = [];

for a = 1:length(arrangements)
    arrangement = arrangements{a};
    for s = 1:length(spacings)
        caze = strcat('WT60_SX', num2str(spacings(s)), '_AG0');
        for row = 1:4
            x_all(end+1,1) = row;
            y_all(end+1,1) = data.(arrangement).(caze).(what_setpoint)(row).incident_velocity;
        end
    end
end

p = polyfit(x_all, y_all, 1);

% Evaluate fit on a smooth x grid
x_fit = linspace(1,4,10);
y_fit = polyval(p, x_fit);

% Plot the best-fit line (across all points)
plot(x_fit, y_fit, 'k-', 'LineWidth', 3, 'linestyle', '--', ...
    'DisplayName', sprintf('$u = %.3f \\cdot Row + %.3f$', p(1), p(2)));
hold off


legend('Interpreter', 'latex', 'box', 'off', 'location', 'northeastoutside')
    
hold off
xlim([0.9, 4.1])
xticks(1:4)
ylim([0, 3])
xlabel('Row #')
ylabel('Incident Velocity [m/s]')


%% Look at incident velocity seen by 2nd row in the inline cases as a function of streamwise spacing

row = 1;

lw = 2;
sz = 100;

% Use the incident velocity determined from the setpoint used in the
% experiments or from the polynomial fit
what_setpoint = 'Experimental';

clc;
figure('color', 'white')
% t = tiledlayout(1,4);
title(sprintf('%s: Inline Row %1.0f', fancy_title, row), 'interpreter', 'latex')

hold on
arrangement = 'Inline';
farm = strcat(farm_type, '_', arrangement);


for s = 1:length(spacings)
    streamwise_spacing = spacings(s) / 10;
    caze = strcat('WT60_SX', num2str(spacings(s)), '_AG0');
    fprintf('%s: %s\n', farm, caze)

    % Plot
    label = sprintf('%s: $S_x = %1.1fD$', arrangement, spacings(s) / 10);
    scatter(streamwise_spacing, data.(arrangement).(caze).(what_setpoint)(row).incident_velocity, ...
            sz, 'filled', 'MarkerFaceColor', colors.(arrangement)(s,:), 'DisplayName', label)
    
    tmp(s) = data.(arrangement).(caze).(what_setpoint)(row).incident_velocity;
    clear s
end

b = plot(spacings / 10, tmp, 'linewidth', 2, 'color', 'black', 'HandleVisibility', 'off');
uistack(b, 'bottom');

% Poly fit
p = polyfit(spacings / 10, tmp, 1);
x_fit = 3:0.1:5;
y_fit = polyval(p, x_fit);
fprintf('$u = %.3f \\cdot Row + %.3f$\n', p(1), p(2))

% Plot the best-fit line (across all points)
% P = plot(x_fit, y_fit, 'k-', 'LineWidth', 3, 'linestyle', '--', 'HandleVisibility', 'off');
% P.Color(4) = 1;

hold off
xlim([2.8, 5.2])
if row == 2
    ylim([1.3, 1.8])
elseif row == 1 & strcmp(farm_type, 'FWF')
    ylim([2.3, 2.6])
end

ylim([2.0, 2.6])
xticks(3:0.5:5)
legend('Interpreter', 'latex', 'box', 'off', 'location', 'southwest')
xlabel('Streamwise Farm Spacing: $S_x$ [D]', 'interpreter', 'latex')
ylabel('Incident Velocity [m/s]')