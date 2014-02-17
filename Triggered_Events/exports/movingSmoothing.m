function [y] = movingSmoothing(x,points)
    y = zeros(size(x));
    halfWindow = round(points/2);
    windowMean = mean(x(1:2*halfWindow));
        % To speed up the algorithm, we only take the mean once,
        % then we multiply that mean by the number of points we
        % are averaging to get the sum of the window. Then we
        % subtract the first point in the window and add the next point
        % that will be at the end of the new window. We divide this 
        % by the number of points to find the new mean. 
    for i = halfWindow:size(x)-halfWindow-1
        y(i) = x(i)-windowMean;
        windowMean = ((windowMean*points)-x(i-halfWindow+1)+x(i+(halfWindow)+1))/points;
    end
    y(1:halfWindow) =  x(1:halfWindow)-mean(x(1:halfWindow));
    y(end-halfWindow:end) = x(end-halfWindow:end)-mean(x(end-halfWindow:end));
end