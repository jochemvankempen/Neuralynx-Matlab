function index = NLX_findEventsInNCS(NCS, t, indexType)
% get subscript and indices for the samples matrix in the NCS file
% structure
% index = NLX_findEventsInNCS(NCS, t, indexType)
%
% NCS ......... NCS structure
% t ........... vector containing timestamps
% indexType ... 'index' 'subscript'

[rowNum, colNum] = size(NCS.Samples);

subscript = zeros(1,2);
subscript(2) = find(NCS.TimeStamps<=t,1,'last');
rowTimes = NCS.TimeStamps(subscript(2))+[0:512-1]*sampPrd;
[dts, subscript(1)] = min(abs(rowTimes-t));
index = sub2ind([rowNum, colNum],subscript(1),subscript(2));
