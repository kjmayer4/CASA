function [ RawDataArray, RawTime ] = importRawSMPS(path )
%% Import Raw SMPS data
% Data should be exported to comma delimited text files
% Output is a single cell array with the data for each individual scan
% organized into columns. Multiple text files can be selected.
% Last edited KJM 3/28/2022

%% Import data

% Open folder
if nargin > 0
    current = cd(path);
end

% Select SMPS data files (can select multiple text files)
filelist = uigetfile('.txt', 'Select SMPS data files', 'MultiSelect', 'on');

% Open files
if ischar(filelist) == 1
    fid = fopen(filelist);
else
    fid = zeros(length(filelist),1);
    for i = 1:length(filelist)
        fid(i) = fopen(filelist{i});
    end
end

% Initialize variables
delimiter = ','; % comma delimited, for textscan
startRow = 35;

% Read in data line by line to get number of columns (for formatSpec) date,  
% time, and other data from header lines
colnum = zeros(length(fid),1);
date = cell(1,length(fid));
time = cell(1,length(fid));

% for i = 1:length(fid)
%     for j = 1:startRow-1
%         if j < 27
%            tline = fgetl(fid(i));
%         elseif j == 27
%            tline = fgetl(fid(i));
%            date(i) = textscan(tline(6:end), '%{MM/dd/uuuu}D', 'Delimiter', delimiter);
%         elseif j == 28
%             tline = fgetl(fid(i));
%             time(i) = textscan(tline(12:end), '%D', 'Delimiter', delimiter);
%         elseif j > 28 % This section needs to be updated to pull the temp/pressure data. Omitted for now 12/6/16
%             tline = fgetl(fid(i));
%         end
%     end
%     colnum(i) = length(date{1,i});
% end

for i = 1:length(fid)
    tline = fgetl(fid(i));
    while ~isequal(tline(1:8), 'Diameter')
        tline = fgetl(fid(i));
        if isequal(tline(1:4), 'Date')
            d = textscan(tline(6:end), '%{MM/dd/uuuu}D', 'Delimiter', delimiter);
            d = d{1,1};
            d = d(~isnat(d));
            date{i} = d;
        elseif isequal(tline(1:10), 'Start Time')
            t = textscan(tline(12:end), '%D', 'Delimiter', delimiter);
            t = t{1,1};
            t = t(~isnat(t));
            time{i}=t;
        end
    end
    colnum(i) = length(date{1,i});
end

% Define format for each file
data = cell(1, length(fid));

for i = 1:length(fid)
    formatSpec = repmat('%f%*f',[1,colnum(i)]); %use repmat to generate formatspec for each file
    formatSpec = ['%f',formatSpec];
    data{i} = textscan(fid(i), formatSpec, 'Delimiter', delimiter, 'EmptyValue', NaN); %Read in data
end


for i = 1:length(fid)
    tline = fgetl(fid(i));
    while ~isequal(tline(1:8), 'Raw Data')
        tline = fgetl(fid(i));
    end
end

% Define format for each file
rawdata = cell(1, length(fid));

for i = 1:length(fid)
    formatSpec = repmat('%f%*f',[1,colnum(i)+1]); %use repmat to generate formatspec for each file
    rawdata{i} = textscan(fid(i), formatSpec, 'Delimiter', delimiter, 'EmptyValue', NaN); %Read in data
    fclose(fid(i)); % Close file
end

%Return to previous folder
if exist('cf', 'var') == 1
    cd(cf);
end

clearvars i j d t tline delimiter startRow filelist formatSpec fid ans cf

%% Organize data into cell array. 
% Each column is a sample with date and start time (row 1), bin diameters
%(row 2), data (row 3), and other parameters (row 4).

% Add date to timestamp
for i = 1:length(date)
    for j = 1:length(date{1,i})
        time{1,i}(j).Day = date{1,i}(j).Day;
        time{1,i}(j).Month = date{1,i}(j).Month;
        time{1,i}(j).Year = date{1,i}(j).Year;
            if time{1,i}(j).Year < 2000
                time{1,i}(j).Year = time{1,i}(j).Year + 2000; % Fixes dates with mm/dd/yy format stamps (e.g. 1/1/15 is imported as 1/1/0015 rather than 1/1/2015
            end
        time{1,i}.Format = 'default';
    end
end

%Fill in data
RawDataArray = cell(6,sum(colnum)); %Create array to hold data
RawTime = zeros(sum(colnum),1);  %Create empty variable to hold times
k = 0;

for i = 1:length(date)
    for j = 1:colnum(i)
        RawDataArray{1,j+k} = time{1,i}(j);
        RawDataArray{2,j+k} = data{1,i}{1,1};
        RawDataArray{3,j+k} = data{1,i}{1,j+1};
        RawDataArray{4,j+k} = rawdata{1,i}{1,1};
        RawDataArray{5,j+k} = rawdata{1,i}{1,j+1};
        RawTime(j+k) = datenum(time{1,i}(j));
    end
    k = k+colnum(i);
end

if nargin > 0
    cd(current);
end

clearvars i j k date time colnum date time data current

%end

