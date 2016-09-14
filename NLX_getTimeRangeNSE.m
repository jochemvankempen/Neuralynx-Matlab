function t = NLX_getTimeRangeNSE(NSE)

% returns the time of first and last sample

t(1) = min(NSE.TimeStamps);
t(2) = max(NSE.TimeStamps);