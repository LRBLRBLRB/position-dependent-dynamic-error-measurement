function opqs(A)
biaozhi=A(1,1:(end-1));
K=opjs(A);
[m,n]=size(K);
tSF=[K;ones(size(K))];
tem=biaozhi;
for k1=n:-1:2
    for k2=(k1-1):-1:1
        if (tem(k1)==tem(k2))
            tSF(:,k2)=tSF(:,k1)+tSF(:,k2);
            tSF(:,k1)=[];
            tem(k1)=[];
            break
        end
    end
end
Kt=tSF(1:m,:)./tSF((m+1):end,:);
[tem,I]=sort(tem);
K=Kt(:,I);
while tem(1)==0
    tem(1)=[];
    K(:,1)=[];
end
[m,n]=size(K);
nk=ceil(sqrt(n));
mk=ceil(n/nk);
figure
for kk=1:n
    subplot(mk,nk,kk)
    Ktm=K(:,kk);
    Ktm(Ktm==0)=[];
    plot(Ktm,'.k-')
    t=tem(kk);
    if (tem(kk)>0)&(tem(kk)<100)
        SS=['“ÚÀÿ',char('A'+tem(kk)-1)];
    elseif tem(kk)>100
        SS=['“ÚÀÿ',char('A'+floor(tem(kk)/100)-1),'°¡', ... 
            char('A'+mod(tem(kk),100)-1)];
    end        
    title(SS)
end
