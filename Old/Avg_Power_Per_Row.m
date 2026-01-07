%%% Mean Power Per Row (Like from Juliaan's paper)

clear; close all; clc;

main_folder   = "/Users/zeinsadek/Desktop/APS2024_Data/Power_Results/WT60_SX50_AG0/Power_Signal";
figure_folder = fullfile(main_folder, "Figures");
mat_folder    = fullfile(main_folder, "Matfiles");
files         = {'LM0_AK00',...
                 'LM5_AK12',...
                 'LM33_AK12'};

%% Load No Waves to Normalize

% Only center turbine
% no_waves = load(fullfile(mat_folder,'LM0_AK00.mat'));
% no_waves = no_waves.output;
% no_waves_power = mean(no_waves(2).Power, 'omitnan');

% Across entire row
no_waves = load(fullfile(mat_folder,'LM0_AK00.mat'));
no_waves = no_waves.output;
no_waves_row_power = [no_waves(1).Power; no_waves(2).Power; no_waves(3).Power];
no_waves_power = mean(no_waves_row_power, 'omitnan');


%% Average power, center turbines, different wavelengths
% normalized by the first row, no waves

centers     = [2,5,8,11];
norm_powers = zeros(length(centers), length(files));
powers      = zeros(length(centers), length(files));

% Get power values from set point
for t = 1:length(centers)
    for f = 1:length(files)
        data = load(fullfile(mat_folder, [files{f}, '.mat']));
        data = data.output;

        %%% Averaging only center turbine
        % data = data(centers(t)).Power;
        % powers(t,f) = mean(data, 'omitnan') / no_waves_power;

        %%% Averaging across entire row
        center = centers(t);
        row_data = [data(center - 1).Power; data(center).Power; data(center + 1).Power];
        norm_powers(t,f) = mean(row_data, 'omitnan') / no_waves_power;
        powers(t,f) = mean(row_data, 'omitnan');

    end
end

%% Power Across Different Rows

ax = figure();
bar(["Row 1"; "Row 2"; "Row 3"; "Row 4"], norm_powers)
legend('No Waves', '$H = 1.0$', '$H = 1.5$', 'Interpreter', 'latex')
ylim([0, 1.1])
ylabel('$\bar{P} / \bar{P}_{Row 1, No Waves}$', 'Interpreter', 'latex')
% exportgraphics(ax, fullfile(figure_folder, 'Relative_Normalized_Power.png'), 'Resolution', 200)

%% Power for Only Row 3

ax = figure();
b = bar(["No Waves", "H = 1.0", "H = 1.5"], norm_powers(3,:));
b(1).Labels = round(b(1).YData, 3);
ylim([0. 0.4])
ylabel('$\bar{P} / \bar{P}_{Row 1, No Waves}$', 'Interpreter', 'latex')

b.FaceColor = 'flat';
b.CData(1,:) = [0.00, 0.44, 0.74];
b.CData(2,:) = [0.85, 0.32, 0.10];
b.CData(3,:) = [0.92, 0.69, 0.12];

exportgraphics(ax, fullfile(figure_folder, 'Relative_Normalized_Power_Row3.png'), 'Resolution', 200)


%% Aggregate Power

summed_power = sum(powers, 1);
summed_power = summed_power / summed_power(1,1);

ax = figure(Position=[200,200,300,500]);
b = bar(["No Waves", "H = 1.0", "H = 1.5"], summed_power);

% Label value on top of chart
b(1).Labels = round(b(1).YData, 3);

ylim([0,1.1])
ylabel("Normalized Aggregate Farm Power")
% exportgraphics(ax, fullfile(figure_folder, 'Aggregate_Normalized_Power.png'), 'Resolution', 200)











