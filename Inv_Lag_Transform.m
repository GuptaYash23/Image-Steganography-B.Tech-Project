function p = ILT(t)
% Inverse Laguere Transform
p(1,1)=t(1,1);
p(1,2)=-t(1,1)+t(1,2);
p(1,3)=2*t(1,1)-4*t(1,2)+t(1,3);
end

