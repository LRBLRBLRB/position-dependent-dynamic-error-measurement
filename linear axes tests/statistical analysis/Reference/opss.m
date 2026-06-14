function [varargout]=opss(A,varargin)
if (nargin>1)& isnumeric(varargin{1})
    ymk=varargin{1};
else
    ymk=1;
end
biaozhi=A(1,1:(end-1));
if nargout==0
    opjs(A,ymk)
    if any(biaozhi>100)
        op2y(A);
    end
    opqs(A)
    opfs(A)
end
[K,YOU,Rj,CX]=opjs(A,ymk);
table=opfs(A);
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
if nargout>=5
    varargout{5}=table;
end
if nargout>=6
    if any(A(1,1:end-1)>100)
        varargout{6}=op2y(A);
    else
        varargout{6}=[];
        return
    end
end
