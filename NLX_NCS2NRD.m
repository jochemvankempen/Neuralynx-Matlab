function NRD = NLX_NCS2NRD(NCS)

% NCS structure
%               Path: [1x83 char]
%             Header: {5x1 cell}
%         TimeStamps: [1x7040 double]
%               ChNr: [1x7040 double]
%                 SF: [1x7040 double]
%     ValidSampleNum: [1x7040 double]
%            Samples: [512x7040 double]

[NumNCSSamples,n] = size(NCS.Samples);

NRD.Path = NCS.Path;

NRD.Header = NCS.Header;

NRD.TimeStamps = repmat(NCS.TimeStamps,[NumNCSSamples,1]) ...
    + repmat([0:NumNCSSamples-1]',[1 n]) .* 1000000./repmat(NCS.SF,[NumNCSSamples 1]);
NRD.TimeStamps = NRD.TimeStamps(:);

NRD.ChNr = unique(NCS.ChNr);

NRD.Samples = NCS.Samples(:);



