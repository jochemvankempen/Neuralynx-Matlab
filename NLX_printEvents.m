function NLX_printEvents(NEV)
n= length(NEV.TimeStamps);
for i=1:n
    fprintf('%5.0f %12.0f %1.0f %4.0f %s\n',i,NEV.TimeStamps(i),NEV.EventID(i),NEV.TTL(i),NEV.Eventstring{i});
end
    
