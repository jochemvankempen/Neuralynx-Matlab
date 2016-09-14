function NEV = NLX_AddEvents(NEV,Timestamps,Eventstring,SaveSuffix)
%% NLX_ADDEVENTS adds events to an existing eventfile
%
% NEV = NLX_AddEvents(NEV,Timestamps,Eventstring,SaveSuffix)
% NEV ................ Can be an NEV structure or a full filepath
% Timestamps ......... Timestamps of the events to add
% Eventstring ........ Cell Array of Eventstrings
% SaveSuffix ......... Saves changed NEV file [fName.SaveSuffix.NEV] Omit to not save. 

if ischar(NEV)
	NEVpath = NEV;
	NEV = NLX_LoadNEV(NEVpath,'full',1,[]);
else
	NEVpath = NEV.Path;
end
[fDir,fName,fExt] = fileparts(NEVpath);

%*************************
% concatenate
%*************************
EventNum = length(Timestamps);
NEV.TimeStamps = cat(2,NEV.TimeStamps,Timestamps);
NEV.EventID = cat(2,NEV.EventID,zeros(1,EventNum));
NEV.TTL = cat(2,NEV.TTL,zeros(1,EventNum));
NEV.Extras = cat(2,NEV.Extras,zeros(8,EventNum));
NEV.Eventstring = cat(1,NEV.Eventstring,Eventstring);

%*************************
% resort
%*************************
[NEV.TimeStamps,SortIndex] = sort(NEV.TimeStamps);
NEV.EventID = NEV.EventID(SortIndex);
NEV.TTL = NEV.TTL(SortIndex);
NEV.Extras = NEV.Extras(:,SortIndex);
NEV.Eventstring = NEV.Eventstring(SortIndex);

%*************************
% save
%*************************
if nargin>2 & ischar(SaveSuffix)
	if isempty(SaveSuffix);SaveSuffix = 'OFF';end
	NEVSavePath = fullfile(fDir,[fName '.' SaveSuffix fExt]);
	NEV.Path = NEVSavePath;
	NEV = NLX_SaveNEV(NEV,0);
end

	
