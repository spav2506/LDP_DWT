function [A]=Angley_x(a,b)
% Angle=zeros(size(a));
A=zeros(size(a));
x=abs(a);
y=abs(b);
for p=1:size(a,1)
    for q=1:size(a,2)
        if a(p,q)>0 && b(p,q)>0 
            A(p,q)= atan(b(p,q)/a(p,q));
        end
        if a(p,q)<0 && b(p,q)>0
            A(p,q)=(pi/2)+atan((y(p,q))/(x(p,q)));
        end
        
        if a(p,q)<0 && b(p,q)<0
            A(p,q)=pi+atan((y(p,q))/(x(p,q)));

        end
        
        if a(p,q)>0 && b(p,q)<0
            A(p,q)=(3*pi/2)+atan((y(p,q))/(x(p,q)));

        end
        if a(p,q)<0 && b(p,q)==0
            A(p,q)=pi;
        end
        if a(p,q)==0&& b(p,q)<0
            A(p,q)=3*pi/2;

        end
        if a(p,q)==0 && b(p,q)>0
            A(p,q)=pi/2;
        end
        if a(p,q)>0 && b(p,q)==0
            A(p,q)=0;

        end
        if a(p,q)==0 && b(p,q)==0
            A(p,q)=0;

        end
    end
end