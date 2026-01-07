%% Comapre tip speeds across all cases

clc; close all; clear


% Data locations
projet_path = "/Users/zeinsadek/Desktop/Experiments/Offshore/Power";
mat_path = fullfile(projet_path, "Data/Matfiles");

% Which arangment to process and where to save
farm_type = 'FBF';
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

%% Plot tip speed, unnormalized

colors.Inline = parula(length(spacings));
colors.Staggered = cool(length(spacings));
lw = 2;
sz = 50;

% Use the incident velocity determined from the setpoint used in the
% experiments or from the polynomial fit
what_setpoint = 'Polynomial';

clc;
figure('color', 'white')
title([fancy_title, ': Tip Speed'], 'interpreter', 'latex')

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
            tip_speed = data.(arrangement).(caze).(what_setpoint)(row).tip_speed;
            incident_velocity = data.(arrangement).(caze).(what_setpoint)(row).incident_velocity;
            tmp(row) = tip_speed;

            scatter(row, tip_speed, ...
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
            y_all(end+1,1) = data.(arrangement).(caze).(what_setpoint)(row).tip_speed;
        end
    end
end

p = polyfit(x_all, y_all, 1);

% Evaluate fit on a smooth x grid
x_fit = linspace(1,4,10);
y_fit = polyval(p, x_fit);

% Plot the best-fit line (across all points)
% plot(x_fit, y_fit, 'k-', 'LineWidth', 3, 'linestyle', '--', ...
%     'DisplayName', sprintf('$u = %.3f \\cdot Row + %.3f$', p(1), p(2)));
hold off


legend('Interpreter', 'latex', 'box', 'off', 'location', 'northeastoutside')
    
hold off
xlim([0.9, 4.1])
xticks(1:4)
ylim([6, 17])
xlabel('Row #')
ylabel('$R \omega$ [m/s]', 'interpreter', 'latex')


%% Plot tip speed normalized in incident velocity

colors.Inline = parula(length(spacings));
colors.Staggered = cool(length(spacings));
lw = 2;
sz = 50;

% Use the incident velocity determined from the setpoint used in the
% experiments or from the polynomial fit
what_setpoint = 'Polynomial';

clc;
figure('color', 'white')
title([fancy_title, ': Normalized Tip Speed'], 'interpreter', 'latex')

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
            tip_speed = data.(arrangement).(caze).(what_setpoint)(row).tip_speed;
            incident_velocity = data.(arrangement).(caze).(what_setpoint)(row).incident_velocity;
            tmp(row) = tip_speed ./ incident_velocity;

            scatter(row, tip_speed ./ incident_velocity, ...
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
            y_all(end+1,1) = data.(arrangement).(caze).(what_setpoint)(row).tip_speed;
        end
    end
end

p = polyfit(x_all, y_all, 1);

% Evaluate fit on a smooth x grid
x_fit = linspace(1,4,10);
y_fit = polyval(p, x_fit);

% Plot the best-fit line (across all points)
% plot(x_fit, y_fit, 'k-', 'LineWidth', 3, 'linestyle', '--', ...
%     'DisplayName', sprintf('$u = %.3f \\cdot Row + %.3f$', p(1), p(2)));
hold off


legend('Interpreter', 'latex', 'box', 'off', 'location', 'northeastoutside')
    
hold off
xlim([0.9, 4.1])
xticks(1:4)
ylim([4, 7])
xlabel('Row #')
ylabel('$R \omega / u_{i}$', 'interpreter', 'latex')





