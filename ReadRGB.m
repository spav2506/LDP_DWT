% Written by S. Hossein Khatoonabadi (skhatoon@sfu.ca)
%
% read RGB component of an image with YUV format 4:1:1
%
% Input
%     IN_VDO: (string) YUV video sequence file name
%     FRMS_CNT: (integer value) number of frames
%     IMG_H: (integer value) number of horizontal pixels (height)
%     IMG_W: (integer value) number of vertical pixels (width)
%     frame: (integer value) identifying a specific frame
%
% Output
%     RGB: (4-d matrix) an image in RGB format

function RGBs = ReadRGB(IN_VDO, FRMS_CNT, IMG_H, IMG_W, frame)

if nargin == 5 % only read a certain frame
    [yFrame, uFrame, vFrame] = ReadYUV(IN_VDO, FRMS_CNT, IMG_H, IMG_W, frame);
    ycbcr = zeros(IMG_H, IMG_W, 3, 'uint8');
    ycbcr(:,:,1) = yFrame;
    ycbcr(:,:,2) = uFrame;
    ycbcr(:,:,3) = vFrame;
    RGBs = ycbcr2rgb(ycbcr);
    return
end

% read whole frames in the sequence:
RGBs = uint8(zeros(IMG_H,IMG_W,3,FRMS_CNT));
[yFrames, uFrames, vFrames] = ReadYUV(IN_VDO, FRMS_CNT, IMG_H, IMG_W);
for frame = 1:FRMS_CNT
    ycbcr = zeros(IMG_H, IMG_W, 3, 'uint8');
    ycbcr(:,:,1) = yFrames(:,:,frame);
    ycbcr(:,:,2) = uFrames(:,:,frame);
    ycbcr(:,:,3) = vFrames(:,:,frame);
    RGB = ycbcr2rgb(ycbcr);
    RGBs(:,:,:,frame) = RGB;
end