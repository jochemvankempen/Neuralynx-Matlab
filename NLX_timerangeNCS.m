function t = NLX_timerangeNCS(NCS)

% returns the time of first and last sample

t(1) = NCS.TimeStamps(1);
t(2) = NCS.TimeStamps(end)+ NCS.ValidSampleNum(end)*1000000/NCS.SF(end);