function [NLX_TimeWin,NLX_ADChannels] = NLX_getFileTimesDialog(EventFilePath)

% opens user dialog to select Neuralynx events as file time window
%% get time window and channels
NEV = NLX_LoadNEV(EventFilePath,'FULL',1,[]);
NEV = NLX_getEventType(NEV,'user',true);
fprintf(1,'>>>>> select time windows <<<<<<<\n');
fprintf(1,'user events:\n');
for i=1:size(NEV.TimeStamps,1)
    fprintf(1,'%12u',NEV.TimeStamps(i));
    fprintf(1,'\t');
    fprintf(1,'%20s',NEV.Eventstring{i});
    if i>1
        fprintf(1,'\t');
        dt = NEV.TimeStamps(i)-NEV.TimeStamps(i-1);
        fprintf(1,'dt: %3.0f min %2.2f sec',floor(dt*1e-6/60),rem(dt*1e-6,60));
    end
    fprintf(1,'\n');
end
fprintf(1,'\ncopy times from above list (return to close) :\n');
TWcnt = 0;
a = NaN;
b = NaN;
while ~isempty(b)
    a = input(sprintf('#%2u low   --> ',TWcnt+1));
    b = input(sprintf('#%2u high  --> ',TWcnt+1));
    c = input(sprintf('#%2u label --> ',TWcnt+1),'s');
    if ~any([isempty(a) isempty(b) isempty(c)])
        TWcnt = TWcnt+1;
        NLX_TimeWin(TWcnt,:) = [a b];
        NLX_TimeLabel{TWcnt,1} = c;
    end
end
fprintf(1,'\nYou chose:\n');
for i=1:size(NLX_TimeWin,1)
    fprintf(1,'%12u %12u',NLX_TimeWin(i,1),NLX_TimeWin(i,2));
    fprintf(1,'\t');
    dt = NLX_TimeWin(i,2)-NLX_TimeWin(i,1);
    fprintf(1,'dt: %3.0f min %2.2f sec\n',floor(dt*1e-6/60),rem(dt*1e-6,60));
end
fprintf(1,'\n');

if nargout>1
    fprintf(1,'\nSelect ADChannels (enter array of channels as [0 1 3 7 ...] or [0:32]):\n');
    NLX_ADChannels = input(' ---> ');
end
