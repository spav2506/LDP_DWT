function [h]=LDP_MET(A)
[w1 w2]=size(A);
I1=padarray(A,[2,2],'symmetric');
Wei=[1 2 4; 128 0 8; 64 32 16];
W=Wei(:);
W(5)=[];
% W=zeros(3,3);
% W1=zeros(3,3);
% W2=zeros(3,3);
% W3=zeros(3,3);
for i=3:w1+2
    for j=3:w2+2
        I_0=I1(i,j)-I1(i,j+1);
        I_45=I1(i,j)-I1(i-1,j+1);
        I_90=I1(i,j)-I1(i-1,j);
        I_135=I1(i,j)-I1(i-1,j-1);
        I_1=I1(i-1,j-1)-I1(i-1,j);
        I_2=I1(i-1,j)-I1(i-1,j+1);
        I_3=I1(i-1,j+1)-I1(i-1,j+2);
        I_4=I1(i,j)-I1(i,j+1);
        I_5=I1(i+1,j+1)-I1(i+1,j+2);
        I_6=I1(i+1,j)-I1(i+1,j+1);
        I_7 = I1(i+1,j-1)-I1(i+1,j);
        I_8=I1(i,j-1)-I1(i,j);
        I45_1 = I1(i-1,j-1)-I1(i-2,j);
        I45_2 = I1(i-1,j)-I1(i-2,j-1);
        I45_3 = I1(i-1,j+1)-I1(i-2,j+2);
        I45_4= I1(i,j+1)-I1(i-1,j+2);
        I45_5= I1(i+1,j-1)-I1(i,j);
        I45_6=I1(i+1,j)-I1(i,j+1);
        I45_7=I1(i+2,j-2)-I1(i+1,j-1);
        I45_8=I1(i,j-1)-I1(i-1,j);
        I90_1=I1(i-1,j-1)-I1(i-2,j-1);
        I90_2=I1(i-1,j)-I1(i-2,j);
        I90_3=I1(i-1,j+1)-I1(i-2,j+1);
        I90_4=I1(i,j+1)-I1(i-1,j+1);
        I90_5=I1(i-1,j-1)-I1(i,j-1);
        I90_6=I1(i-2,j)-I1(i-1,j);
        I90_7=I1(i-1,j+1)-I1(i,j+1);
        I90_8=I1(i,j-1)-I1(i-1,j-1);
        I135_1=I1(i-1,j-1)-I1(i-2,j-2);
        I135_2=I1(i-1,j)-I1(i-2,j-1);
        I135_3=I1(i-1,j+1)-I1(i-2,j);
        I135_4=I1(i,j+1)-I1(i-1,j);
        I135_5=I1(i+2,j+2)-I1(i+1,j+1);
        I135_6=I1(i+1,j)-I1(i,j-1);
        I135_7=I1(i+1,j+1)-I1(i,j);
        I135_8=I1(i,j-1)-I1(i-1,j-2);
        f_0=I_0.*[I_1 I_2 I_3 I_4 I_5 I_6 I_7 I_8];
        f_45=I_45.*[I45_1 I45_2 I45_3 I45_4 I45_5 I45_6 I45_7 I45_8];
        f_90=I_90.*[I90_1 I90_2 I90_3 I90_4 I90_5 I90_6 I90_7 I90_8];
        f_135=I_135.*[I135_1 I135_2 I135_3 I135_4 I135_5 I135_6 I135_7 I135_8];
        D0= f_0<0;
        D45= f_45<0;
        D90= f_90<0;
        D135= f_135<0;
        F1(i-2,j-2)=(D0*W);
        F2(i-2,j-2)=(D45*W);
        F3(i-2,j-2)=(D90*W);
        F4(i-2,j-2)=(D135*W);
    end
end
F_LDP12 =min(F1,F2);
F_LDP13 =min(F4,F3);
F_LDP14 =min(F_LDP13,F_LDP12);
h=F_LDP14;
end