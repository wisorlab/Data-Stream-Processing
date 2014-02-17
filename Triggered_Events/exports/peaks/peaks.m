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

% Create an output excell sheet
Wbook_out = invoke(Wbooks, 'Add');
Sheets_out = Excel.ActiveWorkBook.Sheets;

% Get the worksheets from the given file
Wbook.triggered = Excel.Workbooks.Open(strcat(path,file));
Wbook_in = Excel.ActiveWorkbook;
Sheets_in = Wbook_in.Sheets;

for k=1:Sheets_in.Count % loop through the worksheets of the input file
    sheet_in = get(Sheets_in, 'Item',k);
    [numcols,numrows] = xlUtils.size(sheet_in);
    header = xlUtils.getRow(sheet_in,1);
    
    % create output sheet
    sheet_out = invoke(Sheets_out,'Add');
    sheet_out.name = sheet_in.name;
    
    output = {'Gender','Filename','Strain','Animal ID','Group','Transgender','Intensity',...
        'Trig Max time', 'Trig Max Potential', 'Trig min time', 'Trig min potential',...
        'Rand Max time', 'Rand Max Potential', 'Rand min time', 'Rand min potential' };
        
    top=get(sheet_out,'Range', 'A1:O1');
    top.value = output;
        
    % loop through the rows of each sheet
    for j=2:numrows
        row_in = xlUtils.getRow(sheet_in,j);
        m = mouse(row_in);
        
        % create some arrays to hold the data
        randmax = {};
        randmin = {};
        trigmax = {};
        trigmin = {};
        
        % loop through rand/trig
        sections = { m.trig, m.rand };
        for n=1:2, section = sections{n};

            % loop through section (rand or trigger) values
            for i=1:numel(section)
                value = cell2mat(section(i));

                % are we greater than 0?
                if value>0
                    if ((i>20) && (i<(numel(section)-20)))
                        neighborhood = cell2mat(section(i-20:i+20));
                        largest = max(neighborhood);

                        % are we greater than or equal to the values in the surrounding neighborhood? (i.e. local maxima)
                        if value >= largest
                            if mod(n,2) 
                                trigmax{end+1} = value;
                                trigmax_time = header.value{8+i};
                            else 
                                randmax{end+1} = value;
                                randmax_time = header.value{408+i};
                            end
                        end
                    end
               
 
                % are we less than 0?
                elseif value<0
                    if ((i>20) && (i<(numel(section)-20)))
                        neighborhood = cell2mat(section(i-20:i+20));
                        largest = min(neighborhood);

                        % are we less than or equal to the values in the surrounding neighborhood? (i.e. local minima)
                        if value <= largest
                            if mod(n,2) 
                                trigmin{end+1} = value;
                                trigmin_time = header.value{8+i};

                            else 
                                randmin{end+1} = value;
                                randmin_time = header.value{408+i};
                            end
                        end
                    end
                end % end 'are we less/greater than 0?'
            end % end 'loop through values'
        end % end 'loop through rand/trig' 
        
        % process the max/min peaks
        
        range=get(sheet_out,'Range', sprintf('A%i:G%i',j,j));
        range.value = m.data;

        
        % Despite that fact that they are generic functions and 
        % should have bee added ages ago, strsplit and strjoin were 
        % only added in R2013a. Thus, the following is more robust, 
        % but fails in versions before R2013a 
        % trigmax_time = strsplit(trigmax_time,' ');
        % trigmin_time = strsplit(trigmin_time,' '); 
        % randmax_time = strsplit(randmax_time,' ');
        % randmin_time = strsplit(randmin_time,' ');
        trigmax = max(cellfun(@(x) x, trigmax));
        trigmin = max(cellfun(@(x) x, trigmin));
        randmax = max(cellfun(@(x) x, randmax));
        randmin = max(cellfun(@(x) x, randmin));
        output = {trigmax_time, num2str(trigmax), trigmin_time, num2str(trigmin) ...
            randmax_time, num2str(randmax), randmin_time, num2str(randmin)};
        
        range2=get(sheet_out,'Range', sprintf('H%i:O%i',j,j));
        range2.value = output;
    end  
end
