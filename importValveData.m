function [valve_data] = importValveData(path)
%importValveData - Import data from autovalve system
%   Output is a table variable
%   Missing data is indicated with the error code "-999"
%   valve_data.time is in datetime format


%% Import data

    % Open folder
    if nargin > 0
        current = cd(path);
    else
        path = cd();
    end
    
    % Select valve data files (can select multiple text files)
    filelist = uigetfile('.txt', 'Select valve data file', 'MultiSelect', 'on');
    
    %% Set up the Import Options and import the data
    opts = delimitedTextImportOptions("NumVariables", 8);
    
    % Specify range and delimiter
    opts.DataLines = [4, Inf];
    opts.Delimiter = ",";
    
    % Specify column names and types
    opts.VariableNames = ["date", "time", "trigger1", "trigger2", "trigger3", "pos1", "pos2", "pos3"];
    opts.VariableTypes = ["datetime", "datetime", "double", "double", "double", "double", "double", "double"];
    
    % Specify file level properties
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";
    
    % Specify variable properties
    opts = setvaropts(opts, "date", "InputFormat", "MM/dd/yyyy");
    opts = setvaropts(opts, "time", "InputFormat", "HH:mm:ss");
    
    % Convert filelist to cell array and get number of files
    if class(filelist) == 'char'
        filelist = cellstr(filelist);
    end

    [~,c] = size(filelist);
    
    %Read in data
    valve_data = table();
    
    for i = 1:c
        temp = readtable([path,'\',filelist{i}], opts);
        valve_data = [valve_data;temp];
        clearvars temp
    end
    
    % Combine date and time into a single column
    valve_data.time.Day = valve_data.date.Day;
    valve_data.time.Month = valve_data.date.Month;
    valve_data.time.Year = valve_data.time.Year;
    valve_data.time.Format = 'default';
    valve_data.date = []; %delete unnecessary date column
    
    % Sort table by time and date so it is in order
    valve_data = sortrows(valve_data);

    %% Add columns for indicating house versus outdoor position
    %Create a new column to hold data
    %valve_data.position is a column that indicates whether the house or
    %outdoor air was being sampled.
    %valve_data.position = 1 indicates house
    %valve_data.position = 2 indicates outside
    %valve_data.position = -999 indicates an error
    
    %Create column to hold data
    r = height(valve_data);
    position = NaN(r,1);

    for i = 1:r
        ind = [valve_data.pos1(i),valve_data.pos2(i),valve_data.pos3(i)]; %define indicator as the positions of valves 1, 2, and 3
        if isequal(ind,[1,0,1]) %Position indicator for house
            position(i) = 1;
        elseif isequal(ind,[0,1,2]) %Position indicator for outside
            position(i) = 2;
        else
            position(i) = 0;
        end
        clearvars ind
    end
    
    %Add column to table
    valve_data.position = position;
    
    %% Clear temporary variables
    clear opts
end