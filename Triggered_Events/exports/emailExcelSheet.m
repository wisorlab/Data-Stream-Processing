% Open Excel, add workbook, change active worksheet,
% get/put array, save, and close

% First open an Excel Server
Excel = actxserver('Excel.Application');
set(Excel, 'Visible', 1);

% Insert a new workbook
Workbooks = Excel.Workbooks;
Workbook = invoke(Workbooks, 'Add');

% Make the second sheet active
Sheets = Excel.ActiveWorkBook.Sheets;
sheet2 = get(Sheets, 'Item', 2);
invoke(sheet2, 'Activate');

% Get a handle to the active sheet
Activesheet = Excel.Activesheet;

% Put a MATLAB array into Excel
A = [1 2; 3 4]; 
ActivesheetRange = get(Activesheet,'Range','A1:B2');
set(ActivesheetRange, 'Value', A);

% Get back a range. It will be a cell array, 
% since the cell range can
% contain different types of data.
Range = get(Activesheet, 'Range', 'A1:B2');
B = Range.value;

% Convert to a double matrix. The cell array must contain only scalars.
B = reshape([B{:}], size(B));

% Now save the workbook
invoke(Workbook, 'SaveAs', 'myfile.xls');

% To avoid saving the workbook and being prompted to do so,
% uncomment the following code.
% Workbook.Saved = 1;
% invoke(Workbook, 'Close');

% Quit Excel
invoke(Excel, 'Quit');

% End process
delete(Excel);