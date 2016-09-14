function [NumSamples,FieldArray,FieldCells] = NLX_CheckNCS(NCS)

% Checks an NCS structure for number of spikes and existing data.
%
% NCS ... structure (see NLX_loadNCS.m)

FieldCells = {};
FieldArray = ~[ isempty(NCS.TimeStamps) isempty(NCS.ChNr) isempty(NCS.SF) isempty(NCS.ValidSampleNum) isempty(NCS.Samples) ];
NumSamples = [ size(NCS.TimeStamps,2) size(NCS.ChNr,2) size(NCS.SF,2) size(NCS.ValidSampleNum,2) size(NCS.Samples,2)];
NumSamples = unique(NumSamples(FieldArray));
if length(NumSamples)>1
	error('All field must have same number of samples!');
end

if nargout==3
	if FieldArray(1);FieldCells = cat(2,FieldCells,{NCS.TimeStamps});end
	if FieldArray(2);FieldCells = cat(2,FieldCells,{NCS.ChNr});end
	if FieldArray(3);FieldCells = cat(2,FieldCells,{NCS.SF});end
	if FieldArray(4);FieldCells = cat(2,FieldCells,{NCS.ValidSampleNum});end
	if FieldArray(5);FieldCells = cat(2,FieldCells,{NCS.Samples});end
end

	
