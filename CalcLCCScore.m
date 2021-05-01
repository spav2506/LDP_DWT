% Written by S. Hossein Khatoonabadi (skhatoon@sfu.ca)
%
% calculate the score of linear Pearson correlation coefficient
%
% Input
%     salMap: (2-D matrix) predicted saliency map
%     fixMap: (2-D matrix) discrete fixation map
%     gauss: (2-D matrix) Gaussian mask
%
% Output
%     lcc: (integer value) Pearson score

function lcc = CalcLCCScore(salMap, fixMap, gauss)

fixMapConv = conv2(double(fixMap),gauss,'same'); 
lcc = corr(salMap(:),fixMapConv(:));