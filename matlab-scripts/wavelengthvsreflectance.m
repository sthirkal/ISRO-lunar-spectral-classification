% Define the header file name
hdr_file = 'ch2_iir_nci_20240130T2114257981_d_img_d18.hdr';  % Replace with your actual .hdr file name

% Open the header file
fid = fopen(hdr_file, 'r');

% Initialize variables to store the metadata
samples = [];
lines = [];
bands = [];
data_type = [];
interleave = [];

% Read the header file line by line
while ~feof(fid)
    line = fgetl(fid);
    
    % Parse each line to extract the relevant information
    if contains(line, 'samples')
        samples = sscanf(line, 'samples = %d');
    elseif contains(line, 'lines')
        lines = sscanf(line, 'lines = %d');
    elseif contains(line, 'bands')
        bands = sscanf(line, 'bands = %d');
    elseif contains(line, 'data type')
        data_type = sscanf(line, 'data type = %d');
    elseif contains(line, 'interleave')
        interleave = sscanf(line, 'interleave = %s');
    end
end

% Close the header file
fclose(fid);

% Map ENVI data types to MATLAB data types
switch data_type
    case 1
        matlab_data_type = 'uint8';
    case 2
        matlab_data_type = 'int16';
    case 4
        matlab_data_type = 'single';  % Float in MATLAB
    case 5
        matlab_data_type = 'double';
    case 12
        matlab_data_type = 'uint16';
    otherwise
        error('Unsupported data type');
end

% Load the hyperspectral data using multibandread
filename = 'ch2_iir_nci_20240130T2114257981_d_img_d18.qub';  % Replace with your actual .qub file name
data = multibandread(filename, [lines, samples, bands], ...
                     matlab_data_type, 0, interleave, 'ieee-le');

% Load the XML file containing wavelengths
xmlFileName = 'ch2_iir_nci_20240130T2114257981_d_img_d18.xml';  % Replace with your actual XML file name
xmlDoc = xmlread(xmlFileName);

% Extract all wavelength elements
wavelengthElements = xmlDoc.getElementsByTagName('center_wavelength');

% Initialize an array to store wavelengths
numBands = wavelengthElements.getLength;
wavelengths = zeros(numBands, 1);

% Loop over each wavelength element to extract the value
for i = 6:numBands-56
    wavelengthNode = wavelengthElements.item(i-1);  % XML nodes are 0-indexed
    wavelengths(i) = str2double(wavelengthNode.getTextContent);
end

% Load solar irradiance data from the text file
% Assuming the file has two columns: wavelength and irradiance
solar_data = readtable('ch2_iirs_solar_flux.txt');
E_sun = solar_data{:, 2};  % Extract the solar irradiance

% Define the solar zenith angle (in degrees)
theta_deg = 52.891870;  % Replace with actual value
theta = deg2rad(theta_deg);  % Convert to radians

% Initialize the reflectance array
reflectance = zeros(size(data));

% Calculate reflectance for each band
for band = 6:bands-56
    % Make sure to match the solar irradiance with the correct wavelength band
    reflectance(:, :, band) = (pi * data(:, :, band)) ./ (E_sun(band) * cos(theta));
end

% Specify the band you want to plot
band_index = 10;  % Change this to the desired band index

% Extract the reflectance data for the entire image at the specified band
reflectance_band = reflectance(:, :, band_index);

% Display the reflectance data as an image
figure;
imagesc(reflectance_band);  % Display the image with scaled colors
colorbar;  % Add a colorbar to show the reflectance values
xlabel('Sample');
ylabel('Line');
title(['Reflectance for Band ', num2str(band_index)]);

% Compute the average reflectance across the entire image for the specified band
average_reflectance = mean(reflectance_band(:)) / 1000;  % Scale down by 1000

% Plot the average reflectance
figure;
plot(wavelengths(band_index), average_reflectance, 'o-');  % Plot the average reflectance for the specified band
xlim([0 3000])
xlabel('Wavelength (nm)');
ylabel('Average Reflectance');
title(['Average Reflectance vs. Wavelength for Band ', num2str(band_index)]);

% Initialize an array to store the average reflectance for each band
average_reflectance_all_bands = zeros(bands, 1);

% Loop over each band to compute the average reflectance
for i = 6:bands-56
    reflectance_band = reflectance(:, :, i);  % Extract the reflectance for the current band
    average_reflectance_all_bands(i) = mean(reflectance_band(:)) / 1000;  % Scale down by 1000
end

% Plot average reflectance vs. wavelength
figure;
plot(wavelengths(6:bands-56), average_reflectance_all_bands(6:bands-56), 'o-');
xlim([0 3000])
xlabel('Wavelength (nm)');
ylabel('Average Reflectance');
title('Average Reflectance vs. Wavelength (All Bands)');

% Extract reflectance data for a specific pixel (row, column)
row = 50;  % Choose your desired row
column = 50;  % Choose your desired column
reflectance_pixel = squeeze(reflectance(row, column, :)) / 1000;  % Extract the spectral profile and scale down by 1000

% Plot Reflectance vs. Wavelength for a specific pixel
figure;
plot(wavelengths(6:bands-56), reflectance_pixel(6:bands-56), 'o-');  % 'o-' plots points connected by lines
xlim([0 3000])
xlabel('Wavelength (nm)');  % Label for x-axis
ylabel('Reflectance');  % Label for y-axis
title('Reflectance vs. Wavelength for Pixel (50, 50)');  % Plot title

% Display the reflectance data in the console if needed
disp(table(wavelengths(6:bands-56), reflectance_pixel(6:bands-56)));
