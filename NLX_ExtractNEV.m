function NEV = NLX_ExtractNEV(NEV,Index)

% Extracts entries from a NEV structure

if ~isempty(NEV.TimeStamps);NEV.TimeStamps=NEV.TimeStamps(Index,:);end
if ~isempty(NEV.EventID);NEV.EventID=NEV.EventID(Index,:);end
if ~isempty(NEV.TTL);NEV.TTL=NEV.TTL(Index,:);end
if ~isempty(NEV.Extras);NEV.Extras=NEV.Extras(Index,:);end
if ~isempty(NEV.Eventstring);NEV.Eventstring=NEV.Eventstring(Index,:);end