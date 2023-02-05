%% USER CONFIG

% set this value to the port used for the spectrometer
% type "serialportlist" in matlab to get all currently used ports
conf.port = "/dev/ttyACM0"; 
conf.command = "all"; % Options: "XYZ", "Yxy", "Yuv", "spectral", "all"
conf.file_name = "my_measurement"; % appended to filename with date
conf.output_dir = "./out/auto_measure/";

% show the values as an fullscreen image for direct measurements
conf.show_images = false; 
conf.width = 1920; % only used in combination with "show_images"
conf.height = 1080; % only used in combination with "show_images"

addpath("./src/");

% generate RGB values for the measurement
values = get_values("primary-borders", 8); % primary-borders, borders, mesh, grey

%% SETUP


if not(isfolder(conf.output_dir))
    mkdir(conf.output_dir)
end

% establish connection to spectrometer
clear("spectro");
spectro = Spectrometer(conf.port);
%if ~spectro.is_connected()
%    return
%end

%% MEASUREMENT

if conf.show_images
    % fullscreen figure
    fig = figure('Name', 'TEST', 'MenuBar', 'none', ...
        'WindowState', 'fullscreen', 'ToolBar', 'none');
    img_txt = imread('./res/user_info.png');
    img_txt = im2double(img_txt .* 255);
    img = pad_image_to_size(img_txt, conf.height, conf.width, 1);
    set(gca, 'Position', [0 0 1 1]);
    imshow(img);
    pause;
end

clear("measurements")

countdown(3);

tic
for i = 1:length(values)
    
    if conf.show_images
        img = repmat(values(:,i,:) ./ 255, height, conf.width);
        imshow(img);
        try
            fprintf("\nStarting measurement (" + string(values(:,i,:)) + ")\n");
        catch exception % workaround pls fix
            fprintf("\nStarting measurement (" + i +")\n");
        end
    else
        try
            fprintf("\nStart next measurement (" + string(values(:,i,:)) + ")?\n");
        catch exception
            fprintf("\nStarting measurement (" + i +")\n");
        end
        % pause;
    end
    
    current_measurement = spectro.measure(conf.command);
    current_measurement.measurement = conf.values(:,i,:);
    measurements(i) = current_measurement;
    
    while toc - (i*(24*0.02*5)) < 0
        pause(0.01);
    end
end

if conf.show_images
    close(fig);
end

%% END
output_file = fopen( ...
    conf.output_dir + datestr(datetime,'yyyymmdd_HHMMss') + "_" ...
    + conf.file_name + ".json", 'w');


fprintf(output_file, jsonencode(measurements, 'PrettyPrint', true));

% spectro.quit_remote_mode();
clear("spectro");

%% HELPER FUNCTIONS

function countdown(seconds)
for i = seconds:-1:1
    disp(i);
    pause(1);
end
disp(0);
end