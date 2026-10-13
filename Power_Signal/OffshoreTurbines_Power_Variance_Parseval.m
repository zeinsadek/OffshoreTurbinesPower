function [row_variance, variance_table, fig, fft_spectra, parseval_table] = ...
    OffshoreTurbines_Power_Variance_Parseval(power)
% Exact full-record Parseval variance and row-by-row plots against a/D.
%
% INPUT: the power structure loaded by your original script (NOT spectra):
%   power.(farm).(arrangement).(spacing).(wave)(record).Power
%   power.(farm).(arrangement).(spacing).(wave)(record).Time
%
% USAGE (after loading power, or after running your original script):
% [row_variance, variance_table, fig, fft_spectra, parseval_table] = ...
%     OffshoreTurbines_Power_Variance_Parseval(power);
%
% No Welch averaging, segmentation, taper, or zero-padding is used.
% For x = double(Power(:)) - mean(double(Power(:))), N = numel(x):
%   X = fft(x);
%   variance = sum(abs(X).^2)/N^2 = mean(x.^2) = var(Power,1)
% up to floating-point roundoff. MATLAB var(Power) instead divides by N-1.
% One-sided PSD units are Power^2/Hz; sum(Pxx)*df gives this same variance.
% All bins are retained. Do not use trapz or omit DC/Nyquist bins.
%
% Finite real samples on an approximately uniform time grid are required.
% Invalid records are flagged, never shortened or interpolated here.
% If your original script filled missing values, the equality applies to
% that already-filled signal, not the unavailable original measurements.
%
% Each plotted value is the average of individual turbine variances within
% a physical row, NOT variance of the simultaneous row-mean/row-total signal.
% FBF top, FWF bottom; Inline purple, Staggered orange; spacing by marker.
% Power is assumed to be in mW, as in the supplied script; edit ylabel if not.
% LM labels encode lambda/D, giving a/D = ak*(lambda/D)/(2*pi).
%
% Outputs:
%   row_variance / variance_table: per-case row averages and completeness
%   fig: figure handle
%   fft_spectra: individual full-record PSDs and Parseval diagnostics
%   parseval_table: per-record spectral/time variance, error and QC status
%
% Optional saves:
% writetable(variance_table,'Power_Variance_PerRow.csv');
% writetable(parseval_table,'Power_Parseval_Checks.csv');
% exportgraphics(fig,'Power_Variance_Parseval.pdf','ContentType','vector');

assert(isstruct(power) && isscalar(power),'Input must be the power structure.');
farms = {'FBF','FWF'};
layouts = {'Inline','Staggered'};
physical_ids.Inline = 1:12;
physical_ids.Staggered = [1:5,7:11];
fft_spectra = struct();
qc = cell(0,13);
for iFarm = 1:numel(farms)
    farm = farms{iFarm};
    for iLayout = 1:numel(layouts)
        layout = layouts{iLayout};
        if ~isfield(power,farm) || ~isfield(power.(farm),layout), continue; end
        spacing_names = fieldnames(power.(farm).(layout));
        for iSpacing = 1:numel(spacing_names)
            spacing = spacing_names{iSpacing};
            wave_names = fieldnames(power.(farm).(layout).(spacing));
            for iWave = 1:numel(wave_names)
                wave = wave_names{iWave};
                records = power.(farm).(layout).(spacing).(wave);
                for it = 1:numel(records)
                    turbine_id = NaN;
                    if it <= numel(physical_ids.(layout))
                        turbine_id = physical_ids.(layout)(it);
                    end
                    spec = full_record_psd(records(it));
                    spec.turbine_id = turbine_id;
                    spec.record_index = it;
                    fft_spectra.(farm).(layout).(spacing)(it).(wave) = spec;
                    qc(end+1,:) = {farm,layout,spacing,wave,turbine_id,spec.N, ...
                        spec.variance_fft,spec.variance_time,spec.absolute_error, ...
                        spec.relative_error,spec.parseval_pass,spec.valid,spec.reason}; %#ok<AGROW>
                    if ~spec.valid
                        warning('Parseval:InvalidRecord','%s %s %s %s record %d: %s', ...
                            farm,layout,spacing,wave,it,spec.reason);
                    end
                end
            end
        end
    end
end
assert(~isempty(qc),'No power records found.');
parseval_table = cell2table(qc,'VariableNames',{'Farm','Arrangement','Spacing', ...
    'Wave','TurbineID','N','VarianceFFT','VarianceTime','AbsoluteError', ...
    'RelativeError','ParsevalPass','Valid','Reason'});
[row_variance, variance_table, fig] = plot_fft_variance(fft_spectra);
end

function spec = full_record_psd(record)
spec = struct('Pxx',NaN,'f',NaN,'Fs',NaN,'df',NaN,'N',0, ...
    'variance_fft',NaN,'variance_time',NaN,'absolute_error',NaN, ...
    'relative_error',NaN,'parseval_pass',false,'valid',false,'reason','');
if ~isfield(record,'Power') || ~isfield(record,'Time')
    spec.reason = 'Missing Power or Time.'; return
end
if ~isnumeric(record.Power) || ~isnumeric(record.Time) || ...
        ~isvector(record.Power) || ~isvector(record.Time)
    spec.reason = 'Power and Time must be numeric vectors.'; return
end
p = double(record.Power(:)); t = double(record.Time(:));
N = numel(p); spec.N = N;
if N < 2 || numel(t) ~= N || ~isreal(p) || ~isreal(t) || ...
        any(~isfinite(p)) || any(~isfinite(t))
    spec.reason = 'Need at least two finite real paired Power/Time samples.'; return
end
steps = diff(t); dt = mean(steps);
% Allow small timestamp roundoff/jitter, not gaps or removed samples.
if dt <= 0 || any(steps <= 0) || max(abs(steps-dt)) > 1e-3*dt
    spec.reason = 'Time must increase uniformly (relative step tolerance 0.001).'; return
end
Fs = 1/dt;
x = p-mean(p);
X = fft(x);  % Full record, rectangular window, N FFT points
nPositive = floor(N/2)+1;
Pxx = abs(X(1:nPositive)).^2/(Fs*N);
if rem(N,2) == 0
    Pxx(2:end-1) = 2*Pxx(2:end-1); % DC and Nyquist occur once
else
    Pxx(2:end) = 2*Pxx(2:end);     % Odd N has no Nyquist bin
end
df = Fs/N;
v_fft = sum(Pxx)*df;
v_time = mean(x.^2);  % var(p,1), with population normalization
if ~isfinite(v_fft) || ~isfinite(v_time)
    spec.reason = 'Numerical overflow in spectral/time-domain variance.'; return
end
abs_error = abs(v_fft-v_time);
scale = max(v_fft,v_time);
rel_error = 0;
if scale > 0, rel_error = abs_error/scale; end
% Roundoff tolerance, not a rescaling of the spectrum to force agreement.
passed = abs_error <= 1e-10*scale + 100*realmin;
assert(passed,'Parseval:Mismatch', ...
    'FFT/time variance mismatch: absolute error %.3g, relative error %.3g.', ...
    abs_error,rel_error);
spec.Pxx = Pxx;
spec.f = (0:nPositive-1)'*df;
spec.Fs = Fs; spec.df = df;
spec.variance_fft = v_fft; spec.variance_time = v_time;
spec.absolute_error = abs_error; spec.relative_error = rel_error;
spec.parseval_pass = passed; spec.valid = true;
end

function [row_variance, variance_table, fig] = plot_fft_variance(spectra)
% Average the individually integrated full-record PSDs, then plot.
%% Plot settings
show_linear_fits = true;  % Descriptive fits pooled over spacing/steepness
require_complete_row = true; % Incomplete rows retained with variance = NaN
plot_farm_types = {'FBF','FWF'};
arrangements = {'Inline','Staggered'};
spacings = [5,4.5,4,3.5,3];
markers = {'o','^','s','d','v'};
steepnesses = [0.06,0.09,0.12];
colors.Inline = [157 78 221;90 24 154;36 0 70]/255;
colors.Staggered = [255 158 0;255 133 0;255 109 0]/255;
ids.Inline = 1:12;
ids.Staggered = [1:5,7:11];
row_ids.Inline = {[1 2 3],[4 5 6],[7 8 9],[10 11 12]};
row_ids.Staggered = {[1 2 3],[4 5],[7 8 9],[10 11]};
lambda_D = struct('LM0',0,'LM5',5,'LM4',4,'LM33',5/1.5, ...
    'LM3',3,'LM25',2.5,'LM2',2);

row_variance = struct();
entries = cell(0,11);

%% Integrate each turbine BEFORE row averaging (avoids interpolation losses)
for ft = 1:numel(plot_farm_types)
    farm = plot_farm_types{ft};
    for ia = 1:numel(arrangements)
        arrangement = arrangements{ia};
        if ~isfield(spectra,farm) || ~isfield(spectra.(farm),arrangement)
            continue
        end
        for is = 1:numel(spacings)
            spacing = sprintf('SX%d',round(10*spacings(is)));
            if ~isfield(spectra.(farm).(arrangement),spacing), continue; end
            records = spectra.(farm).(arrangement).(spacing);
            cases = fieldnames(records);
            for iw = 1:numel(cases)
                wave = cases{iw};
                token = regexp(wave,'^(LM\d+)_AK(\d+)$','tokens','once');
                if isempty(token), continue; end
                assert(isfield(lambda_D,token{1}), ...
                    'Add wavelength mapping for %s to lambda_D.',token{1});
                ak = str2double(token{2})/100;
                a_D = ak*lambda_D.(token{1})/(2*pi);
                turbine_id = nan(1,numel(records));
                turbine_variance = nan(1,numel(records));
                for it = 1:numel(records)
                    spec = records(it).(wave);
                    if isempty(spec) || ~isstruct(spec), continue; end
                    if isfield(spec,'turbine_id')
                        turbine_id(it) = spec.turbine_id;
                    elseif it <= numel(ids.(arrangement))
                        turbine_id(it) = ids.(arrangement)(it);
                    end
                    [turbine_variance(it), reason] = integrate_psd(spec);
                    if ~isempty(reason)
                        warning('Variance:InvalidPSD','%s %s %s %s record %d: %s', ...
                            farm,arrangement,spacing,wave,it,reason);
                    end
                end
                for ir = 1:4
                    expected = row_ids.(arrangement){ir};
                    use = ismember(turbine_id,expected) & isfinite(turbine_variance);
                    used_ids = turbine_id(use);
                    assert(numel(unique(used_ids)) == numel(used_ids), ...
                        'Duplicate turbine IDs in %s %s %s %s.',farm,arrangement,spacing,wave);
                    complete = numel(used_ids) == numel(expected);
                    value = NaN;
                    if any(use) && (complete || ~require_complete_row)
                        value = mean(turbine_variance(use));
                    end
                    result = struct('variance',value,'a_over_D',a_D, ...
                        'ak',ak,'lambda_over_D',lambda_D.(token{1}), ...
                        'turbine_ids',used_ids,'turbine_variances',turbine_variance(use), ...
                        'n_turbines',sum(use),'n_expected',numel(expected), ...
                        'complete',complete,'valid',isfinite(value));
                    row_variance.(farm).(arrangement).(spacing)(ir).(wave) = result;
                    entries(end+1,:) = {farm,arrangement,spacings(is),wave,ir, ...
                        ak,a_D,value,sum(use),numel(expected),complete}; %#ok<AGROW>
                end
            end
        end
    end
end
variance_table = cell2table(entries,'VariableNames',{'Farm','Arrangement', ...
    'Spacing_D','Wave','Row','ak','a_over_D','Variance','N_Turbines','N_Expected','Complete'});
assert(~isempty(entries),'No matching spectra found.');
if any(~variance_table.Complete)
    warning('Variance:IncompleteRows','%d incomplete rows; inspect variance_table.', ...
        sum(~variance_table.Complete));
end

%% Figure: top FBF, bottom FWF; columns = physical rows
fig = figure('Color','w','Units','centimeters','Position',[3 3 25 10]);
tl = tiledlayout(fig,2,4,'TileSpacing','compact','Padding','compact');
ax = gobjects(2,4);
for ft = 1:2
    for ir = 1:4
        ax(ft,ir) = nexttile(tl,(ft-1)*4+ir);
        hold(ax(ft,ir),'on');
        set(ax(ft,ir),'FontName','Times New Roman','FontSize',11, ...
            'TickLabelInterpreter','latex','Box','on');
        for ia = 1:2
            base = strcmp(variance_table.Farm,plot_farm_types{ft}) & ...
                strcmp(variance_table.Arrangement,arrangements{ia}) & ...
                variance_table.Row == ir & variance_table.ak > 0 & ...
                isfinite(variance_table.Variance);
            if show_linear_fits
                xx = variance_table.a_over_D(base);
                yy = variance_table.Variance(base);
                if numel(unique(xx)) >= 2
                    coeff = polyfit(xx,yy,1);
                    xf = [min(xx),max(xx)];
                    plot(ax(ft,ir),xf,polyval(coeff,xf),'Color',[.5 .5 .5], ...
                        'LineWidth',1.5,'HandleVisibility','off');
                end
            end
            for is = 1:numel(spacings)
                for ik = 1:numel(steepnesses)
                    use = base & abs(variance_table.Spacing_D-spacings(is)) < 1e-8 & ...
                        abs(variance_table.ak-steepnesses(ik)) < 1e-8;
                    plot(ax(ft,ir),variance_table.a_over_D(use),variance_table.Variance(use), ...
                        'LineStyle','none','Marker',markers{is},'MarkerSize',4.5, ...
                        'Color',colors.(arrangements{ia})(ik,:), ...
                        'MarkerFaceColor',colors.(arrangements{ia})(ik,:), ...
                        'HandleVisibility','off');
                end
            end
        end
        if ft == 1
            title(ax(ft,ir),sprintf('Row %d',ir),'Interpreter','latex');
            ax(ft,ir).XTickLabel = [];
        end
        if ir > 1, ax(ft,ir).YTickLabel = []; end
        if ir == 1
            text(ax(ft,ir),.03,.95,sprintf('(%c) %s','a'+ft-1,plot_farm_types{ft}), ...
                'Units','normalized','VerticalAlignment','top','Interpreter','latex');
        end
    end
end
xlabel(tl,'$a/D$','Interpreter','latex','FontSize',15);
ylabel(tl,'$\langle\sigma_{P}^{2}\rangle_{\mathrm{row}}$ [mW$^2$]', ...
    'Interpreter','latex','FontSize',14);
linkaxes(ax(:),'xy');
forced = variance_table.ak > 0 & isfinite(variance_table.Variance);
if any(forced)
    xlim(ax(1),[0,1.08*max(variance_table.a_over_D(forced))]);
    ylim(ax(1),[0,max(eps,1.12*max(variance_table.Variance(forced)))]);
else
    warning('Variance:NoValidPoints','No valid forced-wave row variances to plot.');
end
% Separate legend keys for arrangement/steepness and streamwise spacing.
h = gobjects(0); labels = {};
for ia = 1:2
    for ik = 1:3
        h(end+1) = plot(ax(1),NaN,NaN,'Color',colors.(arrangements{ia})(ik,:), ...
            'LineWidth',2); %#ok<AGROW>
        labels{end+1} = sprintf('%s: $ak=%.2f$',arrangements{ia}(1),steepnesses(ik)); %#ok<AGROW>
    end
end
for is = 1:numel(spacings)
    h(end+1) = plot(ax(1),NaN,NaN,'LineStyle','none','Marker',markers{is}, ...
        'Color','k','MarkerFaceColor','k','MarkerSize',5); %#ok<AGROW>
    labels{end+1} = sprintf('$S_x/D=%.1f$',spacings(is)); %#ok<AGROW>
end
leg = legend(ax(1),h,labels,'Interpreter','latex','Box','off');
leg.Layout.Tile = 'east';
end

function [v,reason] = integrate_psd(spec)
v = NaN; reason = '';
if isfield(spec,'valid') && ~spec.valid, return; end
if ~isfield(spec,'Pxx') || ~isfield(spec,'f')
    reason = 'Missing Pxx or f.'; return
end
p = spec.Pxx(:); f = spec.f(:);
if numel(f) < 2 || numel(p) ~= numel(f) || ...
        ~isreal(p) || ~isreal(f) || any(~isfinite(p)) || ...
        any(~isfinite(f)) || any(p < 0)
    reason = 'PSD/frequency values are invalid; no bins were omitted.'; return
end
df = f(2)-f(1);
tol = max(1e-10,abs(df)*1e-6);
if df <= 0 || abs(f(1)) > tol || any(abs(diff(f)-df) > tol)
    reason = 'Expected a uniform one-sided frequency grid starting at zero.'; return
end
if isfield(spec,'Fs') && (~isscalar(spec.Fs) || ~isfinite(spec.Fs) || ...
        spec.Fs <= 0 || abs(f(end)-spec.Fs/2) > df/2+tol)
    reason = 'PSD does not span the full one-sided frequency range.'; return
end
v = sum(p)*df;
end
