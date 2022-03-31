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
smpsvol(4,:) = num2cell(totvol); %add to array in row 4

%Convet total volume to mass
rho = 1.2; %density of 1.2 g/cm-3
totmass = totvol*rho;

%Sum up total number and add to array
totnum = totalnum(smps);
smps(4,:) = num2cell(totnum); %add to array in row 4

%% Plot data
figure
%Plot total number
sp1 = subplot(3,1,1);
h1 = plot([smps{1,:}], [smps{4,:}]);
ylabel([{'Aerosol Number'}; {'Concentration (# cm^-^3)'}])
title(['CASA - CSU SMPS (dry) ',startdate])
xlim([smps{1,1}-hours(.5), smps{1,c}+hours(.5)])
% stop_time = datetime(2022, 02, 25, 21,00, 00);
% xlim([smps{1,1}, stop_time]) %set the min and max values on X axis 

% Plot total mass (rho = 1.2 g/cm-3)
sp2 = subplot(3,1,2);
h2 = plot([smps{1,:}], totmass);
h2.Color = rgb('rusty red');
ylabel([{'Aerosol Mass'}; {'Concentration (\mug m^-^3)'}])
% xlim([smps{1,1}-hours(.5), smps{1,c}+hours(.5)])
sp2.XLim = sp1.XLim;
% ylim([0,50])

%Plot size distribution
sp3 = subplot(3,1,3); % SMPS data as subplot 3 of 3
max99 = prctile([smps{3,:}],99, 'all'); %Find 99th percentile of all dN/dlogDp values
smps_lvls = linspace(0,max99,100); %Set 100 contour levels between 0 and max99
smpstime = datenum([smps{1,:}]); %Pull out time as datenum
[m3, h3] = contourf(smpstime, smps{2,1}, cell2mat(smps(3,:)), smps_lvls); %Plot data as a filled in contour plot

ylabel('Diameter (nm)'); %Label y axis as diameter
sp3.YTick = [20, 50, 100, 200, 500];
xlabel('Date')
datetick('x', 'mmm dd HH:MM') %Change datenum to date labels (day/month)
c1 = colorbar; %Add color bar
c1.Label.String = 'dN/dlogDp'; %Label colorbar
h3.LineStyle = 'none'; %Get rid of lines between contour levels
colormap jet %Change the color scheme
sp3.XLim = datenum(sp1.XLim); %Set Xlim to same as subplots 1 and 2
% xlim([min(smpstime), stop_time]) %set the min and max values on X axis 
% set(gca, 'XMinorTick', 'on')
sp3.XTick = datenum(sp1.XTick);
sp3.XTickLabel = sp1.XTickLabel;
sp3.XTickLabelRotation = 0;

%Adjust size
% fig = gcf; %formatting for exporting
% fig.PaperUnits = 'inches'; %formatting for exporting
% fig.PaperPosition = [0,0,8,5]; %formatting for exporting

%Pause until user inputs something
x = input('Press enter to continue once figure has rendered');

%Align subplots
sp1.Position(3) = sp3.Position(3);
sp2.Position(3) = sp3.Position(3);

% Print and save
print(gcf,['CASA_CSU-smps_quicklook_', startdate,'.png'], '-dpng','-r300') %exports figure to a .png file

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

writetable(smpsTable, ['CASA_CSU-smps_quickData_', startdate,'_r0.txt'])