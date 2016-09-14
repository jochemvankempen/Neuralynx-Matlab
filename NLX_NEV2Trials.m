function [Events,ConditionData,ParamData,UserEvents] = NLX_NEV2Trials(NEVpath,NLXTime,TrialWinEv,CndEvSeq,ParamEvSeq,minCndNum,minParamNum)

% Extract trials from an neuralynx event file.
% [Events,ConditionData,ParamData,UserEv] = NLX_NEV2Trials(NEVpath,NLXTime,TrialWinEv,CndEvSeq,ParamEvSeq)
% INPUT:
% NEVpath .............. path to events *.nev file
% NLXTime .............. time window to look for events
% TrialWinEv ........... {[trial start sequence] [trial stop sequence]}
% CndEvSeq ............. {[trial start sequence] [trial stop sequence]}
% ParamEvSeq ........... {[trial start sequence] [trial stop sequence]}
% minCndNum ............ minimum condition parameter to detected 
% minParamNum .......... minimum parameter to detected
% OUTPUT
% Events .......... cell(N)
% ConditionData ... 
% ParamData .......

Events = {};
ConditionData = {};
ParamData = {};
AllEv = {};

%% read events *.nev file
NEV = NLX_LoadNEV(NEVpath,'TTL+',4,NLXTime);
NEV.TimeStamps = NEV.TimeStamps(:);
NEV.TTL = NEV.TTL(:);
NEV.Eventstring = NEV.Eventstring(:);

%% check for user submitted events
% - events at port 'RecID: 4098 Port: 0 TTL Value:'
UserEvents = NLX_getEventType(NEV,'user');
UserEvents = [UserEvents.Eventstring num2cell(UserEvents.TimeStamps)];
NEV = NLX_getEventType(NEV,'digital');

%% select non-zero events
iNonZeroTTL = find(NEV.TTL>0);
nNonZeroTTL = length(iNonZeroTTL);

%% get sequence length of marker events
nTrStart = length(TrialWinEv{1});
nTrStop = length(TrialWinEv{2});
nCndStart = length(CndEvSeq{1});
nCndStop = length(CndEvSeq{2});
nParamStart = length(ParamEvSeq{1});
nParamStop = length(ParamEvSeq{2});

%% loop through all the events
TrialNr = zeros(nNonZeroTTL,1);
ParamNr = zeros(nNonZeroTTL,1);
isCndFlag = false;
isParamFlag = false;
TrCnt = 0;
i = 1;
while i<=nNonZeroTTL
    
    % detect the trial start sequence
    if ~isParamFlag && ~isCndFlag ... % make sure you don't detect a trialstart code within a parameter sequence
            && all(NEV.TTL(iNonZeroTTL(i:i+nTrStart-1))==TrialWinEv{1}(:))% detect correct trialstart sequence
        
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
        while i<=nNonZeroTTL
            i = i+1;
            
            % detect the TRIAL STOP sequence
            if i>nNonZeroTTL
                TrialStop_i = NaN;
                break;
            else
                if ~isParamFlag && ~isCndFlag && all(NEV.TTL(iNonZeroTTL(i:i+nTrStop-1))==TrialWinEv{2})
                    TrialStop_i = i;
                    break;
                end
            end
            
            % check for CONDITION START sequence
            if ~isCndFlag && ~isParamFlag && i<=nNonZeroTTL-(nCndStart-1) && all(NEV.TTL(iNonZeroTTL(i:i+nCndStart-1))==CndEvSeq{1});
                isCndFlag = 1;
                CndStart_i = i+nCndStart;
            end
            
            % check for CONDITION STOP sequence
            if isCndFlag ...
                    && ~isParamFlag ...
                    && i<=nNonZeroTTL-(nCndStop-1) ...
                    && all(NEV.TTL(iNonZeroTTL(i:i+nCndStop-1))==CndEvSeq{2}) ...
                    && (i-1)-(CndStart_i)+1 >= minCndNum
                isCndFlag = 0;
                CndStop_i = i-1;
            end
            
            % check for PARAMETER START sequence
            if ~isCndFlag && ~isParamFlag && nParamStart>0 && i<=nNonZeroTTL-(nParamStart-1) && all(NEV.TTL(iNonZeroTTL(i:i+nParamStart-1))==ParamEvSeq{1});
                isParamFlag = 1;
                ParStart_i = i+nParamStart;
            end
            
            % check for PARAMETER STOP sequence
            if ~isCndFlag && isParamFlag && nParamStop>0 && i<=nNonZeroTTL-(nParamStop-1) && all(NEV.TTL(iNonZeroTTL(i:i+nParamStop-1))==ParamEvSeq{2});
                isParamFlag = 0;
                ParStop_i = i-1;
            end
            
        end
        
        if isnan(TrialStop_i)
            Events(TrCnt) = [];
            ConditionData(TrCnt) = [];
            ParamData(TrCnt) = [];
        else
            % compile the current event
            AllEv{TrCnt} = [NEV.TimeStamps(iNonZeroTTL(TrialStart_i:TrialStop_i)) NEV.TTL(iNonZeroTTL(TrialStart_i:TrialStop_i))];
            Ev_i = TrialStart_i:TrialStop_i;
            if ~any(isnan([CndStart_i CndStop_i]))
                ConditionData{TrCnt} = [NEV.TimeStamps(iNonZeroTTL(CndStart_i:CndStop_i)) NEV.TTL(iNonZeroTTL(CndStart_i:CndStop_i))];
                Ev_i = setdiff(Ev_i,[CndStart_i:CndStop_i]);
            else
                ConditionData{TrCnt} = [];
            end
            if ~any(isnan([ParStart_i ParStop_i]))
                ParamData{TrCnt} = [NEV.TimeStamps(iNonZeroTTL(ParStart_i:ParStop_i)) NEV.TTL(iNonZeroTTL(ParStart_i:ParStop_i))];
                Ev_i = setdiff(Ev_i,[ParStart_i:ParStop_i]);
            else
                ParamData{TrCnt} = [];
            end
            Events{TrCnt} = [NEV.TimeStamps(iNonZeroTTL(Ev_i)) NEV.TTL(iNonZeroTTL(Ev_i))];
        end
        
    end
    
    i = i+1;
end