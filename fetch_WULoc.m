% Yiwen Mei (ymei2@gmu.edu)
% CEIE, George Mason University
% Last update: 11/02/2017

%% Functionality
% This function use the geolookup feature from Weather Underground to locate
% all the observed stations within a given lat/lon domain

%% Input
% xl / xr: longitude of the left/right side of the domain;
% yb / yt: latitude of the bottom/top side of the domain;
%   key  : your personal API key attained from WU;
% totcal : max number of call per day allows by the API key;
% calrate: max number of call per minute allows by the API key;

%% Output
% List_ap : list of airport within the searching domain; order of details
%           follows city, state, country, icao, lat and lon;
% List_pws: list of personal weather station within the searching domain;
%           order of details follows city, state, country, id, neighborhood,
%           lat and lon;

function [airport_info,pws_info]=fetch_WULoc(xl,xr,yb,yt,key,totcal,calrate)
api='http://api.wunderground.com/api/'; % The API address
sr=40; % searching radius by Weather Underground (no more than 50 stations)
call_count=0;

ALL=nan(0,2);
airport_info={};
PLL=nan(0,2);
pws_info={};

% %% Determine the total number of search
ns=[];
srd=floor(km2deg(sr,6371.137)*100)/100; % length of sr at the equator (deg)
for lat=yb:2*srd:yt
  srd1=floor(km2deg(sr/cosd(lat),6371.137)*100)/100; % length of sr at a given lat (deg)

  ns=[ns;length(xl:2*srd1:xr)];
end
ns=sum(ns);

if totcal<ns
  fprintf('%s%i%s\n','Required number of calls (',ns,') exceed the 500. Consider to reduce the search area.');
  return
end

for lat=yb:2*srd:yt
%   srd1=floor(km2deg(sr/cosd(lat),'earth')*100)/100;
  srd1=floor(km2deg(sr/cosd(lat),6371.137)*100)/100;
  for lon=xl:2*srd1:xr
%% Make and read the URL
    las=num2str(lat,'%.2f');
    los=num2str(lon,'%.2f');
    url=[api key '/geolookup/q/' las ',' los '.json'];

% Initial tic
    if rem(call_count,calrate)==0
      t1=tic();
    end
      
    rec=JSON.parse(urlread(url));
    call_count=call_count+1;

% Pause if the actucal call rate exceeds the call rate allowed
    if rem(call_count,calrate)==0 && call_count>=calrate
      dt=toc(t1);
      if dt<=60
        fprintf('%i%s%.2f%s%.2f%s\n',calrate,' calls made in ',dt,' s (',60*calrate/dt,' call/min). Pause for 1 min.');
        pause(61);
      else
        fprintf('%i%s%.2f%s%.2f%s\n',calrate,' calls made in ',dt,' s (',60*calrate/dt,' call/min.');
      end
    end

%% Write the records into Matlab variables
    if isfield(rec,'location')

% List of airport
      rec_ap=rec.location.nearby_weather_stations.airport.station;

      lll=nan(length(rec_ap),2);
      for i=1:length(rec_ap)
        lll(i,:)=[str2double(rec_ap{i}.lat) str2double(rec_ap{i}.lon)];
      end
      [~,j1]=setdiff(lll(:,1),ALL(:,1));
      [~,j2]=setdiff(lll(:,2),ALL(:,2));
      ji=intersect(j1,j2);

      if ~isempty(ji)
        ALL=[ALL;lll(ji,:)];
        for k=1:length(ji)
          l=size(airport_info,1);
          airport_info{l+1,1}=rec_ap{ji(k)}.city;
          airport_info{l+1,2}=rec_ap{ji(k)}.state;
          airport_info{l+1,3}=rec_ap{ji(k)}.country;
          airport_info{l+1,4}=rec_ap{ji(k)}.icao;
          airport_info{l+1,5}=rec_ap{ji(k)}.lat;
          airport_info{l+1,6}=rec_ap{ji(k)}.lon;
        end
      end

% List of personal weather station
      rec_pws=rec.location.nearby_weather_stations.pws.station;

      lll=nan(length(rec_pws),2);
      for i=1:length(rec_pws)
        lll(i,:)=[rec_pws{i}.lat rec_pws{i}.lon];
      end
      [~,j1]=setdiff(lll(:,1),PLL(:,1));
      [~,j2]=setdiff(lll(:,2),PLL(:,2));
      ji=intersect(j1,j2);

      if ~isempty(ji)
        PLL=[PLL;lll(ji,:)];
        for k=1:length(ji)
          l=size(pws_info,1);
          pws_info{l+1,1}=rec_pws{ji(k)}.city;
          pws_info{l+1,2}=rec_pws{ji(k)}.state;
          pws_info{l+1,3}=rec_pws{ji(k)}.country;
          pws_info{l+1,4}=rec_pws{ji(k)}.id;
          pws_info{l+1,5}=rec_pws{ji(k)}.neighborhood;
          pws_info{l+1,6}=num2str(rec_pws{ji(k)}.lat);
          pws_info{l+1,7}=num2str(rec_pws{ji(k)}.lon);
        end
      end
    end
  end
end

%% Remove empty entrees
airport_info=airport_info(~cellfun('isempty',airport_info(:,4)),:);
airport_info(strcmp(airport_info(:,4),'----'),:)=[];
[~,id,~]=unique(airport_info(:,4));
airport_info=airport_info(id,:);

pws_info=pws_info(~cellfun('isempty',pws_info(:,4)),:);
[~,id,~]=unique(pws_info(:,4));
pws_info=pws_info(id,:);

fprintf('%i airports and %i pws found for the region.',size(airport_info,1),size(pws_info,1));
end
