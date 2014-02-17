function [y] = roundp(x, n)
% roundp(x,n) rounds each element of x to the nearest multiple of 10^n 

y = 10^n*round(x/10^n); 

end

