function [NSEcells,Index] = NLX_timesplitNSE(NSE,t)

% time split off a NSE structure 
%
% [NSEcells] = NLX_timesplitNSE(NSE,t)
% t ... two-column vector:
%       each row defines a time window
%       one-column vector:
%       each element defines a timesplit

[nRows,nCols] = size(t);
n = length(NSE.TimeStamps);

if nCols==1
    NSEcells = cell(1,nRows+1);
    Index = false(n,nRows+1);
    for i = 1:nRows+1
        if i == 1
            Index(:,i) = NSE.TimeStamps(:,1) < t(i);
        elseif i == nRows+1
            Index(:,i) = NSE.TimeStamps(:,1) >= t(i-1);
        else
            Index(:,i) = NSE.TimeStamps(:,1) >= t(i-1) & NSE.TimeStamps(:,1) < t(i);
        end
        NSEcells{i} = NLX_ExtractNSE(NSE,Index(:,i));
    end
elseif nCols==2
    NSEcells = cell(1,nRows);
    Index = false(n,nRows);
    for i = 1:nRows
        Index(:,i) = NSE.TimeStamps(:,1) >= t(i,1) & NSE.TimeStamps(:,1) <= t(i,2);
        NSEcells{i} = NLX_ExtractNSE(NSE,Index(:,i));
    end
end

