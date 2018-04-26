% Yiwen Mei (ymei2@gmu.edu)
% CEIE, George Mason University
% Last update: 11/25/2017

%% Functionality
% Download historical weather record for a given period of stations identified
% by the zmw code using the history feature from the Weather Underground API.

%% Input
%  amLoc : list of airport and personal weather station that their records were
%          not downloaded by fetch_WURec.m;
% sds/eds: start/end date in strings;
%   key  : your personal API key attained from WU;
% calrate: call rate allowed per minute;
%  path  : path to store the output records;

%% Output
% DaySum: daily summary of variables for a station for the given period stored
%         in the path specified. DaySum is T by N where T is the time steps
%         with data within the period and N is the types of record (refer to
%         additonal note for the naming convention of output and order of
%         variables in the output);
% ObsSum: summary of observed variables in the device's time resolution for a
%         station for the given period stored in the path specified. ObsSum is
%         T by N where T is the time steps with data within the period and N
%         is the types of record; refer to instructions in  the "read_WURec.m"
%         function for the order of record types;

%% Additional note
% Naming convention of output in path:
% Refer to the notes in fetch_WURec.m.

% Order of variables in output file:
% Refer to "read_WURec.m" function for the order;

function fetch_WUamLocRec(amLoc,sds,eds,key,calrate,path)
api='http://api.wunderground.com/api/';
call_count=0;
nof=0; % number of files outputted

sdn=datenum(sds,'yyyymmdd');
edn=datenum(eds,'yyyymmdd');
dnr=sdn:edn;

n_var=[42 16;12 14]; % Number of variable in daily summary/observation and airport and pws
for n=1:size(amLoc,1)
  if strcmp(amLoc{1},'airport')
    p=1;
  else
    p=2;
  end
  DaySum=nan(0,n_var(1,p));
  ObsSum=nan(0,n_var(2,p));

  for di=1:length(dnr)
%% Make and read the URL
    utcdn=dnr(di);
    ds=datestr(utcdn,'yyyymmdd');

    url=[api key '/history_' ds '/q/zmw:' amLoc{3} '.json'];

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
    utcdt=rec.history.utcdate;
    ObsRec=rec.history.observations;
    DayRec=rec.history.dailysummary;

    if ~isempty(ObsRec) && ~isempty(DayRec)
      [obssum,daysum]=read_WURec(utcdt,ObsRec,DayRec,p);

      DaySum=[DaySum;daysum];
      ObsSum=[ObsSum;obssum];
    end

%% Outputing the records
    if size(ObsSum,1)>=1000000 % Save if the number of time step exceeds 1000000;
      sdt=datestr(ObsSum(1,1),'yyyymmdd');
      edt=datestr(ObsSum(size(ObsSum,1),1),'yyyymmdd');
      save([path 'ObsSum_' amLoc{1} amLoc{2} '_' sdt '_' edt],'ObsSum');
      ObsSum=nan(0,n_var(2,p));
      nof=nof+1;
    end
  end
  if ~isempty(ObsSum) % Save the last part
    sdt=datestr(ObsSum(1,1),'yyyymmdd');
    edt=datestr(ObsSum(size(ObsSum,1),1),'yyyymmdd');
    save([path 'ObsSum_' amLoc{1} amLoc{2} '_' sdt '_' edt],'ObsSum');
    nof=nof+1;
  end
  if ~isempty(DaySum)
    save([path 'DaySum_' amLoc{1} amLoc{2} '_' sds '_' eds],'DaySum');
    nof=nof+1;
  end

  if nof~=0
    fprintf('%i%s\n',nof,[' files outputted for ' amLoc{1} ' ' amLoc{2} '.']);
  else
    fprintf('%s\n',['No records found for ' amLoc{1} ' ' amLoc{2} '.']);
  end
end
end
