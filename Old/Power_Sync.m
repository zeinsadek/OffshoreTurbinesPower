%%% Look at Power Signals and Tracking Images

clear; close all; clc; format long
%% Import Power Data
main_path     = "F:\Power\12_23_2023_Sync\";
figure_folder = "F:\Power\12_23_2023_Sync\Figures";
mat_folder    = "F:\Power\12_23_2023_Sync\Matfiles\";
caze          = 'Tracking_Power_Trigger_100Hz_20s_WVA';
name          = "T1_Tracking_Power_Trigger_100Hz_20s_WVA_P_2000";

% Import data
path = strcat(main_path, caze, '\', name, '.csv');
data = readmatrix(path);

% delete data before first trigger
triggers = find(data(:,6) == 1);
data     = data(triggers(1):end, :);

% Compute Power
t    = data(:,1) * 1E-6;
R    = data(:,2);
BV   = data(:,3);
SV   = data(:,4);
I    = data(:,5); 
trig = data(:,6);

% Zero time
t = t - t(1);

% Where trigger went off
trig_idx = find(trig == 1);
fprintf('Number of Triggered Power Points: %3.1d\n', length(trig_idx))

% Power
V    = BV + SV;
P    = V .* I;

% % Plot Together
% figure('units','pixels','position',[0 0 1440 1080]);
% hold on
% plot(t, P,'linewidth', 1, 'color', 'k')
% scatter(t, P, 5, 'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', 'green')
% plot(t, movmean(P,10),'linewidth', 1, 'color', 'red')
% hold off
% xlim([0, max(t)])
% ylim([40,80])
% xlabel('Time [s]')
% ylabel('Power [mW]')
% title('Turbine 1: Camera-Power Sync Test')

%% Images
im_folder  = strcat("F:\Turbine_Tracking_Images\12_23_2023_Sync\", caze, '\');
im_dir     = dir(strcat(im_folder, 'CAM1'));
im_dir     = im_dir(3:end - 1,:);
num_images = length(im_dir);
fprintf('Number of Triggered Images: %3.1d\n', num_images)

first_image = im_dir(1).name;
seconds      = str2double(first_image(6:7));
microseconds = str2double(first_image(9:14)) * 1E-6;
image_zero   = seconds + microseconds;


for i = 1:num_images
    disp(i)
    I_name       = im_dir(i).name;
    seconds      = str2double(I_name(6:7));
    microseconds = str2double(I_name(9:14)) * 1E-6;
    image_time   = (seconds + microseconds) - image_zero;

    I = imread(strcat(im_folder, 'CAM1\', I_name));
    I = imrotate(I, 90);

    % Plot Together
    ax = figure('units','pixels','position',[0 0 1440 1080]);
    subplot(1,2,1)
    imshow(I)
    title(I_name, 'Interpreter', 'none')
    
    subplot(1,2,2)
    hold on
    % plot(t, P,'linewidth', 2, 'color', 'k')
    scatter(t, P, 10, 'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', 'green')
    plot(t, movmean(P,10),'linewidth', 1, 'color', 'k')
    xline(image_time, 'color', 'k', 'LineWidth', 2)
    hold off
    xlim([0, max(t)])
    xlabel('Time [s]')
    ylabel('Power [mW]')
    title('Turbine 1: Camera-Power Sync Test')
    
    % Save Axes to make Movie
    F(i) = getframe(gcf);
    close all;
end

%% Make Movie
% create the video writer with 1 fps
writerObj = VideoWriter('Tracking_Power_Trigger_100Hz_20s_WVA_10FPS.avi');
writerObj.FrameRate = 10;
open(writerObj);
for i=1:length(F)
    frame = F(i) ;    
    writeVideo(writerObj, frame);
end
close(writerObj);











