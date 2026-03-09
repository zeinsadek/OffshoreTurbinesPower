%% Looking at mean of power
% Zein Sadek


clear; close all; clc;
addpath("/Users/zeinsadek/Documents/MATLAB/MatlabFunctions")
addpath("/Users/zeinsadek/Documents/MATLAB/colormaps")
addpath('/Users/zeinsadek/Documents/MATLAB/colormaps/slanCM')


offshore_path = "/Users/zeinsadek/Desktop/Experiments/Offshore";
power_path = fullfile(offshore_path, "Power/Data/Matfiles");

turbine_type = 'FWF';
farm_arrangement = "Inline";
turbines = 1:12;

% Name depending on farm type
if strcmp(turbine_type, 'FWF')
    fancy_name = 'Floating Wind Farm'; %#ok<UNRCH>
elseif strcmp(turbine_type, 'FBF')
    fancy_name = 'Fixed-Bottom Farm'; %#ok<UNRCH>
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


    % Load no-wave powers
    power_file = fullfile(power_path, strcat(turbine_type, "_", farm_arrangement), caze, strcat("LM0_AK00.mat"));
    tmp = load(power_file);
    power.(farm_spacing).("LM0_AK00") = tmp.output;

end



clear w wave tmp power_file farm_spacing caze

% Remove nans from signals
clc;
for s = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
    caze = strcat("WT60_", farm_spacing, "_AG0");
    fprintf('%s\n', caze)

    cases = fields(power.(farm_spacing));
    for w = 1:length(cases)
        wave = cases{w};

        for t = 1:length(turbines)
            power.(farm_spacing).(wave)(t).Power = fillmissing(power.(farm_spacing).(wave)(t).Power, 'spline');
        end
    end
end

clear w wave tmp power_file farm_spacing caze


% Remove nans from signals
clc;
for s = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
    caze = strcat("WT60_", farm_spacing, "_AG0");
    fprintf('%s\n', caze)

    waves = fields(power.(farm_spacing));
    for w = 1:length(waves)
        wave = waves{w};
        disp(wave)

        for t = 1:length(turbines)
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
% COMPUTE POWER SPECTRA FOR EACH SIGNAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% PSD settings (adjust these based on your dynamics analysis)
dt = mean(diff(power.SX50.LM5_AK12(1).Time), 'omitnan');
Fs = 1/dt;
window_length = 2048;  % Window length for pwelch - adjust as needed
overlap = window_length/2;  % 50% overlap
nfft = window_length;  % FFT length

% Minimum fraction of valid data points required
min_valid_fraction = 0.5;  % Require at least 50% non-NaN data

clc;
fprintf('Computing power spectra...\n')

for s = 1:length(farm_spacings)
    farm_spacing = ['SX', num2str(farm_spacings(s) * 10)];
    caze = strcat("WT60_", farm_spacing, "_AG0");
    fprintf('%s\n', caze)
    
    waves_list = fields(power.(farm_spacing));
    
    % Loop through waves (including no-wave case)
    for w = 1:length(waves_list)
        wave = waves_list{w};
        
        % Loop through turbines
        for t = 1:length(turbines)
            % Get power signal
            power_signal = power.(farm_spacing).(wave)(t).Power;
            
            % Check for NaN content
            nan_fraction = sum(isnan(power_signal)) / length(power_signal);
            
            if nan_fraction > (1 - min_valid_fraction)
                % Too many NaNs - skip this signal
                fprintf('  Skipping %s Turbine %d (%.1f%% NaN)\n', ...
                    wave, t, nan_fraction * 100);
                
                % Store empty/NaN results to maintain structure
                spectra.(farm_spacing)(t).(wave).Pxx = NaN;
                spectra.(farm_spacing)(t).(wave).f = NaN;
                spectra.(farm_spacing)(t).(wave).valid = false;
                continue
            end
            
            % Remove mean (detrend)
            power_signal = power_signal - mean(power_signal, 'omitnan');
            
            % Additional check: ensure we have enough valid data after detrending
            valid_data = power_signal(~isnan(power_signal));
            if length(valid_data) < window_length
                fprintf('  Skipping %s Turbine %d (insufficient valid data: %d points)\n', ...
                    wave, t, length(valid_data));
                
                spectra.(farm_spacing)(t).(wave).Pxx = NaN;
                spectra.(farm_spacing)(t).(wave).f = NaN;
                spectra.(farm_spacing)(t).(wave).valid = false;
                continue
            end
            
            % Compute power spectral density using Welch's method
            [Pxx, f] = pwelch(power_signal, hamming(window_length), overlap, nfft, Fs);
            
            % Store in structure
            spectra.(farm_spacing)(t).(wave).Pxx = Pxx;
            spectra.(farm_spacing)(t).(wave).f = f;
            spectra.(farm_spacing)(t).(wave).Fs = Fs;
            spectra.(farm_spacing)(t).(wave).window_length = window_length;
            spectra.(farm_spacing)(t).(wave).overlap = overlap;
            spectra.(farm_spacing)(t).(wave).valid = true;
            spectra.(farm_spacing)(t).(wave).nan_fraction = nan_fraction;
            
            % Optional: Compute band-limited variances using your function
            % Example: Low frequency band (0-0.5 Hz)
            [rms_low, ~] = bandlimited_rms_fft(power_signal, Fs, 0, 0.5, 'none');
            spectra.(farm_spacing)(t).(wave).rms_low = rms_low;
            
            % Wave-frequency band (if applicable)
            if contains(wave, 'LM') && ~strcmp(wave, 'LM0_AK00')
                wave_prefix = extractBefore(wave, '_');
                if isfield(forcing_frequencies, wave_prefix)
                    f_wave = forcing_frequencies.(wave_prefix);
                    % Band around wave frequency (±10%)
                    [rms_wave, ~] = bandlimited_rms_fft(power_signal, Fs, ...
                        0.9*f_wave, 1.1*f_wave, 'none');
                    spectra.(farm_spacing)(t).(wave).rms_wave = rms_wave;
                    spectra.(farm_spacing)(t).(wave).f_wave = f_wave;
                end
            end
        end
    end
end

fprintf('Power spectra computation complete.\n')





%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTTING EXAMPLE: POWER SPECTRA (with validity checks)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Example 1: Compare spectra across turbines for one wave condition
figure('Position', [100, 100, 1200, 500])

farm_spacing = 'SX50';  % 5D spacing
wave = 'LM5_AK06';      % Example wave condition
turbines_to_plot = [1, 4, 7, 10];  % Front, mid, rear turbines

plot_count = 0;
for i = 1:length(turbines_to_plot)
    t = turbines_to_plot(i);
    
    % Check if data is valid
    if ~isfield(spectra.(farm_spacing)(t).(wave), 'valid') || ...
       ~spectra.(farm_spacing)(t).(wave).valid
        fprintf('Skipping Turbine %d - invalid data\n', t)
        continue
    end
    
    plot_count = plot_count + 1;
    
    f = spectra.(farm_spacing)(t).(wave).f;
    Pxx = spectra.(farm_spacing)(t).(wave).Pxx;
    
    subplot(1, length(turbines_to_plot), i)
    loglog(f, Pxx, 'LineWidth', 1.5)
    grid on
    xlabel('Frequency [Hz]')
    ylabel('PSD [Power^2/Hz]')
    title(sprintf('Turbine %d', t))
    xlim([0.1, Fs/2])
    
    % Add vertical line at wave frequency if available
    if isfield(spectra.(farm_spacing)(t).(wave), 'f_wave')
        f_wave = spectra.(farm_spacing)(t).(wave).f_wave;
        hold on
        xline(f_wave, 'r--', 'LineWidth', 1.5, 'Label', 'Wave freq')
    end
end

if plot_count == 0
    close(gcf)
    warning('No valid data to plot for %s - %s', farm_spacing, wave)
else
    sgtitle(sprintf('%s - %s - %s', fancy_name, farm_spacing, wave), ...
        'FontSize', 14, 'FontWeight', 'bold')
end


%% Example 2: Compare wave vs no-wave for one turbine
figure('Position', [100, 100, 800, 600])

farm_spacing = 'SX50';
turbine = 1;
wave = 'LM5_AK06';
no_wave = 'LM0_AK00';

% Check validity
wave_valid = isfield(spectra.(farm_spacing)(turbine).(wave), 'valid') && ...
             spectra.(farm_spacing)(turbine).(wave).valid;
nowave_valid = isfield(spectra.(farm_spacing)(turbine).(no_wave), 'valid') && ...
               spectra.(farm_spacing)(turbine).(no_wave).valid;

if ~wave_valid || ~nowave_valid
    close(gcf)
    warning('Invalid data for Turbine %d comparison', turbine)
else
    % Wave condition
    f_wave = spectra.(farm_spacing)(turbine).(wave).f;
    Pxx_wave = spectra.(farm_spacing)(turbine).(wave).Pxx;
    
    % No wave condition
    f_nowave = spectra.(farm_spacing)(turbine).(no_wave).f;
    Pxx_nowave = spectra.(farm_spacing)(turbine).(no_wave).Pxx;
    
    loglog(f_wave, Pxx_wave, 'LineWidth', 2, 'DisplayName', wave)
    hold on
    loglog(f_nowave, Pxx_nowave, 'LineWidth', 2, 'DisplayName', 'No waves')
    grid on
    xlabel('Frequency [Hz]')
    ylabel('PSD [Power^2/Hz]')
    title(sprintf('Turbine %d - %s', turbine, farm_spacing))
    legend('Location', 'best')
    xlim([0.1, Fs/2])
    
    % Add wave frequency marker
    if isfield(spectra.(farm_spacing)(turbine).(wave), 'f_wave')
        f_w = spectra.(farm_spacing)(turbine).(wave).f_wave;
        xline(f_w, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Wave freq')
    end
end




%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FFT-BASED BAND-LIMITED RMS FUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% Helper function: Get valid turbines for a condition
function valid_turbines = get_valid_turbines(spectra, farm_spacing, wave, turbines)
    valid_turbines = [];
    for t = 1:length(turbines)
        if isfield(spectra.(farm_spacing)(t).(wave), 'valid') && ...
           spectra.(farm_spacing)(t).(wave).valid
            valid_turbines(end+1) = t; %#ok<AGROW>
        end
    end
end


function [rmsBand, psdInfo] = bandlimited_rms_fft(q, Fs, f1, f2, detrendMode)
% bandlimited_rms_fft  Compute RMS of q in the frequency band [f1,f2] using FFT
%
% This function uses Parseval's theorem to compute band-limited RMS with
% sharp frequency cutoffs (no filter roll-off losses). This ensures that
% the sum of squared RMS values across contiguous bands equals the total
% variance of the signal.
%
% Inputs:
%   q           [Nx1] signal
%   Fs          sampling frequency [Hz]
%   f1          lower band edge [Hz] (use 0 for DC)
%   f2          upper band edge [Hz] (must be <= Fs/2)
%   detrendMode 'constant' (mean removal), 'linear', or 'none'
%
% Outputs:
%   rmsBand     RMS of signal content in [f1, f2]
%   psdInfo     struct with diagnostic info (optional)

    arguments
        q (:,1) double
        Fs (1,1) double {mustBePositive}
        f1 (1,1) double {mustBeNonnegative}
        f2 (1,1) double {mustBePositive}
        detrendMode (1,:) char = 'constant'
    end

    % Input validation
    if f2 > Fs/2
        error('f2 must be <= Fs/2. Got f2=%.3f, Fs/2=%.3f', f2, Fs/2);
    end
    if f1 >= f2
        error('f1 must be < f2. Got f1=%.3f, f2=%.3f', f1, f2);
    end

    N = length(q);
    
    % Detrend signal
    switch detrendMode
        case 'constant'
            q0 = q - mean(q, 'omitnan');
        case 'linear'
            q0 = detrend(q, 'linear');
        case 'none'
            q0 = q;
        otherwise
            q0 = q - mean(q, 'omitnan');
    end

    % Compute FFT
    Q = fft(q0);
    
    % Frequency vector
    df = Fs / N;                    % Frequency resolution
    f = (0:N-1)' * df;              % Two-sided frequency vector
    
    % One-sided frequency vector for indexing
    if mod(N, 2) == 0
        nUnique = N/2 + 1;          % DC to Nyquist (inclusive)
    else
        nUnique = (N+1)/2;          % DC to just below Nyquist
    end
    f_onesided = f(1:nUnique);
    
    % Find frequency bins within the band [f1, f2)
    % Use >= f1 and < f2 for lower bands, include f2 if at Nyquist
    if abs(f2 - Fs/2) < df/2
        idx_band = (f_onesided >= f1) & (f_onesided <= f2);
    else
        idx_band = (f_onesided >= f1) & (f_onesided < f2);
    end
    
    % Get the magnitude squared of FFT coefficients in the band
    Q_onesided = Q(1:nUnique);
    magSq = abs(Q_onesided(idx_band)).^2;
    
    % Determine scaling for each bin
    idx_numbers = find(idx_band);
    
    power = 0;
    for i = 1:length(idx_numbers)
        k = idx_numbers(i);
        if k == 1
            % DC component (appears once)
            power = power + magSq(i);
        elseif mod(N, 2) == 0 && k == nUnique
            % Nyquist component for even N (appears once)
            power = power + magSq(i);
        else
            % All other components (appear twice: positive and negative freq)
            power = power + 2 * magSq(i);
        end
    end
    
    % Parseval's theorem: sum(|x|^2) = (1/N) * sum(|X|^2)
    variance_band = power / N^2;
    rmsBand = sqrt(variance_band);
    
    % Optional diagnostic output
    if nargout > 1
        Pxx = abs(Q_onesided).^2 / (N^2 * df);
        Pxx(2:end-1) = 2 * Pxx(2:end-1);
        if mod(N, 2) ~= 0
            Pxx(end) = 2 * Pxx(end);
        end
        
        psdInfo.f = f_onesided;
        psdInfo.Pxx = Pxx;
        psdInfo.idx = idx_band;
        psdInfo.df = df;
        psdInfo.N = N;
    end
end


