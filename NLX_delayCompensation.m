function [nlxStruct, didCompensate] = NLX_delayCompensation(nlxStruct)

cNLXHeaderCells = NLX_Head2Cell(nlxStruct.Header);
delayParNr      = strcmp(cNLXHeaderCells(:,1),'DspFilterDelay_µs');
delayCompParNr  = strcmp(cNLXHeaderCells(:,1),'DspDelayCompensation');

didCompensate = false;
if any(delayParNr) && any(delayCompParNr)
    wasEnabledWhenRecord   = isempty(strfind(cNLXHeaderCells{delayCompParNr,2},'Disabled'));
    if ~wasEnabledWhenRecord
        nlxStruct.TimeStamps    = nlxStruct.TimeStamps - cNLXHeaderCells{delayParNr,2};
        didCompensate = true;
    end
end

