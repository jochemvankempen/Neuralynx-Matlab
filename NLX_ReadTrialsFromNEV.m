function [TrialHead,TrialEv] = nlx_ReadTrialsFromNEV(NEV,S,TW)

% reads trial events according to events defined in settings structure

Range = find(NEV.TimeStamps>=TW(1) & NEV.TimeStamps<=TW(2));
NEV = NLX_ExtractNEV(NEV,Range);
numEv = length(NEV.TimeStamps);

TRIALSTART = S.EventCode(strmatch('NLX_TRIAL_START',S.EventName,'exact'));
TRIALEND = S.EventCode(strmatch('NLX_TRIAL_END',S.EventName,'exact'));


EvCount = 0;
nTr = 0;
ReachedFileEnd = 0;
hwait=waitbar(0,'');
while EvCount<numEv
    EvCount = EvCount+1;
    
    if NEV.TTL(EvCount)==S.EventCode(strmatch('NLX_TRIAL_START',S.EventName,'exact'));
        nTr = nTr+1;
        
        TrialEv{nTr} = [NEV.TTL(EvCount) NEV.TimeStamps(EvCount)];
        
        while NEV.TTL(EvCount)~=S.EventCode(strmatch('NLX_TRIALPARAM_START',S.EventName,'exact'));
            EvCount = EvCount+1;
        end
        
        currTrialHead = [];
        while NEV.TTL(EvCount)~=S.EventCode(strmatch('NLX_TRIALPARAM_END',S.EventName,'exact'));
            EvCount = EvCount+1;
            if NEV.TTL(EvCount)~=0 & NEV.TTL(EvCount)~=S.EventCode(strmatch('NLX_TRIALPARAM_END',S.EventName,'exact'));
                currTrialHead = cat(1,currTrialHead,[NEV.TTL(EvCount) NEV.TimeStamps(EvCount)]);
            end
        end
        if size(currTrialHead,1)==3
            TrialHead(:,nTr) = currTrialHead(:,1);
        end
        
        while NEV.TTL(EvCount)~=S.EventCode(strmatch('NLX_TRIAL_END',S.EventName,'exact'));
            EvCount = EvCount+1;
            if NEV.TTL(EvCount)~=0;
                TrialEv{nTr} = cat(1,TrialEv{nTr},[NEV.TTL(EvCount) NEV.TimeStamps(EvCount)]);
            end
        end
    end
    waitbar(EvCount/numEv,hwait);
end
close(hwait);

%                 NEV.TimeStamps(TrialStartIND(i)
%     
%     
%     
%     
% end
%         
% 
%     if i<nTrialStarts & ~all(ismember(S.MandatoryEvents,NEV.TTL(TrialStartIND(i):TrialStartIND(i+1)-1)));continue;end
%     if i==nTrialStarts & ~all(ismember(S.MandatoryEvents,NEV.TTL(TrialStartIND(i):end)));continue;end
% 
% 
% 
% %     
% 
% 
% disp('ok')
% % 
% % MandatoryEvents
% % S.EventName(1) = {'NLX_TRIAL_START'};
% % S.EventCode(1) = 255;