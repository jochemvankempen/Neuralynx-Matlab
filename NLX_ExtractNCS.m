function [NCS,Samples,Times] = NLX_ExtractNCS(NCS,NLXTime,doVector)

% Extracts data from an NCS structure.
%
% [NCS,Samples,Times] = NLX_ExtractNCS(NCS,NLXTime)
%
% INPUT
% NCS ........ structure, see NLX_loadNCS
% NLXTime .... time window
% doVector ... vectorise data
% OUTPUT
% NCS ......... NCS structure containing data in time window
% Samples ..... vector of samples
% Times ....... vector timestamps in microseconds

if nargin<2 || isempty(NLXTime)
	NLXTime = NLX_timerangeNCS(NCS);
end
if nargin<3
    doVector = [];
end

Samples = [];Times = [];

% find timestamps; mind that NCS.TimeStamps
% format is a vector and NCS.Samples is matrix
index = find(NCS.TimeStamps>=NLXTime(1) & NCS.TimeStamps<=NLXTime(2));
if isempty(index) & (all(NLXTime<NCS.TimeStamps(1))||all(NLXTime>NCS.TimeStamps(end)));
    % NLXTime is not in timestamp range
    index = zeros(length(NCS.TimeStamps));
    warning('Can''t find samples in the given time window !');
elseif isempty(index) & ~(all(NLXTime<NCS.TimeStamps(1))||all(NLXTime>NCS.TimeStamps(end)));
    % NLXTime is between two timestamp "columns"
    index = find(NCS.TimeStamps<NLXTime(1),1,'last');
    NCS = cutcolumns(NCS,index);
elseif ~isempty(index)
    % include the next lowest highest sample "column"
    if index(1)>1;index = [index(1)-1 index];end
    if length(NCS.TimeStamps)>index(end);index = [index index(end)+1];end
    NCS = cutcolumns(NCS,index);
end


% extract data to arrays
if nargout==1
    if (isempty(doVector) || ~doVector)
        return;
    else
        [NCS.TimeStamps,NCS.Samples] = vectorise(NCS,NLXTime);
    end
elseif nargout>1
    [Times,Samples] = vectorise(NCS,NLXTime);
end

function NCS = cutcolumns(NCS,index)
% reduce to time window before calculations;
NCS.TimeStamps = NCS.TimeStamps(index);
NCS.ChNr = NCS.ChNr(index);
NCS.SF = NCS.SF(index);
NCS.ValidSampleNum = NCS.ValidSampleNum(index);
NCS.Samples = NCS.Samples(:,index);

function [Times,Samples] = vectorise(NCS,NLXTime)
[SampleRows,SampleCols] = size(NCS.Samples);
NCS.TimeStamps = repmat(NCS.TimeStamps,[SampleRows 1]) + repmat([0:SampleRows-1]',[1 SampleCols]) .* repmat(round(1000000./NCS.SF),[SampleRows 1]);
index = find(NCS.TimeStamps>=NLXTime(1) & NCS.TimeStamps<=NLXTime(2));
Samples = NCS.Samples(index);
Times = NCS.TimeStamps(index);

