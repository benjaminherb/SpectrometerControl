%% USER CONFIG

% set this value to the port used for the spectrometer
% type "serialportlist" in matlab to get all currently used ports
conf.port = "/dev/ttyACM0";
conf.command = "all"; % Options: "XYZ", "Yxy", "Yuv", "spectral", "all"
conf.file_name = "my_measurement"; % appended to filename with time/date
conf.output_dir = "./out/";  % directory the measurements will get saved to

%% SETUP
addpath("./src/"); % load helper functions / classes

% create output folder if it does not exist yet
if not(isfolder(conf.output_dir))
    mkdir(conf.output_dir)
end

% establish new connection to the spectrometer
clear("spectro");
spectro = Spectrometer(conf.port);
if ~spectro.is_connected()
    return
end

%% MEASUREMENT

clear("measurements")

keep_measuring = true;
measurement_counter = 0;
while keep_measuring
    measurement_counter = measurement_counter + 1;
    
    fprintf("\nType the name for the next measurement (optional) " ...
        + "and press enter to start measuring.\n");
    user_input = input("Name (default " + measurement_counter + "): ", 's');
    if isempty(user_input)
        name = measurement_counter;
    else
        name = user_input;
    end
    
    current_measurement = spectro.measure(conf.command);
    current_measurement.measurement = name;
    measurements(measurement_counter) = current_measurement;
    
    fprintf( "Press enter to continue, type 'REDO' to redo the previous measurement or " ...
        + "'SAVE' to stop measuring and save to file.\n");
    user_input = input('Input: ', 's');
    if user_input == "REDO" || user_input == "redo"
        disp('Overwriting previous measurement!')
        measurement_counter = measurement_counter - 1;
    elseif user_input == "SAVE" || user_input == "save"
        disp('Saving '+ string(measurement_counter) + ' measurements to file!')
        keep_measuring = false;
    end
end

clear("current_measurement", "counter", "keep_measuring");

%% END
output_file_name = conf.output_dir + datestr(datetime,'yyyymmdd_HHMMss') ...
    + "_" + conf.file_name + ".json";
output_file = fopen(output_file_name, 'w');
fprintf(output_file, jsonencode(measurements, 'PrettyPrint', true));
disp("Saved measurements to '" + output_file_name);

spectro.quit_remote_mode();
clear("spectro", "output_file_name", "output_file");