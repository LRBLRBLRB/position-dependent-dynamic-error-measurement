function [varargout]=op2y(A)
biaozhi=A(1,1:(end-1));
x=A(2:end,end);
[tem,I]=sort(biaozhi);
A=A(:,I);
while tem(1)==0
    tem(1)=[];
    A(:,1)=[];
end
while tem(end)>100
    tem(end)=[];
    A(:,end)=[];
end
tem=A(1,:);
B=A(2:end,:);
ub=unique(B(:));
[mb,nb]=size(B);
nry=nchoosek(nb,2);
ery=cell(nry,1);
C=zeros(length(ub));
kcell=1;
for nh=1:(nb-1)
    for nl=(nh+1):nb
        for k=1:mb
            ch=B(k,nh);
            cl=B(k,nl);
            C(ch,cl)=C(ch,cl)+x(k);
        end
        pj=C;
        ery{kcell}={[nh,nl],pj};
        kcell=kcell+1;
        C=zeros(size(C));
    end
end
for kcll=1:nry
    C=ery{kcll};
    AB=C{1};
    juzhen=C{2};
    [m,n]=size(juzhen);
    y=cell(m+1,n+1);
    A=char(['A'+AB(1)-1]);
    B=char(['A'+AB(2)-1]);
    y{1,1}=[A,'\',B];
    for k=1:n
        y{1,k+1}=[B,num2str(k)];
    end
    for k=1:m
        y{k+1,1}=[A,num2str(k)];
    end
    for kh=1:m
        for kl=1:n
            y{kh+1,kl+1}=juzhen(kh,kl);
        end
    end
    eyb{kcll,1}=['因素',A,'、',B,'的二元表:'];
    eyb{kcll,2}=y;
end
if nargout==0
    for kcll=1:nry
        disp(eyb{kcll,1});
        disp(eyb{kcll,2});
        fprintf('\n')
    end
end
if nargout==1
    varargout{1}=eyb;
end
