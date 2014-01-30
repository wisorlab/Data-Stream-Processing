function [filtered_matrix] = ChebyshevIIFilter(matrix,fs,p1,p2,s1,s2,Rp,Rs)
    Wp=[p1 p2]/(fs/2); Ws=[s1 s2]/(fs/2);  
    [n, Wn]=cheb2ord(Wp,Ws,Rp,Rs);
    [bb,aa]=cheby2(n,Rs,Wn);
    filtered_matrix = matrix;
    filtered_matrix(:,2:end) = filtfilt(bb,aa,matrix(:,2:end));

