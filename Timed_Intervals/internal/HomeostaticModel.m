function [Ti,Td,LA,UA,best_error]=HomeostaticModel(DataMatrix,signal)
% USAGE:  [Ti,Td,error]=Franken_like_model(DataMatrix,signal)
%
% DataMatrix: a sleep data file from Jonathan Wisor where sleep
%           state is in the first column, lactate in the second column and
%           EEG data in the columns after that.  
%
% signal: either 'delta' or 'lactate' 
%
% OUTPUT:
% Ti: the optimum value for tau_i, the rate of increase, using a
% two-process-like model, similar to Franken et al 2001
%
% Td: the optimum value for tau_d, the decay rate. 
% 
% error: the mean square error for the best fit
tic

% make a frequency plot, and use it to figure out upper and lower
% bounds for the model (like Franken et al. 2001 Figure 1)
[LA,UA]=make_frequency_plot_JW(DataMatrix,signal);

% if using lactate as a signal, prepare the data we will compare 
% to by finding all SWS episodes of longer than 5 minutes (like 
% Franken et al)
if strcmp(signal,'delta')
  [t_mdpt_SWS,data_at_SWS_midpoints,t_mdpt_indices]=find_all_SWS_episodes(DataMatrix,signal);
end

% if using a moving window for the upper and lower assymptotes, S
% will have 720 fewer elements than the number of rows of DataMatrix,
% so set up a new index for S
% mask=find(t_mdpt_indices>360 & t_mdpt_indices<(size(DataMatrix,1)-360));
% t_mdpt_SWS_moving_window=t_mdpt_SWS(mask);
% data_at_SWS_midpoints_moving_window=data_at_SWS_midpoints(mask);
% t_mdpt_indices_moving_window=t_mdpt_indices(mask);
mask=361:size(DataMatrix,1)-360';


dt=18/360;  % assuming data points are every 10 seconds and t is in hours 
tau_i=dt:6*dt:360*dt;
tau_d=dt:6*dt:360*dt;
error=zeros(length(tau_i),length(tau_d));

% COMPUTING LOOP
% run the model and compute error for all combinations of tau_i and tau_d

for i=1:length(tau_i)
  for j=1:length(tau_d)
    S=run_S_model(DataMatrix,dt,(LA(1)+UA(1))/2,LA,UA,tau_i(i),tau_d(j)); % run model
    i
    j
    % compute error (depending on if delta power or lactate was used)
    if strcmp(signal,'delta')
      error(i,j)=sqrt((sum((S([t_mdpt_indices])-data_at_SWS_midpoints).^2))/length(t_mdpt_indices)); %RMSE
    elseif strcmp(signal,'lactate')
      error(i,j)=sqrt((sum((S'-DataMatrix([mask],2)).^2))/(size(DataMatrix,1)-720)); %RMSE
    end
      
    % display progress only at intervals of .25*total 
    display_progress(length(tau_d)*(i-1)+j,length(tau_i)*length(tau_d));

  end
end


best_error=min(min(error));
[r,c]=find(error==min(min(error)));
Ti=tau_i(r);
Td=tau_d(c);

% run one more time with best fit and plot it (add a plot with circles)
S=run_S_model(DataMatrix,dt,(LA(1)+UA(1))/2,LA,UA,tau_i(r),tau_d(c));



%figure
t=0:dt:dt*(size(DataMatrix,1)-1);
if strcmp(signal,'delta') 
%  plot(t_mdpt_SWS,data_at_SWS_midpoints,'ro')
  hold off
 % plot(t,S)
  ylabel('Delta power')
  title('Best fit of model to delta power data')
elseif strcmp(signal,'lactate')
 %plot(t,DataMatrix(:,2),'ro')
  hold off
 %tS=t(361:end-360);
 % plot(tS,S)
 %plot(tS,LA,'--')
 %plot(tS,UA,'--')
 %ylabel('lactate')
 %title('Best fit of model to lactate data')
end
xlabel('Time (hours)')
hold off

toc

% hold on

% if strcmp(signal,'delta') 
%   plot(t_mdpt_SWS,data_at_SWS_midpoints,'ro')
% ylabel('Delta power')
% elseif strcmp(signal,'lactate')
%   plot(t,DataMatrix(:,2),'ro')
% ylabel('lactate')
% end

% hold off
% if strcmp(signal,'delta')
%   title('Best fit of model to delta power data')
% elseif strcmp(signal,'lactate')
%   title('Best fit of model to lactate data')
% end  
% xlabel('Time (hours)')



% make a contour plot of the errors
figure
[X,Y]=meshgrid(tau_d,tau_i);
contour(X,Y,error,100)
ylabel('\tau_i')
xlabel('\tau_d')

delete(findall(0,'Type','figure'))


%colorbar

