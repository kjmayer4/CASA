%% Process SMPS Data from CASA
% Last edited 3/29/22 KJM
% Plots time series of SMPS sizing data as total number, total mass, and
% a size distribution

%% Import data
%Define path where data is located
path = 'C:\Data\CASA\SMPS_data\Exported_raw_data';

%Import to matlab as a cell arry including raw data
rawSMPS = importRawSMPS(path);

%Pull date in first and last sample for naming
startdate = datestr(rawSMPS{1,1});
startdate = startdate(1:11);

%Return to folder to save figures/analysis products
cd('C:\Data\CASA\SMPS_data\Quicklooks\Filtered_Data')

%% Process data
%Sort date
rawSMPS = SortSizingDate(rawSMPS); % Sort SMPS date

% Filter out bad SMPS scans
% Set up parameters for filter
scantime = 155;
buffer = 10;
cutoff = 0.1;

[flag, pass_idx] = filterSMPS(rawSMPS, scantime, buffer, cutoff, 'on');

%Create variable that just includes good SMPS data
smps = rawSMPS(1:3,pass_idx);

%Turn NaN to zeros - for some reason, some of these files have NaN values
%at the very smallest diameters
[~,c] = size(smps);
for i = 1:c
    for j = 1:length(smps{3,i})
        if isnan(smps{3,i}(j))
            smps{3,i}(j) = 0;
        end
    end
end



% Convert to volume
smpsvol = conv2vol(smps);

%Sum up total volume and add to array
totvol = totalnum(smpsvol);

%Convert total volume to mass
rho = 1.2; %density of 1.2 g/cm-3
totmass = totvol*rho;

%Sum up total number and add to array
totnum = totalnum(smps);

%% Create a data table
% Flag by valve position
load('C:\Data\CASA\Valve_log\ValveData.mat')
[valveFlag,~,~] = indexSMPS(smps,ValveData);

%Get mode diameter
[~,midx] = max([smps{3,:}]);

modeDiameter = zeros(1,c);

for i = 1:c
    D = [smps{2,i}];
    modeDiameter(i) = D(midx(i));
end

%Create empty table
smpsTable = table();

%Populate table
smpsTable.Time = [smps{1,:}]';
smpsTable.Number = totnum';
smpsTable.Volume = totvol';
smpsTable.Mass = totmass';
smpsTable.Mode_Dp = modeDiameter';
smpsTable.ValveFlag = valveFlag';


%% Add size distribution data
%Get size of cells in SMPS array
cellsz = cellfun(@length,smps); %Find size of all cells in array
%Check that they're all the same size
if range(cellsz(2,:)) ~= 0
    error('Error Line 91: The number of diameter bins in each scan is not the same. Operation terminated.')
end

%Define cellsz as the length of the first scan's diameter bins
cellsz = cellsz(2,1);

%Define table size
sz = [c,2*cellsz]; % Define size of table using c (number of columns in smps array i.e. number of scans) and the 2x the number of dN/dlogdp bins

%Generate variable names for table
nvars = cellsz; 
baseName = 'diameter_bin';
varnames_diameter = matlab.internal.datatypes.numberedNames(baseName,1:nvars);
baseName = 'dndlogdp_bin';
varnames_dndlogdp = matlab.internal.datatypes.numberedNames(baseName,1:nvars);

varNames = [varnames_diameter,varnames_dndlogdp];

%Generate variable type (double)
varTypes = repmat({'double'},1,2*cellsz); 

%Create table
tempTable = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

%%Add data to table
for i = 1:c
    tempTable{i,1:cellsz} = [smps{2,i}]';
    tempTable{i,cellsz+1:end} = [smps{3,i}]';
end

smpsTable = [smpsTable,tempTable];

% writetable(smpsTable, ['CASA_CSU-smps_', startdate,'_r0.txt'])