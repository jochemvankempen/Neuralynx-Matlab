function c = NLX_ClusterColor(ClusterNr)

% Coloring for cell clusters

c = [ ...
        .6 .6 .6; ...                   0 light grey
        1 0 0; ...                      1 red
        0 1 0; ...                      2 green
        0    0.7490    1.0000; ...      3 deep sky blue
        1 0 1; ...                      4 magenta
        1.0000    0.6471         0; ... 5 orange
        0    1.0000    0.4980; ...      6 spring green
        0 0 1; ...                      7 blue
        1.0000    0.2706         0; ... 8 Orange Red
        0.4863    0.9882         0 ...  9 Lawn Green
        ]; ... 
        
 if nargin==1
     c = c(ClusterNr+1,:);
 end
