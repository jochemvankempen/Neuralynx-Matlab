function tsRecWinIndex = NLX_getRecPeriodsNCS(NCS)

% return the periods of recording as timestamp index
%
% tsRecWinIndex = NLX_getRecPeriodsNCS(NCS)
%
% examine the ncs file first
sampFreq  = unique(NCS.SF);
sampPrd   = 1000000.0/sampFreq;
sampleNum = max(NCS.ValidSampleNum);
tsNum     = length(NCS.ValidSampleNum);

maxSamplePrd  = 1000000.0/min(NCS.SF);
tolTSPrd      = 5;% this should reflect the time between last sample of last timestamp and current timestamp
maxTSPrd      = maxSamplePrd*sampleNum + tolTSPrd; % time difference between timestamps usually doesn't match sample frequency
recGapIndex   = find(diff(NCS.TimeStamps)>maxTSPrd);
tsRecWinIndex = [1 recGapIndex+1;recGapIndex  tsNum]';
nTsRecWins    = size(tsRecWinIndex,1);% start and end indices of recordings
