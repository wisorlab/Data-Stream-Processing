function [ matrix ] = compress( m, hertz, desired_hertz)
% matrix = compress(m, 5000, 2000, 8);
% Takes data sampled at 'hertz' and outputs data at a smaller sampling
% rate, 'desired_hertz'.

matrix = ones(floor(desired_hertz*length(m(:,1))/hertz),length(m(1,:)));  %floor rounds down
for i = 1:(floor(desired_hertz*length(m(:,1))/hertz));
    matrix(i,:) = m(floor((hertz/desired_hertz)*i),:);
end

end

