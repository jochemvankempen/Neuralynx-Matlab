function NEV = NLX_getEventType(NEV,EventType,PrintFlag)

% extract digital/user committed events
% NEV = NLX_getEventType(NEV,EventType)
% NEV ......... NEV structure, see NLX_LoadNEV.m
% EventType ... 'user', 'digital'

%% find user events and digital
DigEvIdx1 = regexp(NEV.Eventstring,'RecID:*');
DigEvIdx2 = regexp(NEV.Eventstring,'Raw Data File Input Port TTL*');
DigEvIdx3 = regexp(NEV.Eventstring,'Digital Lynx Parallel Input Port TTL*');
DigEvIdx = ~cellfun('isempty',DigEvIdx1) | ~cellfun('isempty',DigEvIdx2) | ~cellfun('isempty',DigEvIdx3);
UserEvIdx = ~DigEvIdx;

%% decide which ones to clear
switch lower(EventType)
    case 'user'
        NEV = NLX_ExtractNEV(NEV,UserEvIdx);
    case 'digital'
        NEV = NLX_ExtractNEV(NEV,DigEvIdx);
end

%%
if nargin>=3 && PrintFlag
    NumEvents = size(NEV.TimeStamps,1);
    for i=1:NumEvents
        fprintf(1,'%20.0f\t%8.0f\t%s\n',NEV.TimeStamps(i),NEV.TTL(i),NEV.Eventstring{i});
    end
end