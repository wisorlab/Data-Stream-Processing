[hdr,data]=edfread(fname);
t = 1/fs:1/fs:hdr.duration;
plot(t,data(:,1))
hold on
plot(t,data(:,4).*100,'r')