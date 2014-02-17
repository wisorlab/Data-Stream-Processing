% imports
utils = getUtils;
xlUtils = getXlUtils;

% open file dialog
[file,path] = uigetfile({'*.xlsx','Excel Workbook (*.xlsx)';'*.xlsx','Excel 97-2003 Workbook (*.xls)';'*.*','All Files'},... % Open the user interface for opening files
'Select EDF File','MultiSelect','Off');

% Open an Excel ActiveX connection
Excel = actxserver('Excel.Application');
set(Excel, 'Visible', 1);
Wbooks = Excel.Workbooks;

% Get the worksheets from the given file
Wbook.triggered = Excel.Workbooks.Open(strcat(path,file));
Wbook_in = Excel.ActiveWorkbook;
Sheets_in = Wbook_in.Sheets;
for i=1:Sheets_in.Count % loop through the sheets of the input file
    sheet_in = get(Sheets_in, 'Item',i);
    [numcols,numrows] = xlUtils.size(sheet_in);
    header = xlUtils.getRow(sheet_in,1);
    
    % loop through the rows of each sheet
    for j=2:numrows
        row_in = xlUtils.getRow(sheet_in,j);
        m = mouse(row_in);
        
        
    end
end
%
% Wbook.triggered = invoke(Wbooks, 'Add');
% sheetnames = {'1 Hz Wake','1 Hz REM','1 Hz SWS','1 Hz Unscored','10 Hz Wake','10 Hz REM','10 Hz SWS','10 Hz Unscored','20 Hz Wake','20 Hz REM','20 Hz SWS','20 Hz Unscored','40 Hz Wake','40 Hz REM','40 Hz SWS','40 Hz Unscored'};
% Sheets = Excel.ActiveWorkBook.Sheets;
% for i = 1:13
%     invoke(Sheets,'Add');
% end
% for i = 1:16
%     sheet = get(Sheets, 'Item', i);
%     invoke(sheet, 'Activate');
%     sheet.name = sheetnames{i};
% end
% else
%     exportState = 0;