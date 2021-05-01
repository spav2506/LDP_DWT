function [Saliency]= method_LDP(frameType,mv_x,mv_y,dct)
mv_x = mv_x(:,:,frameType=='P');
mv_y = mv_y(:,:,frameType=='P');

[BLK_H,BLK_W,FRMS_CNT] = size(mv_x);
 hsize=[3 3];L=9;
 Ga_flt = fspecial('gaussian',[BLK_H,BLK_W],6);
%  h2 = fspecial('gaussian',hsize,3.0);
BLK_SZ=4;
for frame = 1:FRMS_CNT
%% Data acquisition from data functions
    a=mv_x(:,:,frame);
    b=mv_y(:,:,frame);
%% Finding orientation between 0 to 2*pi
    A=Angley_x(b,a);
%     A=imfilter(A,ones(3));
%%  padaaying for DCP method    
%     S_p=padarray(A,[2,2],'symmetric');
%% Implementing DCP method
    [h]=LDP_MET(A);
%% Normalizing the minimum of two (dual cross) descriptors
     I=Normalize3d(h);
%      I1=(I>0.95);
%      I=double(I.*I1);
%      SER=fspecial('gaussian',[5 5],12);
%% Double filtering the binary map to smoothening
%  I3=imgaussfilt(I,13);
% I3=imgaussfilt(I3,'FilterSize',13);
     I3=conv2(I,Ga_flt,'same');
%      I3=conv2(I3,ones(7),'same');

     WER(:,:,frame)=I3;
end
%% Intializing the  size of DCP based Motion orientation
sfc_flt1 = zeros(size(WER));
%% Temporal filtering
for frame=1:L
    sfc_flt1(:,:,frame) = imfilter(WER(:,:,frame),ones(3));
end
sfc_avg1 = sfc_flt1;
for frame=L+1:FRMS_CNT
    sfc_flt1(:,:,frame) = imfilter(WER(:,:,frame),ones(3));
    sfc_avg1(:,:,frame) = mean(sfc_flt1(:,:,frame-L:frame),3);
end
sfc_avg1 = Normalize3d(sfc_avg1);
L=9;
%% REsidual Norms
% MBLK_SZ = BLK_SZ*4;
% dct = abs(dct(:,:,:,frameType=='P'));
% %%
% % sfc
% dct_high = logical(dct);
% sfc = Subsum(squeeze(dct_high(:,:,1,:)),MBLK_SZ,MBLK_SZ);
% sfc_flt = zeros(size(sfc));
% for frame=1:L
%     sfc_flt(:,:,frame) = imfilter(sfc(:,:,frame),ones(3));
% end
% sfc_avg = sfc_flt;
% for frame=L+1:size(sfc,3)
%     sfc_flt(:,:,frame) = imfilter(sfc(:,:,frame),ones(3));
%     sfc_avg(:,:,frame) = mean(sfc_flt(:,:,frame-L:frame),3);
% end
% sfc_avg = Normalize3d(sfc_avg);
% S_SRN = imresize(sfc_avg,4,'bilinear');
%% LWT
%% Intialization
BLK_SZ=4;L=9;W=6;
MBLK_SZ = BLK_SZ*4;


%% reading DCT-R values

dct = (dct(:,:,:,frameType=='P'));


%% Applying Lifting wavelet on DCT


[CH,CV,CD]=DiscretWavelet3(dct);



%% Sorting all frames of lifting coefficients and store in temperory file (tmp)

tmp1 = sort(reshape((CH),[],1),'descend');
tmp2 = sort(reshape((CV),[],1),'descend');
tmp3 = sort(reshape((CD),[],1),'descend');

 
 %% 25 th percentile threshold over all frames of lifting wavelet coefficients

TH1 = tmp1(floor(numel(tmp1)*.25));
TH2 = tmp2(floor(numel(tmp2)*.25));
TH3 = tmp3(floor(numel(tmp3)*.25));


%% Setting these three thresholds and find DCT binary

dct_binary_map1 = CH > TH1;


dct_binary_map2 =  CV > TH2;


dct_binary_map3 =  CD > TH3;

%%


%% The final dct map is formed via its all dct binary map



dct_map=(dct_binary_map1 | dct_binary_map2) | dct_binary_map3;

Final_dct_map=imresize(dct_map,2,'bilinear');





sfc_map = Subsum(squeeze (Final_dct_map),MBLK_SZ,MBLK_SZ);

sfc_map= Normalize3d(sfc_map);


%%

%%
% 
sfc_flt = zeros(size(sfc_map));


%% spatial and temporal filtering 
for frame=1:L
    sfc_flt(:,:,frame) = imfilter(sfc_map(:,:,frame),ones(3));
end
sfc_avg = sfc_flt;
for frame=L+1:size(sfc_map,3)
    sfc_flt(:,:,frame) = imfilter(sfc_map(:,:,frame),ones(3));
    sfc_avg(:,:,frame) = mean(sfc_flt(:,:,frame-L:frame),3);
end
sfc_avg = Normalize3d(sfc_avg);







%% Interpolation to block level

S_DWT = imresize(sfc_avg,4,'bilinear');
S_DWT=Normalize3d(S_DWT);

a1=sfc_avg1;

b1=S_DWT;

% 
AB=a1.*b1;

c1=1-a1;

d1=1-b1;

CD=c1.*d1;

Fuse= (AB)./(1-CD);
% Fuse=a1+b1+AB;
S=Fuse;W=3;
zeroSaliency = find(sum(sum(S,1),2)==0);
if ~isempty(zeroSaliency)
    for i=1:numel(zeroSaliency)
        if zeroSaliency(i) == 1
            gaussMap = fspecial('gaussian',[BLK_H BLK_W],W); 
            % equal to pixel-based Gaussian blob of one visual digree
            S(:,:,1) = gaussMap / max(gaussMap(:));            
        else
            S(:,:,zeroSaliency(i)) = S(:,:,zeroSaliency(i)-1);
        end
    end
end
Saliency = zeros(BLK_H,BLK_W,length(frameType));
Saliency(:,:,frameType=='P') = S;
Saliency = imresize(Saliency,BLK_SZ,'nearest');
Saliency = uint8(Saliency.*255);