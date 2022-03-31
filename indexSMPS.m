
function [ValvePos, house_idx, outside_idx] = indexSMPS(SMPSdataArray, ValveData)
%Index SMPS data by autovalve position
%   For CASA Autovalve System
%   Last edited 3/28/22 KJM


% Interestct the valve time and 
SMPStime = [SMPSdataArray{1,:}];

[~,sidx,vidx] = intersect(SMPStime, ValveData.time);

% Get position from valve data
[~,col] = size(SMPSdataArray);

ValvePos = zeros(1,col);

for i = 1:length(sidx)
    ValvePos(sidx(i)) = ValveData.position(vidx(i));
end

house_idx = find(ValvePos == 1);
outside_idx = find(ValvePos == 2);

end