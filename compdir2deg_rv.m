% Yiwen Mei (ymei2@gmu.edu)
% CEIE, George Mason University
% Last update: 11/02/2017

%% Functionality
% This function converts wind direction from camp dir/deg to deg/camp dir;
% note that 0 deg is north and there are 16 compass directions.

%% Input
% sub: subject angle in degree or compass direction; if it is in degree it has
%      to be from 0 to 360 deg; if it is in compass direction it has to be the 
%      16 compass directions specified below. Note that -1 means the device
%      cannot measure the previlling wind (i.e., outputting "Variable").

%% Output
% wdir: wind direction in degree or compass direction.

function wdir=compdir2deg_rv(sub)

dirVal=[-1 0:22.5:337.5];
dirNms={'Variable','North','NNE','NE','ENE','East','ESE','SE','SSE','South',...
    'SSW','SW','WSW','West','WNW','NW','NNW'}; % 16 compass directions

if ~ischar(sub) % function direction
  [~,i]=min(abs(sub-dirVal));
  sub=dirVal(i);
end
comp2deg_rv=@(sub) dirVal(strcmp(dirNms,sub));

if ~isempty(sub)
  wdir=comp2deg_rv(sub);
%   if wdir==-1; wdir=NaN; end
else
  wdir=NaN;
end
end
