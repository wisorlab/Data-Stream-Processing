function [LabelLine] = MakeLabel( StringText,NumberIterations,NumberLoops)
%UNTITLED2 Summary of this function goes here
%   There is frequently a need to have labels as the first row in a Matlab output file of type xlsx.
% For instance, I often output EEG pwr 1-20 Hz in 1 Hz bins, each represented by 1 column of data in the spreadsheet.
% I need to output a row of labels: 'FileID, EEG2-1, EEG2-2, EEG2-3 etc. to EEG2-20' at the top of the spreadsheet.
%This fxn takes an input string (i.e., 'EEG2-' and a counter variable and concatenates them to produce these labels.  
%There are three inputs for this function: the string, the number of iterations of that string, and the number of
%loops through the counter one wants to run.

CellCount=0;

for BigLoop=1:NumberLoops
  for SmallLoop=1:NumberIterations 
    CellCount = CellCount+1;  
    LabelLine {CellCount} = [StringText '-' num2str(SmallLoop)];
  end  
end


end



