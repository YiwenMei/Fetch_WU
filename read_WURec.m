% Yiwen Mei (ymei2@gmu.edu)
% CEIE, George Mason University
% Last update: 10/25/2017

%% Functionality
% This function re-format the original weather records in .json retrieved from
% WU to matlab array.

%% Input
% utcdt : a Matlab structure retrieved from the .json record recording the
%         date time in UTC;
% ObsRec: a Matlab structure retrieved from the .json record recording the
%         observation;
% DayRec: a Matlab structure retrieved from the .json record recording the
%         daily summary;
% stype : Observation type (1 stands for airport; 2 stands for pws);

%% Output
% DaySum: a Matlab array recording the daily summary. DaySum is T by N where
%         T is the time steps and N is the types of record (see additional note
%         for the order of variables in DaySum);
% ObsSum: a Matlab array recording the observation. ObsSum is T by N where T is
%         the time steps and N is the types of record (see additional note for
%         the order of variables in ObsSum);

%% Additional Note
% Order of DaySum for airpot:                     1)Date number
%  2)Mean air temp (deg C);  3)Max air temp;      4)Min air temp;
%  5)Mean dewpt temp;        6)Max dewpt temp;    7)Min dewpt temp;
%  8)Mean air press (hPa);   9)Max air press;    10)Min air press;
% 11)Mean wind spd (km/h);  12)Max wind spd;     13)Min wind spd;
% 14)Wind direction (deg, refer to compdir2deg_rv.m for details);
% 15)Mean visib (km);       16)Max visib;        17)Min visib;
% 18)Mean rel humidity (%); 19)Max rel humidity; 20)Min rel humidity;
% 21)Snowfall (mm/h);       22)Snowdepth (mm);   23)Precip (mm/h);
% 24)Month to date (1st~now) snowfall (mm);      25)Since Jul.1 snowfall;
% 26)Growing degree days (day);
% 27)Heating degree days (HDD);      28)Norm HDD;
% 29)1st~now HDD;                    30)Norm 1st~now HDD;
% 31)Since Sep.1 HDD;                32)Norm since Sep.1 HDD;
% 33)Since Jul.1 HDD;                34)Norm since Jul.1 HDD;
% 35)Cooling degree days (CDD);      36)Norm CDD;
% 37)1st~now CDD;                    38)Norm 1st~now CDD;
% 39)Since Sep.1 CDD;                40)Norm since Sep.1 CDD;
% 41)Since Jul.1 CDD;                42)Norm since Jul.1 CDD;

% Order of DaySum for pws:                    1)Date number
%  2)Mean air temp;      3)Max air temp;      4)Min air temp;
%  5)Mean dewpt temp;    6)Max dewpt temp;    7)Min dewpt temp;
%                        8)Max air press;     9)Min air press;
% 10)Mean wind spd;     11)Max wind spd;     12)Wind direction (compdir2deg_rv.m)
% 13)Mean rel humidity; 14)Max rel humidity; 15)Min rel humidity;
% 16)Precip

% Order of ObsSum for airpot:
%  1)Date number; 2)Air temp;   3)Dewpt temp;      4)Rel humidity; 5)Wind spd;
%  6)Wind gust;   7)Wind direction (refer to compdir2deg_rv.m);    8)Visib;
%  9)Air press;  10)Windchill; 11)Heat index;     12)Precip;

% Order of ObsSum for pws:
%  1)Date number; 2)Air temp;    3)Dewpt temp;      4)Rel humidity; 5)Wind spd;
%  6)Wind gust;   7)Wind direction (refer to compdir2deg_rv.m);     8)Air press;
%  9)Windchill;  10)Heat index; 11)Precip rate;    12)Cum precip
% 13)Solar rad;  14)UV;

function [ObsSum,DaySum]=read_WURec(utcdt,ObsRec,DayRec,stype)
%% Daily summary
utcdn=datenum([utcdt.year utcdt.mon utcdt.mday utcdt.hour utcdt.min],...
    'yyyymmddHHMM');

DayNms=fieldnames(DayRec{1});
if stype==1
  roid=[16 29 31 18 35 37 20 39 41 22 43 45 25 26 47 49 28 33 34 5 11 54 ...
    7 9 51 52 57:63 53 64:70];
  wid=13; % colume of wind direction
else
  roid=[3 12 14 5 18 20 22 24 7 26 10 11 16 17 28];
  wid=11;
end

DaySum=nan(1,length(roid));
for f=1:length(roid)
  DaySum(f)=str2double(getfield(DayRec{1},DayNms{roid(f)}));
end
if isnan(DaySum(wid(1))) % Convert from wind direction is wind direction in deg
  DaySum(wid(1))=compdir2deg_rv(getfield(DayRec{1},'meanwdire')); % is unavailable
end
DaySum=[utcdn DaySum];

%% Observations at device time resolution
ObsNms=fieldnames(ObsRec{1});
if stype==1
  roid=[3 5 7 8:2:22];
else
  roid=[3 5 7 8:2:24 25];
end

ObsSum=nan(length(ObsRec),length(roid));
utcdn=nan(length(ObsRec),1);
for t=1:length(ObsRec)
  utcdn(t)=datenum([ObsRec{t}.utcdate.year ObsRec{t}.utcdate.mon...
    ObsRec{t}.utcdate.mday ObsRec{t}.utcdate.hour ObsRec{t}.utcdate.min],...
    'yyyymmddHHMM');
  for f=1:length(roid)
    ObsSum(t,f)=str2double(getfield(ObsRec{t},ObsNms{roid(f)}));
  end
  if isnan(ObsSum(t,6))
    ObsSum(t,6)=compdir2deg_rv(getfield(ObsRec{1},'wdire'));
  end
end
ObsSum=[utcdn ObsSum];
ObsSum(ObsSum==-9999 | ObsSum==-999)=NaN;
end
