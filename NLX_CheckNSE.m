function [NumSpikes,FieldArray,FieldCells] = NLX_CheckNSE(NSE)

% Checks an NSE structure for number of spikes and existing data.
%
% NSE ... structure (see NLX_loadNSE.m)

FieldCells = {};
FieldArray = ~[ isempty(NSE.TimeStamps) isempty(NSE.ScNr) isempty(NSE.ClusterNr) isempty(NSE.SpikeFeatures) isempty(NSE.SpikeWaveForm) ];
NumSpikes = [ size(NSE.TimeStamps,1) size(NSE.ScNr,1) size(NSE.ClusterNr,1) size(NSE.SpikeFeatures,2) size(NSE.SpikeWaveForm,3)];
NumSpikes = unique(NumSpikes(FieldArray));
if length(NumSpikes)>1
	error('All field must have same number of spikes!');
end

if nargout==3
	if FieldArray(1);FieldCells = cat(2,FieldCells,{NSE.TimeStamps'});end
	if FieldArray(2);FieldCells = cat(2,FieldCells,{NSE.ScNr'});end
	if FieldArray(3);FieldCells = cat(2,FieldCells,{NSE.ClusterNr'});end
	if FieldArray(4);FieldCells = cat(2,FieldCells,{NSE.SpikeFeatures});end
	if FieldArray(5);FieldCells = cat(2,FieldCells,{NSE.SpikeWaveForm});end
end


	
