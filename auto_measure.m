%% USER CONFIG

% set this value to the port used for the spectrometer
% type "serialportlist" in matlab to get all currently used ports
conf.port = "/dev/ttyACM0";
conf.command = "all"; % Options: "XYZ", "Yxy", "Yuv", "spectral", "all"
conf.file_name = "my_measurement"; % appended to filename with time/date
conf.output_dir = "./out/";  % directory the measurements will get saved to

% show the values as an fullscreen image for direct measurements
% set to false if you are not using this script to generate the images
conf.show_images = true;
conf.width = 1920; % only used in combination with "show_images"
conf.height = 1080; % only used in combination with "show_images"

addpath("./src/"); % load helper functions / classes

% whith "show_images" set to true you can use RGB values to generate
% and show test images, which will be measured automatically. get_values
% can be used to generate typical patterns or specify a n*3 double array
% values = get_values("borders", 8); % grey, primary-borders, borders, mesh
% values = [[0.3,0.5,0.1];[0,1,1];[1,0.2,0.8];[1,0.2,0.8]];
values = 0:0.2:1;

% as an alternative you can set "show_images" to false and use this script to
% go through a set of measurements by pressing enter to start the next one
% specified names which will be shown and saved with the measurements
% values = ["Paprika_LED_Wall", "Paprika_Orbiter", "Paprika_Daylight"];


%% SETUP

% create output folder if it does not exist yet
if not(isfolder(conf.output_dir))
    mkdir(conf.output_dir)
end

% check for some invalid options
if ~exist("values", "var") 
    disp("Please define values in the USER CONFIG section");
    return
end

if (class(values(1)) == "string" && conf.show_images)
    disp("WARNING: Can not show images defined by names. Please " + ...
        "either specify values as RGB tripplets or set " +...
        "conf.show_images to false. Ignoring this option now!");
    conf.show_images = false;
end

% establish new connection to the spectrometer
clear("spectro");
spectro = Spectrometer(conf.port);
if ~spectro.is_connected()
    return
end

%% MEASUREMENT

% create figure and show it in fullscreen
if conf.show_images
    fig = figure('Name', 'Measurement', 'MenuBar', 'none', ...
        'WindowState', 'fullscreen', 'ToolBar', 'none');
    img = pad_image_to_size( ...
        im2double(imread('./res/user_info.png') .* 255), ...
        conf.height, conf.width, 1);
    set(gca, 'Position', [0 0 1 1]);
    imshow(img);
    pause;
    countdown(3);
    tic;
else
    disp("Measuring without showing the images...");
end

clear("measurements")

% accomedate accommodate 1:n greyscale and n:3 rgb values
count = size(values,1);
if size(values,1) == 1
    count = size(values, 2);
end

for i = 1:count
    
    if conf.show_images
        
        % stops measurement if the figure gets closed
        if ~ishandle(fig)
            disp("Measurement stopped by the user (figure was closed)");
            return
        end
        
        if ismatrix(values) && size(values, 1) == 1 % grey scale values
            color_value = [values(i), values(i), values(i)];
        elseif ismatrix(values) && size(values, 2) == 3
            color_value = values(i,:);
        elseif ndims(values) == 3 && all(size(values, [2,3]) == [1,3])
            color_value = values(i,1,:);
        else
            disp("Please specify colors either as n*m*3 or n*3");
            close(fig);
            return
        end
        
        img = repmat(reshape(color_value, [1,1,3]), conf.height, conf.width);
        imshow(img);
        fprintf("Measuring (" + num2str(color_value, '%.4f ') + ")\n");
    else
        if class(values(i)) == string
            fprintf("Measuring (" + i +") - Press enter to measure...\n");
        else
            fprintf("Start next measurement (" + num2str(values(i)) + ") - Press enter to measure...\n");
        end
        pause;
    end
    
    current_measurement = spectro.measure(conf.command);
    current_measurement.measurement = values(:,i,:);
    measurements(i) = current_measurement;

end

if conf.show_images
    close(fig);
    disp("Time elapsed: " + toc);
end

clear("i", "fig", "current_measurement", "color_value", "count");

%% END
output_file_name = conf.output_dir + datestr(datetime,'yyyymmdd_HHMMss') ...
    + "_" + conf.file_name + ".json";
output_file = fopen(output_file_name, 'w');
fprintf(output_file, jsonencode(measurements, 'PrettyPrint', true));
disp("Saved measurements to '" + output_file_name);

spectro.quit_remote_mode();
clear("spectro", "output_file_name", "output_file");

%% HELPER FUNCTIONS

function countdown(seconds)
for i = seconds:-1:1
    disp(i);
    pause(1);
end
disp(0);
end
