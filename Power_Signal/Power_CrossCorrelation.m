%% Looking at cross-correlation of power
% Zein Sadek

clear; close all; clc;
addpath("/Users/zeinsadek/Documents/MATLAB/MatlabFunctions")
addpath("/Users/zeinsadek/Documents/MATLAB/colormaps")

clear; close all; clc;
addpath("/Users/zeinsadek/Documents/MATLAB/MatlabFunctions")
addpath("/Users/zeinsadek/Documents/MATLAB/colormaps")
addpath('/Users/zeinsadek/Documents/MATLAB/colormaps/slanCM')


offshore_path = "/Users/zeinsadek/Desktop/Experiments/Offshore";
power_path = fullfile(offshore_path, "Power/Data/Matfiles");

turbine_type = 'FWF';
farm_arrangement = "Staggered";
turbines = 1:12;

% Name depending on farm type
if strcmp(turbine_type, 'FWF')
    fancy_name = 'Floating Wind Farm';
elseif strcmp(turbine_type, 'FBF')
    fancy_name = 'Fixed-Bottom Farm';
end

% Load all spacings
farm_spacings = [5, 4.5, 4, 3.5, 3];
wave_steepnesses = [0.06, 0.09, 0.12];
wavelengths = [5, 4, 3, 2];

% Generate list of waves
waves = {};
c = 1;
for w = 1:length(wavelengths)
    wavelength = wavelengths(w);
    for st = 1:length(wave_steepnesses)
        wave_steepness = wave_steepnesses(st);
        steep = compose('%02d', round(100 * wave_steepness));
        waves{c} = ['LM', num2str(wavelength), '_AK', steep{1}];
        c = c + 1;
    end
end

clear w wavelength st wave_steepness steep c


% Load powers
for s = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
    caze = strcat("WT60_", farm_spacing, "_AG0");
    fprintf('%s\n', caze)

    for w = 1:length(waves)
        wave = waves{w};

        power_file = fullfile(power_path, strcat(turbine_type, "_", farm_arrangement), caze, strcat(wave, ".mat"));
        tmp = load(power_file);
        power.(farm_spacing).(wave) = tmp.output;
    end
end

clear w wave tmp power_file farm_spacing caze

% Remove nans from signals
clc;
for s = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
    caze = strcat("WT60_", farm_spacing, "_AG0");
    fprintf('%s\n', caze)

    for w = 1:length(waves)
        wave = waves{w};

        for t = 1:length(turbines)
            % turbine = turbines(t);
            power.(farm_spacing).(wave)(t).Power = fillmissing(power.(farm_spacing).(wave)(t).Power, 'spline');
        end
    end
end

clear w wave tmp power_file farm_spacing caze


forcing_frequencies.("LM5")  = 1.4273;
forcing_frequencies.("LM4")  = 1.6075;
forcing_frequencies.("LM33") = 1.7651;
forcing_frequencies.("LM3")  = 1.8617;
forcing_frequencies.("LM25") = 2.0402;
forcing_frequencies.("LM2")  = 2.2813;



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE STD OF EACH POWER STIGNAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
for s = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
    caze = strcat("WT60_", farm_spacing, "_AG0");
    fprintf('%s\n', caze)

    % Loop through waves
    for w = 1:length(waves)
        wave = waves{w};

        % Loop through turbines
        for t = 1:length(turbines)
            % Compute standard deviation
            deviations.(farm_spacing)(t).(wave) = std(power.(farm_spacing).(wave)(t).Power, 0, 'all', 'omitnan');

            if isnan(deviations.(farm_spacing)(t).(wave))
                fprintf('%s: %s Turbine %2.0f\n', caze, wave, t)
            end
        end
    end
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE MEAN OF EACH POWER STIGNAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
for s = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
    caze = strcat("WT60_", farm_spacing, "_AG0");
    fprintf('%s\n', caze)

    % Loop through waves
    for w = 1:length(waves)
        wave = waves{w};

        % Loop through turbines
        for t = 1:length(turbines)
            % Compute standard deviation
            averages.(farm_spacing)(t).(wave) = mean(power.(farm_spacing).(wave)(t).Power, 'all', 'omitnan');

            if isnan(deviations.(farm_spacing)(t).(wave))
                fprintf('%s: %s Turbine %2.0f\n', caze, wave, t)
            end
        end
    end
end



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST CROSS CORRELATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Test cross-correlation
farm_spacing = 'SX50';
wave = 'LM5_AK12';

% Load signals
row1_signal = power.(farm_spacing).(wave)(2).Power;
row2_signal = power.(farm_spacing).(wave)(5).Power;

% Make the same length
n = min(numel(row1_signal), numel(row2_signal));
A = row1_signal(1:n);
B = row2_signal(1:n);

clc;
fs = 30;          % Hz
maxLag_s = 120;    % seconds
out = xcorr_metrics(A, B, fs, maxLag_s);
disp(out)



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTTIG MAX CORRELATION VALUE
% FOR ALL SPACINGS WAVES
% SPECIFYING FIXED ROW AND DOF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
fs = 30;          % Hz
maxLag_s = 10;    % seconds

% Specifying the 'fixed' turbine row and show the max correlation value
% with all other waked rows
centers = [2, 5, 8, 11];
fixed_row = 1;

% Determine waked turbines
waked_turbines = centers(fixed_row + 1:end);
num_waked_turbines = length(waked_turbines);

% Plot things
wave_steepnesses = [0.06, 0.09, 0.12];
wavelengths = [5,4,3,2];
steepness_alpha = [0.3, 0.6, 1];
sz = 100;
spacing_shapes = {'o', 'diamond', '^', 'v', 'square'};
wave_colors = {'#EC4E20', '#FF9505', '#4C4B63', '#ABA8B2'};


clc; close all
figure('color', 'white')
t = tiledlayout(1, num_waked_turbines);
sgtitle('Correlation coefficient of Power')

% Loop through waked turbines
for c = 1:num_waked_turbines

    reference_turbine = centers(fixed_row);
    correlating_turbine = waked_turbines(c);

    h(c) = nexttile;
    title(sprintf('Row %1.0f to Row %1.0f', fixed_row, ceil(correlating_turbine / 3)))
    hold on
    % Loop through spacings
    for s = 1:length(farm_spacings)
        farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
        caze = strcat("WT60_", farm_spacing, "_AG0");
        fprintf('%s\n', caze)
        
        % tmp = tracking.(farm_spacing);
        % waves = fieldnames(tmp);

        % Loop through waves
        for st = 1:length(wave_steepnesses)
            wave_steepness = wave_steepnesses(st);
            steep = compose('%02d', round(100 * wave_steepness));
            disp(steep{1})

            for w = 1:length(wavelengths)
                % Make wave
                wave = ['LM', num2str(wavelengths(w)), '_AK', steep{1}];
                harmonic_ratio = farm_spacings(s) / wavelengths(w);


                % Get signals
                turbine_A_signal = power.(farm_spacing).(wave)(reference_turbine).Power;
                turbine_B_signal = power.(farm_spacing).(wave)(correlating_turbine).Power;

    
                % Make the same length
                n = min(numel(turbine_A_signal), numel(turbine_B_signal));
                A = turbine_A_signal(1:n);
                B = turbine_B_signal(1:n);
    
    
                % Cross-correlate
                out = xcorr_metrics(A, B, fs, maxLag_s);
    
                % out.rho_max ~ largest magnitude XC coefficient
                % out.rho_abs_max ~ abs of largest magnitude XC coefficient
                % out.tau_max ~ time lag at largest peak

                scatter(harmonic_ratio, out.rho_max, sz, spacing_shapes{s}, 'filled', ...
                        'MarkerFaceColor', wave_colors{w}, 'markerfacealpha', steepness_alpha(st))

            end
        end
    end
    xline(0.5:1:2.5, 'linestyle', '--')
    xline(1:1:2, 'linestyle', '-')
    hold off
end

linkaxes(h, 'xy')
xlim([0.4, 2.5])
ylim([-1, 1])
xlabel(t, '$S_x / \lambda$', 'interpreter', 'latex')
ylabel(t, '$\rho_{P}$', 'interpreter', 'latex')






%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTTIG ABSOLUTE VALUE OF MAX CORRELATION VALUE
% FOR ALL SPACINGS WAVES
% SPECIFYING FIXED ROW AND DOF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
fs = 30;          % Hz
maxLag_s = 10;    % seconds

% Specifying the 'fixed' turbine row and show the max correlation value
% with all other waked rows
centers = [2, 5, 8, 11];
fixed_row = 1;

% Determine waked turbines
waked_turbines = centers(fixed_row + 1:end);
num_waked_turbines = length(waked_turbines);

% Plot things
wave_steepnesses = [0.06, 0.09, 0.12];
wavelengths = [5,4,3,2];
steepness_alpha = [0.3, 0.6, 1];
sz = 100;
spacing_shapes = {'o', 'diamond', '^', 'v', 'square'};
wave_colors = {'#EC4E20', '#FF9505', '#4C4B63', '#ABA8B2'};


clc; close all
figure('color', 'white')
t = tiledlayout(1, num_waked_turbines);
sgtitle('Correlation coefficient of Power')

% Loop through waked turbines
for c = 1:num_waked_turbines

    reference_turbine = centers(fixed_row);
    correlating_turbine = waked_turbines(c);

    h(c) = nexttile;
    title(sprintf('Row %1.0f to Row %1.0f', fixed_row, ceil(correlating_turbine / 3)))
    hold on
    % Loop through spacings
    for s = 1:length(farm_spacings)
        farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
        caze = strcat("WT60_", farm_spacing, "_AG0");
        fprintf('%s\n', caze)
        
        % tmp = tracking.(farm_spacing);
        % waves = fieldnames(tmp);

        % Loop through waves
        for st = 1:length(wave_steepnesses)
            wave_steepness = wave_steepnesses(st);
            steep = compose('%02d', round(100 * wave_steepness));
            disp(steep{1})

            for w = 1:length(wavelengths)
                % Make wave
                wave = ['LM', num2str(wavelengths(w)), '_AK', steep{1}];
                harmonic_ratio = farm_spacings(s) / wavelengths(w);


                % Get signals
                turbine_A_signal = power.(farm_spacing).(wave)(reference_turbine).Power;
                turbine_B_signal = power.(farm_spacing).(wave)(correlating_turbine).Power;
                
    
                % Make the same length
                n = min(numel(turbine_A_signal), numel(turbine_B_signal));
                A = turbine_A_signal(1:n);
                B = turbine_B_signal(1:n);
    
    
                % Cross-correlate
                out = xcorr_metrics(A, B, fs, maxLag_s);
    
                % out.rho_max ~ largest magnitude XC coefficient
                % out.rho_abs_max ~ abs of largest magnitude XC coefficient
                % out.tau_max ~ time lag at largest peak

                scatter(harmonic_ratio, out.rho_abs_max, sz, spacing_shapes{s}, 'filled', ...
                        'MarkerFaceColor', wave_colors{w}, 'markerfacealpha', steepness_alpha(st))

            end
        end
    end
    xline(0.5:1:2.5, 'linestyle', '--')
    xline(1:1:2, 'linestyle', '-')
    hold off
end

linkaxes(h, 'xy')
xlim([0.4, 2.5])
ylim([0, 1])
xlabel(t, '$S_x / \lambda$', 'interpreter', 'latex')
ylabel(t, '$| \rho_{P} |$', 'interpreter', 'latex')



















%% Functions

function out = xcorr_metrics(x, y, fs, maxLag_s)
% Returns peak correlation and lag at peak (seconds)

x = x(:); y = y(:);
x = x - mean(x, 'omitnan');
y = y - mean(y, 'omitnan');

% Optional: handle NaNs by simple fill (or remove segments)
x = fillmissing(x,'linear','EndValues','nearest');
y = fillmissing(y,'linear','EndValues','nearest');

maxLag = round(maxLag_s * fs);
[r, lags] = xcorr(x, y, maxLag, 'coeff');
tau = lags / fs;

% Peak magnitude (use abs so anti-correlation counts as strong coupling)
[~, idx] = max(abs(r));
out.rho_max = r(idx);
out.rho_abs_max = abs(r(idx));
out.tau_max = tau(idx);

% Also useful: zero-lag correlation
[~, iz] = min(abs(tau));
out.rho0 = r(iz);
end
