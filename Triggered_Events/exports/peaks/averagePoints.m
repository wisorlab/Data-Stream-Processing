function [ matrix ] = averagePoints(m,nPoints)
% matrix = averagePoints(m,nPoints)
% Averages every nPoints points in a vector or matrix;

matrix = zeros(length(m(:,1)),ceil(length(m(1,:))/nPoints));
for i = 1:length(matrix)
    matrix(:,i) = mean(m(:,(nPoints*(i-1)+1):(nPoints*(i-1)+nPoints)),2);
end

end