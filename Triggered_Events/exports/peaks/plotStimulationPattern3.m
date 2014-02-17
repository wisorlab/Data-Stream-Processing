function [fig] = plotStimulationPattern3(label,time,eeg,ttl,sleepData)
    % Enlarge figure size
    set(0,'Units','pixels') 
    scnsize = get(0,'ScreenSize');
    scnsize(1) = 10;
    scnsize(2) = 40;
    scnsize(3) = scnsize(3)-20;
    scnsize(4) = scnsize(4)-50;
    fig = figure;
    set(fig,'OuterPosition',scnsize);
    
    wakelines = zeros(2*length(find(sleepData == 1)));
    remlines = zeros(2*length(find(sleepData == 2)));
    sleeplines = zeros(2*length(find(sleepData == 3)));
    unclassifiedlines = zeros(2*length(find(sleepData == 4)));
    for i = 1:length(sleepData)
        if sleepData(i) == 1
            wakelines(2*(i-1)+1:2*(i-1)+2) = [10*(i-1) 10*(i-1)+10];
            remlines(2*(i-1)+1:2*(i-1)+2) = NaN;
            sleeplines(2*(i-1)+1:2*(i-1)+2) = NaN;
            unclassifiedlines(2*(i-1)+1:2*(i-1)+2) = NaN;
        elseif sleepData(i) == 2
            wakelines(2*(i-1)+1:2*(i-1)+2) = NaN;
            remlines(2*(i-1)+1:2*(i-1)+2) = [10*(i-1) 10*(i-1)+10];
            sleeplines(2*(i-1)+1:2*(i-1)+2) = NaN;
            unclassifiedlines(2*(i-1)+1:2*(i-1)+2) = NaN;
        elseif sleepData(i) == 3
            wakelines(2*(i-1)+1:2*(i-1)+2) = NaN;
            remlines(2*(i-1)+1:2*(i-1)+2) = NaN;
            sleeplines(2*(i-1)+1:2*(i-1)+2) = [10*(i-1) 10*(i-1)+10];
            unclassifiedlines(2*(i-1)+1:2*(i-1)+2) = NaN;
        elseif sleepData(i) == 4
            wakelines(2*(i-1)+1:2*(i-1)+2) = NaN;
            remlines(2*(i-1)+1:2*(i-1)+2) = NaN;
            sleeplines(2*(i-1)+1:2*(i-1)+2) = NaN;
            unclassifiedlines(2*(i-1)+1:2*(i-1)+2) = [10*(i-1) 10*(i-1)+10];
        end
    end     
    plot(wakelines,zeros(length(wakelines),1),'c','LineWidth',6000);
    hold on
    set(gca,'Xlim',[min(time) max(time)]);
    plot(sleeplines,zeros(length(sleeplines)),'y','LineWidth',6000);
    plot(remlines,zeros(length(remlines)),'m','LineWidth',6000);
    plot(unclassifiedlines,zeros(length(unclassifiedlines)),'k','LineWidth',6000); 
    legend('Wake','Sleep','REM');
    plot(time,eeg,'b');
    plot(time,ttl.*300,'r');
    title('Animal Recording');
    ylabel('Voltage (uV)');
    xlabel('Time (sec)');
      
    suptitle(label);
end