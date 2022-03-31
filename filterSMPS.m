function [flag, pass_idx] = filterSMPS(rawSMPS, scantime, buffer, cutoff, Diag)
% arguments
%     rawSMPS (5,:) cell
%     scantime double
%     buffer double
%     cutoff double
%     Diag char
% end

%% filterSMPS
% Detects and flags bad scans caused by timing error in Farmer group SMPS.
% Bad scans have a purge peak outside of the normal bounds. This function
% defines the time period where the purge peak should be and detects
% whether they are present. Scans fail when no purge peak is present.

% The argument scantime must be defined based on the scan parameters. The
% buffer argument allows for adjustment of the window in which the purge peak
% is expected in a good scan. The cutoff argument allows for tuning of the
% threshold of what differentiates a peak vs noise.

% Output 1 is "flag", which is an index where 1 = pass and 0 = fail
% Output 2 is "pass_idx" which is a list of all passed scan #s


%% Filter data for bad SMPS scans
% Define arguments if none are specified
% These values are the defaults for CASA
switch nargin
    case 2
        buffer = 10;
        cutoff = 0.1;
        Diag = 'off';        
    case 3
        cutoff = 0.1;
        Diag = 'off';
    case 4
        Diag = 'off';     
end


% Get size of rawSMPS array
[~,c] = size(rawSMPS);

%Create variables to hold outputs
flag = zeros(1,c); %Create variable to hold flagss
purgemax = zeros(1,c); %Create variable to hold maximum purge values

% Loop through data and detect bad scans
for i = 1:c
    time = [rawSMPS{4,i}]; %Pull time
    counts = [rawSMPS{5,i}]; %Pull counts
    normcounts = counts./max(counts); %normalize to maximum value
    rawSMPS{6,i} = normcounts; %Add normalized counts to row 6 of array

    cuttime = find(time == scantime+buffer); % Get start time for purge region
    endtime = length(time); % Get end time

    pm = max(normcounts(cuttime:endtime)); %Find maximum counts during purge time region
    purgemax(i) = pm; %Add max to purgemax array

    if pm > cutoff %If the purge maximum is greater than the cutoff value, give scan a pass flag (1)
        flag(i) = 1;
    end
end

% Define pass_idx
pass_idx = find(flag == 1);

%% Plot figure for user to check pass/fail accuracy
if Diag(1:2) == 'on' | Diag(1:2) == 'On' |Diag(1:2) == 'ON'
    f = figure;
    subplot(1,3,1)
    title('All Scans')
    ylabel('Normalized CPC Counts')
    xlabel('Time')
    hold on
    for i = 1:c
        h1 = plot([rawSMPS{4,i}],[rawSMPS{6,i}]);
        if flag(i) == 0
            h1.Color = rgb('red');
        elseif flag(i) == 1
            h1.Color = rgb('blue');
        end
    end
    h2 = plot([scantime+buffer,scantime+buffer],[0,1]);
    h2.Color = rgb('black');
    h2.LineStyle = '--';
    h2.LineWidth = 1;
    h3 = plot([time(endtime),time(endtime)],[0,1]);
    h3.Color = rgb('black');
    h3.LineStyle = '--';
    h3.LineWidth = 1;
    
    subplot(1,3,2)
    title('Flagged Scans')
    ylabel('Normalized CPC Counts')
    xlabel('Time')
    hold on
    for i = 1:c
        if flag(i) == 0
            h1 = plot([rawSMPS{4,i}],[rawSMPS{6,i}]);
            h1.Color = rgb('red');
        end
    end
    h2 = plot([scantime+buffer,scantime+buffer],[0,1]);
    h2.Color = rgb('black');
    h2.LineStyle = '--';
    h2.LineWidth = 1;
    h3 = plot([time(endtime),time(endtime)],[0,1]);
    h3.Color = rgb('black');
    h3.LineStyle = '--';
    h3.LineWidth = 1;

    subplot(1,3,3)
    title('Passed Scans')
    ylabel('Normalized CPC Counts')
    xlabel('Time')
    hold on
    for i = 1:c
        if flag(i) == 1
            h1 = plot([rawSMPS{4,i}],[rawSMPS{6,i}]);
            h1.Color = rgb('blue');
        end
    end
    h2 = plot([scantime+buffer,scantime+buffer],[0,1]);
    h2.Color = rgb('black');
    h2.LineStyle = '--';
    h2.LineWidth = 1;
    h3 = plot([time(endtime),time(endtime)],[0,1]);
    h3.Color = rgb('black');
    h3.LineStyle = '--';
    h3.LineWidth = 1;

    f.Position = [50, 350, 1800, 500];
end

end