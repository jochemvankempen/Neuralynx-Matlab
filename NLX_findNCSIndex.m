function [index, subscript] = NLX_findNCSIndex(NCS, x, version)

% get subscript and indices for the samples matrix in the NCS file
% structure
% NaN index defines timestamps in between recording breaks
%
% [index, subscript] = NLX_findNCSIndex(NCS, x)

if nargin<3
    version = 'matrix';
end

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

% examine x
n          = length(x);
index      = zeros(n,1).*NaN;
if nargout>1
    subscript = zeros(n,2);
end

for iRecWin = 1:nTsRecWins
    currRecTimeWin = [NCS.TimeStamps(tsRecWinIndex(iRecWin,1)) NCS.TimeStamps(tsRecWinIndex(iRecWin,2)) + maxTSPrd];
    xRecWinIndex   = find(x>=currRecTimeWin(1) & x<=currRecTimeWin(2));
    nn = length(xRecWinIndex);
    
    switch version
        case 'loop'
            [index, subscript] = findIndexLOOP(NCS.TimeStamps,x,sampleNum,sampPrd,xChunkSize);
        case 'matrix'
                xChunkSize = 10000;
                xChunkNum = ceil(nn/xChunkSize);
                for iChk = 1:xChunkNum
                    %fprintf(1,'chunk %u of %u\n',iChk,xChunkNum);
                    xChkIndex    = [1 xChunkSize] + (iChk-1)*xChunkSize;
                    xChkIndex(2) = min([xChkIndex(2) nn]);
                    xChkIndex    = xRecWinIndex(xChkIndex);

                    % range of timestamps that should contain this chunk of x
                    tsWin(1) = find(NCS.TimeStamps                                 <=x(xChkIndex(1)),1,'last');
                    tsWin(2) = find(NCS.TimeStamps                                 <=x(xChkIndex(2)),1,'last');
                    
%                     tsWin(2) = find(NCS.TimeStamps+(NCS.ValidSampleNum-1).*sampPrd >=x(xChkIndex(2)),1,'first');
%                     lastSampleTime = NCS.TimeStamps(tsWin(2))+(sampleNum-1)*sampPrd;
%                     if x(xChkIndex(2))>
%                     if x(xChkIndex(1))<NCS.TimeStamps(tsWin(1)) || x(xChkIndex(2))>NCS.TimeStamps(tsWin(2))+(sampleNum-1)*sampPrd
%                         error('Timestamps are not within NCS range!!')
%                     end

                    index(xChkIndex(1) : xChkIndex(2)) = findIndex(NCS.TimeStamps(tsWin(1):tsWin(2)) , x(xChkIndex(1):xChkIndex(2)),sampleNum,sampPrd);
                    index(xChkIndex(1) : xChkIndex(2)) = index(xChkIndex(1) : xChkIndex(2)) + (tsWin(1)-1)*sampleNum;
                end
    end
end




function index = findIndex(ts,x,sampleNum,sampPrd)
tsNum = length(ts);
[tsGridHor, xGridVert] = meshgrid(ts,x);

latestTSIndex = sum(tsGridHor<=xGridVert,2);
sampleNr      = round((x-ts(latestTSIndex)')./sampPrd) + 1;

% here rounding yields an index close to the next timestamp
% latestTSIndex(sampleNr==sampleNum+1) = latestTSIndex(sampleNr==sampleNum+1)+1;
% sampleNr(sampleNr==sampleNum+1)      = 1;
% !!! But, since gaps between NCS.TimeStamps are usually bigger than between
% samples, we assign the last sample
sampleNr(sampleNr==sampleNum+1)      = sampleNum;

if any(sampleNr>sampleNum) || any(sampleNr<1)
    error('unexpected sampleNr!');
elseif any(latestTSIndex>tsNum) 
    error('unexpected timeStampNr!');
end
index = sub2ind([sampleNum, tsNum],sampleNr,latestTSIndex);




function [index, subscript] = findIndexLOOP(rowTS,x,sampleNum,sampPrd,xChunkSize)
n = length(x);
tsNum = length(rowTS);
subscript = zeros(n,2);
xChunkCount = 1;
for ix = 1:n
    if ix>xChunkSize*xChunkCount
        fprintf(1,'%u\n',xChunkCount*xChunkSize);
        xChunkCount = xChunkCount+1;
    end
    iTS         = find(rowTS<=x(ix),1,'last');
    sampleTimes = rowTS(iTS)+[0:sampleNum]*sampPrd;
    % use [0:sampleNum] instead of [0:sampleNum-1] to compensate for
    % timestamps that are actually closer to the next column
    [dts, iS]   = min(abs(sampleTimes-x(ix)));
    if iS>sampleNum
        subscript(ix,1) = 1;
        subscript(ix,2) = iTS+1;
    else
        subscript(ix,1) = iS;
        subscript(ix,2) = iTS;
    end
end
if any(subscript(:,1)>sampleNum) || any(subscript(:,1)<1)
    error('unexpected sampleNr!');
end
index = sub2ind([sampleNum, tsNum],subscript(:,1),subscript(:,2));

