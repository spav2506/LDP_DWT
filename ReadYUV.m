% Written by S. Hossein Khatoonabadi (skhatoon@sfu.ca)
%
% read YUV component of an image with format 4:0:0, and up-sampling UV to
% the same resolution of Y (as a matter of convenience)
%
% Input
%     IN_VDO: (string) YUV video sequence file name
%     FRMS_CNT: (integer value) number of frames
%     IMG_H: (integer value) number of horizontal pixels (height)
%     IMG_W: (integer value) number of vertical pixels (width)
%     frame: (integer value) identifying a specific frame
%
% Output
%     yFrame: (matrix) Y dimension of image
%     uFrame: (matrix) U dimension of image
%     vFrame: (matrix) V dimension of image

function [yFrames, uFrames, vFrames] = ReadYUV(IN_VDO, FRMS_CNT, IMG_H, IMG_W, frame)

if nargin == 5 % only read a certain frame
    fpIn = fopen(IN_VDO,'rb');
    fseek(fpIn, (frame-1)*IMG_H*IMG_W*1.5 ,'bof');
    
    temp = fread(fpIn, IMG_H*IMG_W, 'uint8');
    if length(temp) < IMG_H*IMG_W
        length(temp)
        error('error in reading YUV')
    end
    temp = reshape(temp,IMG_W, IMG_H);
    yFrames = temp';
    
    if nargout == 1
        fclose(fpIn);
        return
    end
    
    temp = fread(fpIn, IMG_H*IMG_W/4, 'uint8');
    if length(temp) < IMG_H*IMG_W/4
        length(temp)
        error('error in reading YUV')
    end
    temp = reshape(temp, IMG_W/2, IMG_H/2);
    temp = temp';
    uFrames = kron(temp,ones(2));
    
    temp = fread(fpIn, IMG_H*IMG_W/4, 'uint8');
    if length(temp) < IMG_H*IMG_W/4
        length(temp)
        error('error in reading YUV')
    end
    temp = reshape(temp, IMG_W/2, IMG_H/2);
    temp = temp';
    vFrames = kron(temp,ones(2));
    
    fclose(fpIn);
    return
end

% read whole frames in the sequence:
yFrames = zeros(IMG_H,IMG_W,FRMS_CNT); uFrames = yFrames; vFrames = yFrames;
fpIn = fopen(IN_VDO,'rb');

for frame=1:FRMS_CNT
    temp = fread(fpIn, IMG_H*IMG_W, 'uint8');
    if length(temp) < IMG_H*IMG_W
        length(temp)
        fclose(fid);
        error('error in reading YUV')
    end
    temp = reshape(temp,IMG_W, IMG_H);
    yFrame = temp';
    
    temp = fread(fpIn, IMG_H*IMG_W/4, 'uint8');
    if length(temp) < IMG_H*IMG_W/4
        length(temp)
        error('error in reading YUV')
    end
    temp = reshape(temp, IMG_W/2, IMG_H/2);
    temp = temp';
    uFrame = kron(temp,ones(2));
    
    temp = fread(fpIn, IMG_H*IMG_W/4, 'uint8');
    if length(temp) < IMG_H*IMG_W/4
        length(temp)
        error('error in reading YUV')
    end
    temp = reshape(temp, IMG_W/2, IMG_H/2);
    temp = temp';
    vFrame = kron(temp,ones(2));
    
    yFrames(:,:,frame) = yFrame;
    uFrames(:,:,frame) = uFrame;
    vFrames(:,:,frame) = vFrame;
end
fclose(fpIn);
