function [Events,ConditionData,ParamData,AllEv] = NLX_ReadTrialsNEV(NEV,TimeWin,TrialWinEv,CndEvSeq,ParamEvSeq,SplitTrialInfo)

% reads trials from a NEV file
%
% NEV
% TimeWin
% TrialWinEv
% CndEvSeq
% ParamEvSeq
% SplitTrialInfo

Events = {};
ConditionData = {};
ParamData = {};
AllEv = {};

% select valid events, in time window and non-zero
N = length(NEV.TimeStamps);
if isempty(TimeWin)
    IX = find(NEV.TTL>0);
else
    IX = find(NEV.TimeStamps>=TimeWin(1)&NEV.TimeStamps<=TimeWin(2)&NEV.TTL>0);
end

nTrStart = length(TrialWinEv{1});
nTrStop = length(TrialWinEv{2});
nCndStart = length(CndEvSeq{1});
nCndStop = length(CndEvSeq{2});
nParamStart = length(ParamEvSeq{1});
nParamStop = length(ParamEvSeq{2});
nIX = length(IX);

TrialNr = zeros(nIX,1);
ParamNr = zeros(nIX,1);

%----------------------------
% loop through all the events
%----------------------------
isCndFlag = logical(0);
isParamFlag = logical(0);
TrCnt = 0;
i = 1;
while i<=nIX
    
    % detect the trial start sequence
    if ~isParamFlag & ~isCndFlag & all(NEV.TTL(IX(i:i+nTrStart-1))==TrialWinEv{1})
        TrCnt = TrCnt+1;
        Events{TrCnt} = [];
        ConditionData{TrCnt} = [];
        ParamData{TrCnt} = [];
        
        TrialStart_i = i;
        TrialStop_i = NaN;
        CndStart_i = NaN;
        CndStop_i = NaN;
        ParStart_i = NaN;
        ParStop_i = NaN;
        
        % go through all events from here until ... break
		while i<=nIX
		    i = i+1;
        
            % detect the TRIAL STOP sequence
			if ~isParamFlag & ~isCndFlag & all(NEV.TTL(IX(i:i+nTrStop-1))==TrialWinEv{2})
                TrialStop_i = i;
				break;
			end
    		
            % check for CONDITION START sequence
            if ~isCndFlag & ~isParamFlag & i<=nIX-(nCndStart-1) & all(NEV.TTL(IX(i:i+nCndStart-1))==CndEvSeq{1});
                isCndFlag = 1;
                CndStart_i = i+nCndStart;
            end
            
            % check for CONDITION STOP sequence
            if isCndFlag & ~isParamFlag & i<=nIX-(nCndStop-1) & all(NEV.TTL(IX(i:i+nCndStop-1))==CndEvSeq{2});
                isCndFlag = 0;
                CndStop_i = i-1;
            end
           
            % check for PARAMETER START sequence
            if ~isCndFlag & ~isParamFlag & i<=nIX-(nParamStart-1) & all(NEV.TTL(IX(i:i+nParamStart-1))==ParamEvSeq{1});
                isParamFlag = 1;
                ParStart_i = i+nParamStart;
            end
            
            % check for PARAMETER STOP sequence
            if ~isCndFlag & isParamFlag & i<=nIX-(nParamStop-1) & all(NEV.TTL(IX(i:i+nParamStop-1))==ParamEvSeq{2});
                isParamFlag = 0;
                ParStop_i = i-1;
            end
            
        end
        
        % compile the current event
        AllEv{TrCnt} = [NEV.TimeStamps(IX(TrialStart_i:TrialStop_i))' NEV.TTL(IX(TrialStart_i:TrialStop_i))'];
        Ev_i = TrialStart_i:TrialStop_i;
        if ~any(isnan([CndStart_i CndStop_i]))
            ConditionData{TrCnt} = [NEV.TimeStamps(IX(CndStart_i:CndStop_i))' NEV.TTL(IX(CndStart_i:CndStop_i))'];
            Ev_i = setdiff(Ev_i,[CndStart_i:CndStop_i]);
        else
            ConditionData{TrCnt} = [];
        end
        if ~any(isnan([ParStart_i ParStop_i]))
            ParamData{TrCnt} = [NEV.TimeStamps(IX(ParStart_i:ParStop_i))' NEV.TTL(IX(ParStart_i:ParStop_i))'];
            Ev_i = setdiff(Ev_i,[ParStart_i:ParStop_i]);
        else
            ParamData{TrCnt} = [];
        end
        Events{TrCnt} = [NEV.TimeStamps(IX(Ev_i))' NEV.TTL(IX(Ev_i))'];
          
	end
	
	i = i+1;
end

% %----------------------------
% % Get correct event windows
% %----------------------------
% SplitTrialInfo = [1 4 32 -500*1000 500*1000];
% SplitN = SplitTrialInfo(1);
% TrialWin = [];
% if SplitN==1 & size(SplitTrialInfo)==1
% elseif SplitN==1 & size(SplitTrialInfo)==3
%     TrialStartCode = SplitTrialInfo(2);
%     TrialStopCode = SplitTrialInfo(3);
%     
%     for i = 1:TrCnt
%         TrSrti = Events{TrCnt}(:,2)==TrialStartCode;
%         TrSrtn = sum(TrSrti);
%         TrSrti = Events{TrCnt}(:,2)==TrialStartCode;
%         TrSrtn = sum(TrSrti);
