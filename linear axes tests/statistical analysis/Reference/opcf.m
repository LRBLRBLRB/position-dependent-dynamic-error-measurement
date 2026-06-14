function  [table,stat]=opcf(A)
alpha1=0.05;alpha2=0.01;
biaozhi=A(1,:);
ind=find(biaozhi<0);
X=A(2:end,ind);
biaozhi(ind)=[];
A(1,:)=[];
A(:,ind)=[];
T=sum(X(:));
[n,s]=size(X);
[n,k]=size(A);
Atm=X.*X;
Se2=sum(Atm(:))-sum(sum(X,2).*sum(X,2))/s;
fe2=n*(s-1);
CT=T*T/n/s;
SST=sum(Atm(:))-CT;
fT=n*s-1;
A=repmat(A,s,1);
x=X(:);
mm=max(A(:));
K=zeros(mm,k);
for kk=1:k
    tmp=A(:,kk);
    kmax=max(tmp);
    for kh=1:kmax
        tind=find(tmp==kh);
        K(kh,kk)=sum(x(tind));
    end    
end
m=max(A);
r=n./m;
KK=K.*K;
SSj=sum(KK)./r/s-CT;
fy=m-1;
nz=nonzeros(biaozhi);
unz=unique(nz);
knz=length(unz);
linshi=[biaozhi',SSj',fy',zeros(k,1)];
for kk=1:knz
    ind=find(biaozhi==unz(kk));
    tsf(kk,:)=[unz(kk),sum(linshi(ind,[2:end]),1)];
    linshi(ind,:)=zeros(length(ind),4);
end
Se1=0;
fe1=0;
z0=find(biaozhi==0);
if ~isempty(z0)
    z0=z0(:);
    TSe1=sum(linshi(z0,:),1);
    Se1=TSe1(2);
    fe1=TSe1(3);
else
    Se1=0;
    fe1=0;
end
Se=Se1+Se2;
fe=fe1+fe2;
Ve=Se/fe;
V=tsf(:,2)./tsf(:,3);
for kkk=1:length(V)
    if (V(kkk)>2*Ve)
        tsf(kkk,4)=1;
    else
        Se=Se+tsf(kkk,2);
        fe=fe+tsf(kkk,3);
        tsf(kkk,4)=0;
    end
end
Ve=Se/fe;
Fb=V/Ve;
[ml,tem]=size(tsf);
table=cell(ml+1,7);
table(1,:)={'方差来源','平方和','自由度','均方差','F值','Fα','显著性'};
for kk=1:ml
    if tsf(kk,4)==0
        table{kk+1,1}=['因素',num2str(tsf(kk,1)),'*'];
    else
        table{kk+1,1}=['因素',num2str(tsf(kk,1))];
    end
end

M=[tsf(:,[2,3]),V,Fb];
for kh=2:(ml+1)
    for kl=2:5
        table{kh,kl}=M(kh-1,kl-1);
    end
end
ntst=length(Fb);Ksui=0;
for ktst=1:ntst
    lian=finv(1-[alpha1;alpha2],tsf(ktst,3),fe);
    F1=min(lian);F2=max(lian);
    table{ktst+1,6}=[num2str(F1),';',num2str(F2)];
    if Fb(ktst)>F2
        table{ktst+1,7}='高度显著';Ksui=Ksui+1;
    elseif (Fb(ktst)<=F2)&(Fb(ktst)>F1)
        table{ktst+1,7}='显著';Ksui=Ksui+1;
    else
        table{ktst+1,7}='不显著';
    end
end

if (~isempty(z0))
    table(end+1,1:3)={'误差e1',Se1,fe1};
end
table(end+1,1:3)={'误差e2',Se2,fe2};
table(end+1,1:4)={'误差',Se,fe,Ve};
table(end+1,1:3)={'总和',SST,fT};
if fe1==0
    Falpha=NaN;
else
    Fsi=Se1/Se2*fe2/fe1;
    Falpha=1-fcdf(Fsi,fe1,fe2);
end
psui=Ksui/ntst;
stat=[psui,Falpha];