function [CH_1,CV_1,CD_1]=DiscretWavelet3(dct)
frm_cnt=size(dct,4);

% m=size(dct,1);
% n=size(dct,2);
CH_1=[];CV_1=[];CD_1=[];
% sd1=liftwave('haar');
dct=double(abs(dct));
for i= 1:frm_cnt
    dct1 = ((dct(:,:,1,i)));

             [A,CH,CV,CD]=dwt2(dct1,'haar');

             
             
             
             CH_1(:,:,i)=CH;
             CV_1(:,:,i)=CV;
             CD_1(:,:,i)=CD;


    
end
end