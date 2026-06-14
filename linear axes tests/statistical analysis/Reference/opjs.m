function  [varargout]=opjs(A,varargin)
if (nargin>1)& isnumeric(varargin{1})
    ymk=varargin{1};
else
    ymk=1;
end
biaozhi=A(1,1:(end-1));
A=A(2:end,:);
[m,n]=size(A);
B=A(:,1:end-1);
mm=max(B(:));
K=zeros(mm,n-1);
for kh=1:m
    for kl=1:(n-1)
        kt=A(kh,kl);
        K(kt,kl)=K(kt,kl)+A(kh,end);
    end
end
tem=biaozhi;
if ymk==0
    [tem,you]=min(K);
else
    [tem,you]=max(K);
end
YOU=['优水平：',num2str(you)];
R=max(K)-min(K);
tem=biaozhi;;
for k1=1:(length(tem)-1)%
    for k2=(k1+1):length(tem)        
        if (tem(k1)>100)&(tem(k1)==tem(k2))&(tem(k1)>-1)
            R(k1)=(R(k1)+R(k2))/2;
            R(k2)=nan;            
            tem(k2)=-10;
        end
    end
end
Rj=['极差R值：',num2str(R)];
[temp,cixu]=sort(R);
nal=sum(isnan(R));
cixu=cixu(1:(end-nal));
klen=length(cixu);
CX=[];
for k=klen:-1:1
    tem=cixu(k);
    if (biaozhi(tem)>0)&(biaozhi(tem)<100)
        CX=[CX,char('A'+biaozhi(tem)-1),' ;  '];
    elseif (biaozhi(tem)>100)
        CX=[CX,char('A'+floor(biaozhi(tem)/100)-1),'×',char('A'+mod(biaozhi(tem),100)-1),' ;  '];
    end
end
CX=['主次顺序：',CX];
if nargout==0
    disp('T值：')
    disp(K)
    fprintf('\n\n')
    disp(YOU)
    fprintf('\n\n')
    disp(Rj)
    fprintf('\n\n')
    disp(CX)
end
if nargout>=1
    varargout{1}=K;
end
if nargout>=2
    varargout{2}=YOU;
end
if nargout>=3
    varargout{3}=Rj;
end
if nargout>=4
    varargout{4}=CX;
end
if nargout>4
    return;
end
