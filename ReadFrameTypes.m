% Written by S. Hossein Khatoonabadi (skhatoon@sfu.ca)
%
% read frame types from input file
% 
% Input
%     path: (string) containing directory and file name prefix
     
% Output
%     mbType: (matrix) frame types

function fType = ReadFrameTypes(path)

% I_FRAME = 'I';
% B_FRAME = 'B';
% P_FRAME = 'P';

filename = sprintf('%stypes.txt', path);
fid = fopen(filename,'rt');
fType = fscanf(fid,'%s');
fclose(fid);
