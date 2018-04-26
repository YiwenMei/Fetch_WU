% Yiwen Mei (ymei2@gmu.edu)
% CEIE, George Mason University
% Last update: 11/25/2017

%% Functionality
% This function has two functionalities:
%  1)Download historical weather record for a given period of stations identified
%    by the station ID using the history feature from the Weather Underground API.
%  2)Output a list of stations which their records need to be downloaded by the
%    "fetch_WUamLocRec.m" function due to the ambiguous station ID.

%% Input
% airport_info: list of interested airport station;
%   pws_info  : list of interested personal weather station;
%   sds/eds   : start/end date in strings;
%     key     : your personal API key attained from WU;
%   calrate   : call rate allowed per minute;
%     path    : path to store the output records;

%% Output
% DaySum: daily summary of variables for a station for the given period stored
%         in the path specified (refer to read_WURec for details);
% ObsSum: summary of observed variables in the device's time resolution for a
%         station for the given period stored in the path specified.refer to instructions in  the "read_WURec.m"
%         function for the order of record types (refer to read_WURec for details);
% amLoc : list of stations that this function is not able to fetch data for due
%         to the ambiguous station ID; order of items in the list follows type,
%         station ID and zmw. 

%% Additional note
% What is the ambiguous station ID?
% This function downloads historical record using the station ID to construct
% the URL. However, it appears that the use of this station ID in some cases
% refers to multiple locations. To further narrow down the search result to one
% station, the "fetch_WUamLocRec.m" function was developed. Use the amLoc outputted
% by this function as an input of the "fetch_WUamLocRec.m" function.

% Naming convention of output in path:
% For example, "ObsSum_airportVABB_20071001_20080930" means summary of observed
% record for airport VABB from 20071001 to 20080930.

% Order of variables in output file:
% Refer to "read_WURec.m" function for the order;

function amLoc=fetch_WURec(airport_info,pws_info,sds,eds,key,calrate,path)
api='http://api.wunderground.com/api/';
call_count=0;

sdn=datenum(sds,'yyyymmdd');
edn=datenum(eds,'yyyymmdd');
dnr=sdn:edn;

tp1={'airport','pws'};
tp2={'','pws:'};
Lr=[size(airport_info,1) size(pws_info,1)];
n_var=[42 16;12 14]; % Number of variable in daily summary/observation and airport and pws
amLoc=cell(0,3);
for p=1:length(Lr)
  for n=1:Lr(p)
    nof=0; % number of files outputted

    DaySum=nan(0,n_var(1,p));
    ObsSum=nan(0,n_var(2,p));

    eval(sprintf('%s',['id=',tp1{p},'_info{n,4};'])); % Airport/pws id
    ids=[tp2{p} id];
    for di=1:length(dnr)
%% Make and read the URL
      utcdn=dnr(di);
      ds=datestr(utcdn,'yyyymmdd');
      url=[api key '/history_' ds '/q/' ids '.json'];

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
          fprintf('%i%s%.2f%s%.2f%s\n',calrate,' calls made in ',dt,' s (',60*calrate/dt,' call/min).');
        end
      end

%% Write the records into Matlab variables
      if isfield(rec,'history') % History field exist
        utcdt=rec.history.utcdate;
        ObsRec=rec.history.observations;
        DayRec=rec.history.dailysummary;

      elseif isfield(rec.response,'results') % Ambiguous location
        amList=cell2mat(rec.response.results);
        eval(sprintf('idx=strcmp(%s_info{1},{amList.city});',tp1{p}));
        amLoc=[amLoc;{tp1{p} id amList(idx).zmw}];
        nof=-1;
        break
      end

      if ~isempty(ObsRec) && ~isempty(DayRec)
        [obssum,daysum]=read_WURec(utcdt,ObsRec,DayRec,p);

        DaySum=[DaySum;daysum];
        ObsSum=[ObsSum;obssum];
      end

%% Outputing the records
      if size(ObsSum,1)>=1000000 % Save if the number of time step exceeds 1000000;
        sdt=datestr(ObsSum(1,1),'yyyymmdd');
        edt=datestr(ObsSum(size(ObsSum,1),1),'yyyymmdd');
        save([path 'ObsSum_' tp1{p} id '_' sdt '_' edt],'ObsSum');
        ObsSum=nan(0,n_var(2,p));
        nof=nof+1;
      end
    end
    if ~isempty(ObsSum) % Save the last part
      sdt=datestr(ObsSum(1,1),'yyyymmdd');
      edt=datestr(ObsSum(size(ObsSum,1),1),'yyyymmdd');
      save([path 'ObsSum_' tp1{p} id '_' sdt '_' edt],'ObsSum');
      nof=nof+1;
    end
    if ~isempty(DaySum)
      save([path 'DaySum_' tp1{p} id '_' sds '_' eds],'DaySum');
      nof=nof+1;
    end

    if nof>0
      fprintf('%i%s\n',nof,[' files outputted for ' tp1{p} ' ' id '.']);
    elseif nof==0
      fprintf('%s\n',['No records found for ' tp1{p} ' ' id '.']);
    else
      fprintf('Ambiguous location for %s %s. Use fetch_WUamLocRec.m for downloading.\n',tp1{p},id);
    end
  end
end
end
