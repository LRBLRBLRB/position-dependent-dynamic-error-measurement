function table=opfs(A)  
biaozhi=A(1,1:end-1);
tmp=A(1,1:end-1);
A(1,:)=[];
z0=find(tmp==0);
x=A(:,end);
A(:,end)=[];
[n,k]=size(A);
if ~isempty(z0)
    z0=z0(:);
end
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
alpha1=0.05;alpha2=0.01;
m=max(A);
r=n./m;
Km=K./r(ones(mm,1),:);
Kmm=(Km-mean(x)).*(Km-mean(x));
Kmm(K==0)=0;
SSj=sum(Kmm,1).*r;
SST=sum(SSj);
fT=n-1;
fy=max(A)-1;
nz=nonzeros(biaozhi);
unz=unique(nz);
knz=length(unz);
linshi=[biaozhi',SSj',fy',zeros(k,1)];
for kk=1:knz
    ind=find(biaozhi==unz(kk));
    tsf(kk,:)=[unz(kk),sum(linshi(ind,[2:end]),1)];
    linshi(ind,:)=zeros(length(ind),4);
end
if isempty(z0)
    [tem,z0] = min(SSj);
    Ve=SSj(z0)/fy(z0);
else
    tsf(end+1,:)=sum(linshi,1);
    Ve=tsf(end,2)/tsf(end,3);
    tsf(end,end)=0;
end 
V=tsf(:,2)./tsf(:,3);
Se=SST;fe=fT;
for kkk=1:length(V)
    if (V(kkk)>2*Ve)
        Se=Se-tsf(kkk,2);
        fe=fe-tsf(kkk,3);
        tsf(kkk,4)=1;
    end
end
Ve=Se/fe;
Fb=V/Ve;
[ml,tem]=size(tsf);
table=cell(ml+3,7);
table(1,:)={'方差来源','平方和','自由度','均方差','F值','Fα','显著性'}; 
for kk=1:ml
    if tsf(kk,4)==0
        table{kk+1,1}=['因素',num2str(tsf(kk,1)),'*'];
    else
        table{kk+1,1}=['因素',num2str(tsf(kk,1))];
    end
end
if (tsf(ml,4)==0)&(~isempty(z0))
    table{ml+1,1}=['空列*'];
end
M=[tsf(:,[2,3]),V,Fb];
for kh=2:(ml+1)
    for kl=2:5
        table{kh,kl}=M(kh-1,kl-1);
    end
end
ntst=length(Fb);
for ktst=1:ntst
    F=finv(1-[alpha1;alpha2],tsf(ktst,3),fe);
    F1=min(F);F2=max(F);
    table{ktst+1,6}=[num2str(F1),';',num2str(F2)];
    if Fb(ktst)>F2
        table{ktst+1,7}='高度显著';
    elseif (Fb(ktst)<=F2)&(Fb(ktst)>F1)
        table{ktst+1,7}='显著';
    end
end
table(end-1,1:4)={'误差',Se,fe,Ve};
table(end,1:3)={'总和',SST,n-1};
