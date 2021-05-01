% Written by S. Hossein Khatoonabadi (skhatoon@sfu.ca)
%
% read DCT values from input file
% 
% Input
%     path: (string) containing directory and file name prefix
%     frameNum: (integer value) frame number
%     IMG_H: (integer value) number of horizontal pixels (height)
%     IMG_W: (integer value) number of vertical pixels (width)
%     
% Output
%     dct: (matrix) DCT values of macroblocks of types Y/Cb/Cr
%
% Format in the file
%     DCT_Y(1){16 sets of 16 dct values for MB #1} 
%     DCT_Cb(1){4 sets of 16 dct values for MB #1} 
%     DCT_Cr(1){4 sets of 16 dct values for MB #1} 
%     DCT_Y(2)
%     .
%     .
%     .
%     DCT_Cr(IMG_H*IMG_W/256)

function dct = ReadDCTs(path, frameNum, IMG_H, IMG_W)

filename = sprintf('%s%d.txt', path, frameNum);
input = load(filename);

if length(input) ~= IMG_H*IMG_W*1.5
    error('error in size')
end

dct = zeros(IMG_H,IMG_W,3,'int16');

index = 1;
for h=1:IMG_H/16
    for w=1:IMG_W/16
        dct((h-1)*16+1:h*16,(w-1)*16+1:w*16,1) = reshape(input(index:index+255),16,16);
        index = index+256;
        dct((h-1)*8+1:h*8,(w-1)*8+1:w*8,2) = reshape(input(index:index+63),8,8);
        index = index+64;
        dct((h-1)*8+1:h*8,(w-1)*8+1:w*8,3) = reshape(input(index:index+63),8,8);
        index = index+64;
    end
end
