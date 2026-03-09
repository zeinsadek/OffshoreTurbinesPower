%% Looking at spectral decomposition of cross-correlation of power
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
% PARSEVAL VERIFICATION DIAGNOSTIC
% Run this section to verify the function is working correctly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Test case
farm_spacing = 'SX50';
wave = 'LM5_AK12';

A = power.(farm_spacing).(wave)(2).Power;
B = power.(farm_spacing).(wave)(5).Power;
n = min(numel(A), numel(B));
A = A(1:n); B = B(1:n);

% Prepare signals (same preprocessing as in xcorr_band_partitioned)
A = A(:); B = B(:);
A = A - mean(A, 'omitnan');
B = B - mean(B, 'omitnan');
A = fillmissing(A, 'linear', 'EndValues', 'nearest');
B = fillmissing(B, 'linear', 'EndValues', 'nearest');

% Define bands that span the full spectrum (no gaps!)
fs = 30;
bands_test.LF   = [0, 0.5];
bands_test.WF   = [0.5, 1.5];
bands_test.HF   = [1.5, fs/2];   % Up to Nyquist

% Compute band-partitioned cross-correlation
out = xcorr_band_partitioned(A, B, fs, bands_test);

%% === TIME-DOMAIN REFERENCE VALUES ===
var_A_time = var(A);
var_B_time = var(B);
cov_AB_time = mean(A .* B);  % Covariance (since mean-subtracted)
rho_AB_time = cov_AB_time / sqrt(var_A_time * var_B_time);

%% === FREQUENCY-DOMAIN VALUES FROM DIAGNOSTICS ===
f = out.diagnostics.f;
Sxx = out.diagnostics.Sxx;
Syy = out.diagnostics.Syy;
Sxy = out.diagnostics.Sxy;
df = out.diagnostics.df;

% Integrate spectra (Parseval's theorem)
var_A_freq = sum(Sxx) * df;
var_B_freq = sum(Syy) * df;
cov_AB_freq = sum(real(Sxy)) * df;  % Real part of CPSD integrates to covariance
rho_AB_freq = cov_AB_freq / sqrt(var_A_freq * var_B_freq);

%% === BAND CONTRIBUTIONS ===
band_names_test = fieldnames(bands_test);
num_bands_test = length(band_names_test);

% Accumulators
sum_var_A_bands = 0;
sum_var_B_bands = 0;
sum_cov_AB_bands = 0;

fprintf('\n')
fprintf('=========================================================\n')
fprintf('   PARSEVAL VERIFICATION FOR CROSS-CORRELATION\n')
fprintf('=========================================================\n\n')

% Compute band contributions directly from spectra
for b = 1:num_bands_test
    bname = band_names_test{b};
    f_lo = bands_test.(bname)(1);
    f_hi = bands_test.(bname)(2);
    
    % Frequency indices
    idx = (f >= f_lo) & (f < f_hi);
    
    % Band-integrated quantities
    var_A_band = sum(Sxx(idx)) * df;
    var_B_band = sum(Syy(idx)) * df;
    cov_AB_band = sum(real(Sxy(idx))) * df;
    
    % Accumulate
    sum_var_A_bands = sum_var_A_bands + var_A_band;
    sum_var_B_bands = sum_var_B_bands + var_B_band;
    sum_cov_AB_bands = sum_cov_AB_bands + cov_AB_band;
    
    % Store for table
    band_var_A(b) = var_A_band;
    band_var_B(b) = var_B_band;
    band_cov_AB(b) = cov_AB_band;
end

%% === DISPLAY RESULTS ===

fprintf('--- VARIANCE OF SIGNAL A (Turbine Row 1) ---\n')
fprintf('  Time-domain:           %.6e\n', var_A_time)
fprintf('  Frequency-domain:      %.6e\n', var_A_freq)
fprintf('  Error:                 %.4f%%\n', 100 * abs(var_A_freq - var_A_time) / var_A_time)
fprintf('  Sum of bands:          %.6e\n', sum_var_A_bands)
fprintf('  Bands/Total:           %.4f%%\n\n', 100 * sum_var_A_bands / var_A_freq)

fprintf('--- VARIANCE OF SIGNAL B (Turbine Row 2) ---\n')
fprintf('  Time-domain:           %.6e\n', var_B_time)
fprintf('  Frequency-domain:      %.6e\n', var_B_freq)
fprintf('  Error:                 %.4f%%\n', 100 * abs(var_B_freq - var_B_time) / var_B_time)
fprintf('  Sum of bands:          %.6e\n', sum_var_B_bands)
fprintf('  Bands/Total:           %.4f%%\n\n', 100 * sum_var_B_bands / var_B_freq)

fprintf('--- COVARIANCE (A, B) ---\n')
fprintf('  Time-domain:           %.6e\n', cov_AB_time)
fprintf('  Frequency-domain:      %.6e\n', cov_AB_freq)
fprintf('  Error:                 %.4f%%\n', 100 * abs(cov_AB_freq - cov_AB_time) / abs(cov_AB_time + eps))
fprintf('  Sum of bands:          %.6e\n', sum_cov_AB_bands)
fprintf('  Bands/Total:           %.4f%%\n\n', 100 * sum_cov_AB_bands / cov_AB_freq)

fprintf('--- CORRELATION COEFFICIENT ---\n')
fprintf('  Time-domain (direct):  %.6f\n', rho_AB_time)
fprintf('  Frequency-domain:      %.6f\n', rho_AB_freq)
fprintf('  xcorr (zero-lag):      %.6f\n', out.full.rho_max)
fprintf('\n')

%% === PER-BAND BREAKDOWN TABLE ===

fprintf('=========================================================\n')
fprintf('   PER-BAND CONTRIBUTIONS\n')
fprintf('=========================================================\n\n')
fprintf('%-8s %12s %12s %12s %12s %12s %12s\n', ...
    'Band', 'f_range', 'Var(A)', 'Var(B)', 'Cov(A,B)', 'rho_band', '|rho|_band')
fprintf('%-8s %12s %12s %12s %12s %12s %12s\n', ...
    '----', '-------', '------', '------', '--------', '--------', '----------')

for b = 1:num_bands_test
    bname = band_names_test{b};
    f_range_str = sprintf('[%.1f,%.1f]', bands_test.(bname)(1), bands_test.(bname)(2));
    
    % Get rho_band from function output
    rho_band = out.(bname).rho_band;
    rho_band_mag = out.(bname).rho_band_mag;
    
    fprintf('%-8s %12s %12.2e %12.2e %12.2e %+12.4f %12.4f\n', ...
        bname, f_range_str, band_var_A(b), band_var_B(b), band_cov_AB(b), rho_band, rho_band_mag)
end

fprintf('\n%-8s %12s %12.2e %12.2e %12.2e\n', ...
    'SUM', '', sum_var_A_bands, sum_var_B_bands, sum_cov_AB_bands)
fprintf('%-8s %12s %12.2e %12.2e %12.2e\n', ...
    'TOTAL', '(freq)', var_A_freq, var_B_freq, cov_AB_freq)

%% === FRACTIONAL CONTRIBUTIONS ===

fprintf('\n')
fprintf('=========================================================\n')
fprintf('   FRACTIONAL CONTRIBUTIONS (%%)\n')
fprintf('=========================================================\n\n')
fprintf('%-8s %15s %15s %15s\n', 'Band', 'frac_Var(A)', 'frac_Var(B)', 'frac_Cov(A,B)')
fprintf('%-8s %15s %15s %15s\n', '----', '-----------', '-----------', '-------------')

for b = 1:num_bands_test
    bname = band_names_test{b};
    frac_A = 100 * band_var_A(b) / var_A_freq;
    frac_B = 100 * band_var_B(b) / var_B_freq;
    frac_cov = 100 * band_cov_AB(b) / cov_AB_freq;
    
    fprintf('%-8s %14.1f%% %14.1f%% %14.1f%%\n', bname, frac_A, frac_B, frac_cov)
end
fprintf('%-8s %14.1f%% %14.1f%% %14.1f%%\n', 'TOTAL', ...
    100 * sum_var_A_bands / var_A_freq, ...
    100 * sum_var_B_bands / var_B_freq, ...
    100 * sum_cov_AB_bands / cov_AB_freq)

%% === DIAGNOSTIC PLOT ===

figure('Color', 'white', 'Position', [100, 100, 1200, 800])
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact')
sgtitle('Parseval Verification: Band-Partitioned Cross-Correlation', 'FontWeight', 'bold')

band_colors = {'#3498db', '#e74c3c', '#2ecc71'};

% PSD of A
nexttile
semilogy(f, Sxx, 'k', 'LineWidth', 1.2)
hold on
for b = 1:num_bands_test
    idx = (f >= bands_test.(band_names_test{b})(1)) & (f < bands_test.(band_names_test{b})(2));
    area(f(idx), Sxx(idx), 'FaceColor', band_colors{b}, 'FaceAlpha', 0.4, 'EdgeColor', 'none')
end
hold off
xlabel('Frequency [Hz]')
ylabel('S_{AA} [units²/Hz]')
title(sprintf('PSD of A: Var_{time}=%.2e, Var_{freq}=%.2e', var_A_time, var_A_freq))
xlim([0, 5])
grid on

% PSD of B
nexttile
semilogy(f, Syy, 'k', 'LineWidth', 1.2)
hold on
for b = 1:num_bands_test
    idx = (f >= bands_test.(band_names_test{b})(1)) & (f < bands_test.(band_names_test{b})(2));
    area(f(idx), Syy(idx), 'FaceColor', band_colors{b}, 'FaceAlpha', 0.4, 'EdgeColor', 'none')
end
hold off
xlabel('Frequency [Hz]')
ylabel('S_{BB} [units²/Hz]')
title(sprintf('PSD of B: Var_{time}=%.2e, Var_{freq}=%.2e', var_B_time, var_B_freq))
xlim([0, 5])
grid on

% Cross-spectral density (real part)
nexttile
plot(f, real(Sxy), 'k', 'LineWidth', 1.2)
hold on
for b = 1:num_bands_test
    idx = (f >= bands_test.(band_names_test{b})(1)) & (f < bands_test.(band_names_test{b})(2));
    area(f(idx), real(Sxy(idx)), 'FaceColor', band_colors{b}, 'FaceAlpha', 0.4, 'EdgeColor', 'none')
end
yline(0, '--', 'Color', [0.5, 0.5, 0.5])
hold off
xlabel('Frequency [Hz]')
ylabel('Re\{S_{AB}\} [units²/Hz]')
title(sprintf('CPSD (Real): Cov_{time}=%.2e, Cov_{freq}=%.2e', cov_AB_time, cov_AB_freq))
xlim([0, 5])
grid on

% Coherence
nexttile
plot(f, out.diagnostics.Cxy, 'k', 'LineWidth', 1.2)
hold on
for b = 1:num_bands_test
    idx = (f >= bands_test.(band_names_test{b})(1)) & (f < bands_test.(band_names_test{b})(2));
    area(f(idx), out.diagnostics.Cxy(idx), 'FaceColor', band_colors{b}, 'FaceAlpha', 0.4, 'EdgeColor', 'none')
end
hold off
xlabel('Frequency [Hz]')
ylabel('C_{AB} (Coherence)')
title('Magnitude-Squared Coherence')
xlim([0, 5])
ylim([0, 1])
grid on

% Bar chart of band contributions
nexttile
bar_data = [band_var_A' / var_A_freq, band_var_B' / var_B_freq, band_cov_AB' / cov_AB_freq] * 100;
b_handle = bar(bar_data);
for i = 1:3
    b_handle(i).FaceColor = 'flat';
end
set(gca, 'XTickLabel', band_names_test)
ylabel('Fraction of Total (%)')
legend({'Var(A)', 'Var(B)', 'Cov(A,B)'}, 'Location', 'best')
title('Band Contributions')
grid on

% Band correlation coefficients
nexttile
rho_bands = zeros(num_bands_test, 1);
rho_bands_mag = zeros(num_bands_test, 1);
for b = 1:num_bands_test
    rho_bands(b) = out.(band_names_test{b}).rho_band;
    rho_bands_mag(b) = out.(band_names_test{b}).rho_band_mag;
end
bar_handle = bar([rho_bands, rho_bands_mag]);
bar_handle(1).FaceColor = [0.2, 0.4, 0.8];
bar_handle(2).FaceColor = [0.8, 0.4, 0.2];
set(gca, 'XTickLabel', band_names_test)
ylabel('\rho')
legend({'\rho_{band}', '|\rho|_{band}'}, 'Location', 'best')
title(sprintf('Band Correlations (Full: \\rho = %.3f)', rho_AB_time))
yline(rho_AB_time, '--k', 'LineWidth', 1.5)
grid on

%% === SUMMARY PASS/FAIL ===

fprintf('\n')
fprintf('=========================================================\n')
fprintf('   PARSEVAL VERIFICATION SUMMARY\n')
fprintf('=========================================================\n\n')

tol = 5;  % Tolerance in percent

err_var_A = 100 * abs(var_A_freq - var_A_time) / var_A_time;
err_var_B = 100 * abs(var_B_freq - var_B_time) / var_B_time;
err_cov = 100 * abs(cov_AB_freq - cov_AB_time) / abs(cov_AB_time + eps);
coverage_A = 100 * sum_var_A_bands / var_A_freq;
coverage_B = 100 * sum_var_B_bands / var_B_freq;
coverage_cov = 100 * sum_cov_AB_bands / cov_AB_freq;

fprintf('CHECK 1: Var(A) time vs freq        Error: %5.2f%%  [%s]\n', ...
    err_var_A, pass_fail(err_var_A < tol))
fprintf('CHECK 2: Var(B) time vs freq        Error: %5.2f%%  [%s]\n', ...
    err_var_B, pass_fail(err_var_B < tol))
fprintf('CHECK 3: Cov(A,B) time vs freq      Error: %5.2f%%  [%s]\n', ...
    err_cov, pass_fail(err_cov < tol))
fprintf('CHECK 4: Bands cover Var(A)         Coverage: %5.1f%%  [%s]\n', ...
    coverage_A, pass_fail(coverage_A > 99))
fprintf('CHECK 5: Bands cover Var(B)         Coverage: %5.1f%%  [%s]\n', ...
    coverage_B, pass_fail(coverage_B > 99))
fprintf('CHECK 6: Bands cover Cov(A,B)       Coverage: %5.1f%%  [%s]\n', ...
    coverage_cov, pass_fail(coverage_cov > 99))

fprintf('\n')


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BAND-PARTITIONED CROSS-CORRELATION ANALYSIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
fs = 30;  % Hz

% Define frequency bands
% Adjust these based on your wave frequencies and expected wake dynamics
bands.LF = [0, 0.5];           % Sub-wave frequencies (wake meandering, etc.)
bands.WF = [0.5, 1.5];         % Primary wave band (covers your LM2-LM5 range)
bands.HF = [1.5, fs/2];        % Higher harmonics, turbulence (up to Nyquist)

% Specifying the 'fixed' turbine row
centers = [2, 5, 8, 11];
fixed_row = 1;

% Determine waked turbines
waked_turbines = centers(fixed_row + 1:end);
num_waked_turbines = length(waked_turbines);

% Plot settings
wave_steepnesses = [0.06, 0.09, 0.12];
wavelengths = [5, 4, 3, 2];
steepness_alpha = [0.3, 0.6, 1];
sz = 100;
spacing_shapes = {'o', 'diamond', '^', 'v', 'square'};
wave_colors = {'#EC4E20', '#FF9505', '#4C4B63', '#ABA8B2'};

band_names = fieldnames(bands);
num_bands = length(band_names);

% Create figure with bands as columns
close all
figure('color', 'white', 'Position', [100, 100, 1400, 400])
t = tiledlayout(num_waked_turbines, num_bands + 1, 'TileSpacing', 'compact');
sgtitle('Band-partitioned correlation: of Power')

% Storage for results
results = struct();

% Loop through waked turbines (rows of figure)
for c = 1:num_waked_turbines
    reference_turbine = centers(fixed_row);
    correlating_turbine = waked_turbines(c);
    row_pair = sprintf('Row%d_to_Row%d', fixed_row, ceil(correlating_turbine / 3));
    
    % First column: full-band correlation
    h_full(c) = nexttile;
    hold on
    title(sprintf('Row %d→%d (Full)', fixed_row, ceil(correlating_turbine / 3)))
    
    % Loop through spacings and waves
    for s = 1:length(farm_spacings)
        farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
        
        for st = 1:length(wave_steepnesses)
            steep = compose('%02d', round(100 * wave_steepnesses(st)));
            
            for w = 1:length(wavelengths)
                wave = ['LM', num2str(wavelengths(w)), '_AK', steep{1}];
                harmonic_ratio = farm_spacings(s) / wavelengths(w);
                
                % Get signals
                A = power.(farm_spacing).(wave)(reference_turbine).Power;
                B = power.(farm_spacing).(wave)(correlating_turbine).Power;
                n = min(numel(A), numel(B));
                A = A(1:n); B = B(1:n);
                
                % Compute band-partitioned correlation
                out = xcorr_band_partitioned(A, B, fs, bands);
                
                % Store results
                results.(farm_spacing).(wave).(row_pair) = out;
                
                % Plot full-band
                scatter(harmonic_ratio, out.full.rho_abs_max, sz, spacing_shapes{s}, 'filled', ...
                    'MarkerFaceColor', wave_colors{w}, 'MarkerFaceAlpha', steepness_alpha(st))
            end
        end
    end
    hold off
    
    % Band columns
    for b = 1:num_bands
        bname = band_names{b};
        h_band(c, b) = nexttile;
        hold on
        title(sprintf('$\\rho_{%s}$ [%.1f - %.1f Hz]', bname, bands.(bname)(1), bands.(bname)(2)), 'Interpreter', 'latex')
        
        for s = 1:length(farm_spacings)
            farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
            
            for st = 1:length(wave_steepnesses)
                steep = compose('%02d', round(100 * wave_steepnesses(st)));
                
                for w = 1:length(wavelengths)
                    wave = ['LM', num2str(wavelengths(w)), '_AK', steep{1}];
                    harmonic_ratio = farm_spacings(s) / wavelengths(w);
                    
                    % Retrieve stored result
                    out = results.(farm_spacing).(wave).(row_pair);
                    
                    % Plot band correlation magnitude
                    %%% Rho_band_mag represents how synchronized turbines
                    %%% are at a specific frequency scale
                    scatter(harmonic_ratio, out.(bname).rho_band_mag, sz, spacing_shapes{s}, 'filled', ...
                        'MarkerFaceColor', wave_colors{w}, 'MarkerFaceAlpha', steepness_alpha(st))
                end
            end
        end
        hold off
    end
end

% Link axes and format
linkaxes([h_full, h_band(:)'], 'xy')
xlim([0.4, 2.6])
ylim([0, 1])
xlabel(t, '$S_x / \lambda$', 'interpreter', 'latex')
ylabel(t, '$|\rho|$', 'interpreter', 'latex')








%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function out = xcorr_band_partitioned(x, y, fs, bands, varargin)
% XCORR_BAND_PARTITIONED  Parseval-consistent band-partitioned cross-correlation
%
%   out = xcorr_band_partitioned(x, y, fs, bands)
%
%   Computes cross-correlation metrics partitioned by frequency band using
%   MANUAL FFT-based cross-spectral analysis. This approach guarantees
%   Parseval consistency by avoiding the normalization issues in cpsd.
%
%   INPUTS:
%       x, y    - Time series (same length, will be trimmed if not)
%       fs      - Sampling frequency [Hz]
%       bands   - Struct with fields defining frequency bands, e.g.:
%                   bands.low  = [0.01, 0.5];   % [f_min, f_max] in Hz
%                   bands.wave = [0.5, 3.0];
%                   bands.high = [3.0, 15];
%
%   OUTPUTS:
%       out.full        - Full-band metrics (rho_max, tau_max, etc.)
%       out.parseval    - Parseval verification metrics
%       out.<bandname>  - Per-band metrics
%       out.diagnostics - Spectra and frequency vector for plotting
%
%   THEORY:
%       Parseval's theorem: Var(x) = integral of Sxx(f) df
%       Wiener-Khinchin:    Cov(x,y) = integral of Re{Sxy(f)} df
%       Band correlation:   rho_band = Cov_band / sqrt(Var_x_band * Var_y_band)
%
%   NOTE: Uses manual FFT computation to ensure Parseval consistency.
%         The built-in cpsd function has normalization that doesn't
%         preserve covariance when integrated.

% Prepare signals
x = x(:); y = y(:);
n = min(length(x), length(y));
x = x(1:n); y = y(1:n);

% Remove mean
x = x - mean(x, 'omitnan');
y = y - mean(y, 'omitnan');

% Handle NaNs
x = fillmissing(x, 'linear', 'EndValues', 'nearest');
y = fillmissing(y, 'linear', 'EndValues', 'nearest');

% ===================================================================
% MANUAL FFT-BASED SPECTRAL ESTIMATION (Parseval-consistent)
% ===================================================================
% Using rectangular window (no taper) and direct FFT ensures that
% Parseval's theorem is satisfied exactly.

nfft = 2^nextpow2(n);

% Compute FFT
X = fft(x, nfft);
Y = fft(y, nfft);

% Two-sided power spectral density
% Normalization: divide by (fs * n) to get density units [units^2/Hz]
Sxx_twosided = (abs(X).^2) / (fs * n);
Syy_twosided = (abs(Y).^2) / (fs * n);
Sxy_twosided = (X .* conj(Y)) / (fs * n);

% Frequency vector (two-sided)
f_twosided = (0:nfft-1)' * fs / nfft;

% Convert to one-sided spectrum (for positive frequencies only)
% This doubles the power at all frequencies except DC and Nyquist
n_onesided = nfft/2 + 1;
f = f_twosided(1:n_onesided);

Sxx = Sxx_twosided(1:n_onesided);
Syy = Syy_twosided(1:n_onesided);
Sxy = Sxy_twosided(1:n_onesided);

% Double non-DC, non-Nyquist components for one-sided spectrum
Sxx(2:end-1) = 2 * Sxx(2:end-1);
Syy(2:end-1) = 2 * Syy(2:end-1);
Sxy(2:end-1) = 2 * Sxy(2:end-1);

df = fs / nfft;

% ===================================================================
% PARSEVAL VERIFICATION
% ===================================================================
var_x_freq = sum(Sxx) * df;
var_y_freq = sum(Syy) * df;
cov_xy_freq = sum(real(Sxy)) * df;

var_x_time = var(x);
var_y_time = var(y);
cov_xy_time = mean(x .* y);
rho_xy_time = cov_xy_time / sqrt(var_x_time * var_y_time);

% Store Parseval diagnostics
out.parseval.var_x_time = var_x_time;
out.parseval.var_x_freq = var_x_freq;
out.parseval.var_x_error_pct = 100 * abs(var_x_freq - var_x_time) / var_x_time;

out.parseval.var_y_time = var_y_time;
out.parseval.var_y_freq = var_y_freq;
out.parseval.var_y_error_pct = 100 * abs(var_y_freq - var_y_time) / var_y_time;

out.parseval.cov_xy_time = cov_xy_time;
out.parseval.cov_xy_freq = cov_xy_freq;
out.parseval.cov_xy_error_pct = 100 * abs(cov_xy_freq - cov_xy_time) / (abs(cov_xy_time) + eps);

out.parseval.rho_time = rho_xy_time;
out.parseval.rho_freq = cov_xy_freq / sqrt(var_x_freq * var_y_freq);

% ===================================================================
% COHERENCE AND PHASE
% ===================================================================
Cxy = abs(Sxy).^2 ./ (Sxx .* Syy);
Cxy(isnan(Cxy) | isinf(Cxy)) = 0;
phi = angle(Sxy);

% ===================================================================
% FULL-BAND METRICS
% ===================================================================
% Time-domain cross-correlation for reference
maxLag = round(10 * fs);
[r_full, lags_full] = xcorr(x, y, maxLag, 'coeff');
tau_full = lags_full / fs;
[~, idx_max] = max(abs(r_full));

out.full.rho_max = r_full(idx_max);
out.full.rho_abs_max = abs(r_full(idx_max));
out.full.tau_max = tau_full(idx_max);
out.full.coh_mean = mean(Cxy);

% Frequency-domain correlation (should match time-domain)
out.full.rho_freq = cov_xy_freq / sqrt(var_x_freq * var_y_freq);

% ===================================================================
% BAND-PARTITIONED METRICS
% ===================================================================
band_names = fieldnames(bands);
sum_var_x = 0;
sum_var_y = 0;
sum_cov_xy = 0;

for b = 1:length(band_names)
    bname = band_names{b};
    f_lo = bands.(bname)(1);
    f_hi = bands.(bname)(2);
    
    % Find frequency indices in band
    idx_band = (f >= f_lo) & (f < f_hi);
    
    if sum(idx_band) < 2
        warning('Band %s has fewer than 2 frequency bins', bname);
        out.(bname) = make_empty_struct();
        continue;
    end
    
    % Band-limited spectra
    Sxx_band = Sxx(idx_band);
    Syy_band = Syy(idx_band);
    Sxy_band = Sxy(idx_band);
    Cxy_band = Cxy(idx_band);
    phi_band = phi(idx_band);
    f_band = f(idx_band);
    
    % Band-integrated quantities (Parseval-consistent)
    var_x_band = sum(Sxx_band) * df;
    var_y_band = sum(Syy_band) * df;
    cov_xy_band = sum(real(Sxy_band)) * df;
    
    % Accumulate for coverage check
    sum_var_x = sum_var_x + var_x_band;
    sum_var_y = sum_var_y + var_y_band;
    sum_cov_xy = sum_cov_xy + cov_xy_band;
    
    % Band correlation coefficient
    denom = sqrt(var_x_band * var_y_band);
    if denom > 0
        rho_band = cov_xy_band / denom;
    else
        rho_band = NaN;
    end
    
    % Band power fractions
    psd_frac_x = var_x_band / var_x_freq;
    psd_frac_y = var_y_band / var_y_freq;
    if abs(cov_xy_freq) > eps
        cpsd_frac = cov_xy_band / cov_xy_freq;
    else
        cpsd_frac = NaN;
    end
    
    % Coherence statistics in band
    coh_mean = mean(Cxy_band);
    [coh_max, idx_peak_coh] = max(Cxy_band);
    
    % Coherence-weighted mean phase
    if sum(Cxy_band) > 0
        weights = Cxy_band / sum(Cxy_band);
        phase_mean = sum(weights .* phi_band);
    else
        phase_mean = NaN;
    end
    
    % Equivalent time lag from phase at peak coherence frequency
    f_peak = f_band(idx_peak_coh);
    phi_peak = phi_band(idx_peak_coh);
    if f_peak > 0
        tau_equiv = phi_peak / (2 * pi * f_peak);
    else
        tau_equiv = NaN;
    end
    
    % Store results
    out.(bname).rho_band = rho_band;
    out.(bname).rho_band_mag = abs(rho_band);
    out.(bname).var_x = var_x_band;
    out.(bname).var_y = var_y_band;
    out.(bname).cov_xy = cov_xy_band;
    out.(bname).coh_mean = coh_mean;
    out.(bname).coh_max = coh_max;
    out.(bname).phase_mean = phase_mean;
    out.(bname).tau_equiv = tau_equiv;
    out.(bname).f_peak_coh = f_peak;
    out.(bname).psd_frac_x = psd_frac_x;
    out.(bname).psd_frac_y = psd_frac_y;
    out.(bname).cpsd_frac = cpsd_frac;
end

% Band coverage check
out.parseval.bands_cover_var_x_pct = 100 * sum_var_x / var_x_freq;
out.parseval.bands_cover_var_y_pct = 100 * sum_var_y / var_y_freq;
out.parseval.bands_cover_cov_xy_pct = 100 * sum_cov_xy / cov_xy_freq;

% ===================================================================
% STORE DIAGNOSTICS
% ===================================================================
out.diagnostics.f = f;
out.diagnostics.Sxx = Sxx;
out.diagnostics.Syy = Syy;
out.diagnostics.Sxy = Sxy;
out.diagnostics.Cxy = Cxy;
out.diagnostics.phi = phi;
out.diagnostics.df = df;
out.diagnostics.nfft = nfft;
out.diagnostics.n_samples = n;

end

function s = make_empty_struct()
    s.rho_band = NaN; s.rho_band_mag = NaN;
    s.var_x = NaN; s.var_y = NaN; s.cov_xy = NaN;
    s.coh_mean = NaN; s.coh_max = NaN;
    s.phase_mean = NaN; s.tau_equiv = NaN; s.f_peak_coh = NaN;
    s.psd_frac_x = NaN; s.psd_frac_y = NaN; s.cpsd_frac = NaN;
end

function str = pass_fail(condition)
    if condition
        str = 'PASS';
    else
        str = 'FAIL';
    end
end