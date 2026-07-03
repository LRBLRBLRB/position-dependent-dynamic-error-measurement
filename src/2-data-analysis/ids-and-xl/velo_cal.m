function v  = cal_velo(t,x)
v = diff(x)./diff(t);
end