function [Index,TimeStamps,NEV] = NLX_findEvents(NEV,varargin)

% Finds event timestamps in a *.NEV file.
%
% [Index,TimeStamps,NEV] = NLX_findEvents(NEV,'property1',value1, ...)
%
% INPUT
% NEV ............. structure containing NEV data, loads file if empty
% Property/Value pairs
% 'TTL' ............ vector of TTL codes
% 'EVENTSTRING' .... cell array of strings
% 'TIMEWINDOW' ........... [lower upper] window, multiple windows in rows
% 'ISTTL'
% 'ISMANUAL'

if isempty(NEV)
	NEV = NLX_LoadNEV([],'FULL',1,[],1);
	if isempty(NEV.Path);return;end
end
[NumEvents,FieldArray] = NLX_CheckNEV(NEV);
Index = logical(zeros(NumEvents,1));

for i = 1:2:length(varargin)
	switch upper(varargin{i})
		case 'TTL'
            Index = ismember(NEV.TTL,varargin{i+1});
		case 'EVENTSTRING'
            Index = ismember(NEV.Eventstring,varargin{i+1});
		case 'STRMATCH'
            Index = strmatch(varargin{i+1},NEV.Eventstring);
		case 'TIMEWINDOW'
			for j = 1:size(varargin{i+1},1)
				Index(NEV.TimeStamps(:,1)>=varargin{i+1}(j,1) & NEV.TimeStamps(:,1)<=varargin{i+1}(j,2)) = 1;
			end
        case 'ISTTL'
            Index = NEV.EventID == 1;
        case 'ISMANUAL'
            Index = NEV.EventID == 4;
            
        otherwise
            error('Don''t know what to look for!');
	end
end
TimeStamps = NEV.TimeStamps(Index);
