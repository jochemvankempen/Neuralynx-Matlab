function [NumEvents,FieldArray,FieldCells] = NLX_CheckNEV(NEV)

% Checks an NEV structure for number of Events and existing data.
%
% NEV ... structure (see NLX_loadNEV.m)

FieldCells = {};
FieldArray = ~[ isempty(NEV.TimeStamps) isempty(NEV.EventID) isempty(NEV.TTL) isempty(NEV.Extras) isempty(NEV.Eventstring) ];
NumEvents = [ size(NEV.TimeStamps,1) size(NEV.EventID,1) size(NEV.TTL,1) size(NEV.Extras,1) size(NEV.Eventstring,1)];
NumEvents = unique(NumEvents(FieldArray));
if length(NumEvents)>1
	error('All field must have same number of spikes!');
end

if nargout==3
	if FieldArray(1);FieldCells = cat(2,FieldCells,{NEV.TimeStamps(:)'});end
	if FieldArray(2);FieldCells = cat(2,FieldCells,{NEV.EventID(:)'});end
	if FieldArray(3);FieldCells = cat(2,FieldCells,{NEV.TTL(:)'});end
	if FieldArray(4);FieldCells = cat(2,FieldCells,{NEV.Extras'});end
	if FieldArray(5);FieldCells = cat(2,FieldCells,{NEV.Eventstring(:)});end
end
	
