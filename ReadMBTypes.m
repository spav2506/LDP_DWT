% Written by S. Hossein Khatoonabadi (skhatoon@sfu.ca)
%
% read macroblock types from input file
% 
% Input
%     path: (string) containing directory and file name prefix
%     frameNum: (integer value) frame number
%     MBLK_H: (integer value) number of horizontal macroblocks (height)
%     MBLK_W: (integer value) number of vertical macroblocks (width)
%     
% Output
%     mbType: (3-d matrix) block types 

%% NOTE: 
% - in FFMpeg I4MB and I8MB are the same
% - SMB is not written in files
%%

function mbType = ReadMBTypes(path, frameNum, MBLK_H, MBLK_W)

% PREDICTION = '>';
% SKIP = 'S';
% INTRA_16x16 = 'I';
% INTRA_4x4 = 'i';

% extra information:
% BLK_8x8 = '+';
% BLK_16x8' = '-';
% BLK_8x16 = '|';

filename = sprintf('%s%d.txt', path, frameNum);
fid = fopen(filename,'rt');

mbType = char(zeros(MBLK_H,MBLK_W,2));

for i=1:MBLK_H
    tmp = fgetl(fid);
    mbType(i,:,1) = tmp(1:3:end);
    mbType(i,:,2) = tmp(2:3:end);
end

fclose(fid);
