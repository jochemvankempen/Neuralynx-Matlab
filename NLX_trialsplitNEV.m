function [TrialData,EventData,ParamData] = NLX_trialsplitNEV(NEV,TimeWin,TrialStartSeq,TrialStopSeq,ParamStartSeq,ParamStopSeq)

TrialData = {};
EventData = {};
ParamData = {};

N = length(NEV.TimeStamps);
if isempty(TimeWin)
    IX = find(NEV.TTL>0);
else
    IX = find(NEV.TimeStamps>=TimeWin(1)&NEV.TimeStamps<=TimeWin(2)&NEV.TTL>0);
end

nTrStart = length(TrialStartSeq);
nTrStop = length(TrialStopSeq);
nParamSeq = length(ParamStartSeq);
nIX = length(IX);

TrialNr = zeros(nIX,1);
ParamNr = zeros(nIX,1);

isParamFlag = logical(0);
TrCnt = 0;
i = 1;
while i<=nIX
    
    if ~isParamFlag & all(NEV.TTL(IX(i:i+nTrStart-1))==TrialStartSeq)
        TrCnt = TrCnt+1;
		currTrialStartEvent = i;
		currTrialStopEvent = 0;
		currParamStartEvent = cell(nParamSeq);
		currParamStopEvent = cell(nParamSeq);
		ParamRelatedEvents = [];
		
		while i<=nIX
			i = i+1;
			if ~isParamFlag & all(NEV.TTL(IX(i:i+nTrStop-1))==TrialStopSeq)
				TrialEnd=1;
				currTrialStopEvent = i;
				break;
			end
    		for k = 1:nParamSeq
        		cParN = length(ParamStartSeq{k});
        		if i<=nIX-(cParN-1) & all(NEV.TTL(IX(i:i+cParN-1))==ParamStartSeq{k});
            		isParamFlag = 1;
					currParamStartEvent{k} = i+cParN;
					ParamRelatedEvents = [ParamRelatedEvents i:i+cParN-1];
        		end
				cParN = length(ParamStopSeq{k});
				if i<=nIX-(cParN-1) & all(NEV.TTL(IX(i:i+cParN-1))==ParamStopSeq{k});
					isParamFlag = 0;
					currParamStopEvent{k} = i-1;
					ParamRelatedEvents = [ParamRelatedEvents i:i+cParN-1];
				end
				
				if isParamFlag
					ParamRelatedEvents = [ParamRelatedEvents i];
				end
			end
		end
		
		TrialData{1,TrCnt} = [NEV.TimeStamps(IX(currTrialStartEvent:currTrialStopEvent))' NEV.TTL(IX(currTrialStartEvent:currTrialStopEvent))'];
		EventData{1,TrCnt} = TrialData{1,TrCnt}(~ismember([currTrialStartEvent:currTrialStopEvent],ParamRelatedEvents),:);
		for k = 1:nParamSeq
			if ~isempty(currParamStartEvent{k})
				ParamData{k,TrCnt} = [NEV.TimeStamps(IX(currParamStartEvent{k}:currParamStopEvent{k}))' NEV.TTL(IX(currParamStartEvent{k}:currParamStopEvent{k}))'];
			end
		end
	end
	
	i = i+1;
end


