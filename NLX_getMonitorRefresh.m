function monitorTs = NLX_getMonitorRefresh( NEVpath, ttlCode, timeWin, refreshPeriod, maxCycle)

% Get monitor-refresh timestamps from TTL events and expected refresh
% period
%
% monitorTs = NLX_getMonitorRefresh( NEVpath, ttlCode, timeWin, refreshPeriod, maxCycle)
%
% NEVpath .........
% ttlCode .........
% timeWin .........
% refreshPeriod ...
% maxCycle ........ num. of cycles to extrapolate from known events. Set to
%                   inf for complete interpolation between TTL events

%% 1. find events that are known to be related to actual refresh events
% These events should be defined in >>>ttlCode<<<
NEV           = NLX_LoadNEV(NEVpath,'FULL',1,[]);
if isempty(timeWin)
    refEvtsTs     = NEV.TimeStamps(ismember(NEV.TTL,ttlCode));
else
    refEvtsTs     = NEV.TimeStamps(ismember(NEV.TTL,ttlCode) & NEV.TimeStamps>=timeWin(1) & NEV.TimeStamps<=timeWin(2));
end
nRefEvts      = size(refEvtsTs,1);

%% 2. reconstruct timestamps of monitor refreshs in between the known
% events, store them in monitorTS
monitorTs = getMonitorRefresh(refEvtsTs(:), refreshPeriod, maxCycle);
nMonTs    = size(monitorTs,1);

function monitorTs = getMonitorRefresh(ts, refPrd, maxCycle)
% reconstruct monitor refresh times from known refreshes
% ts ......... timestamps of known refresh events
% refPrd ..... theoretical refresh period of the monitor at hand
% maxCycle ... maximum cycles per give timestamp

if numel(ts)==1
    monitorTs = ts(1);
    return;
else
    [nTs,nBounds] = size(ts);
    if nBounds==1
        % construct time windows from sequence of times
        ts = [ts [ts(2:end,1);inf]];
    end
end

timeRange = [min(ts(~isinf(ts(:)))) max(ts(~isinf(ts(:))))];
n = floor(diff(timeRange)/refPrd);
i = 0;
monitorTs = zeros(n,1).*NaN;

for its = 1:nTs
    if ~isinf(ts(its,2)) && ~isnan(ts(its,2))
        nRefPrds = floor(diff(ts(its,:))/refPrd)-1;
        if nRefPrds>maxCycle
            nRefPrds = maxCycle;
        end
        lastTS = ts(its,1) +  nRefPrds * refPrd; % make sure you only get starttimes of complete refreshperiods
        monitorTs(i+1:i+1+nRefPrds) = [ts(its,1) : refPrd : lastTS]';% these are the expected monitor refreshes from the given timestamp
        i = i+nRefPrds;
    end
end

monitorTs(isnan(monitorTs)) = [];
