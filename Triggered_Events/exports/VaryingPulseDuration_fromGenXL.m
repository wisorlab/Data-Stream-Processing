%=========================================================================
% created by @jonbrennecke / http://github.com/jonbrennecke
%=========================================================================

clear 

% add path to mcBinRead.m
addpath ../../../Matlab/etc/;

% add path to the XL class 
% @see https://github.com/jonbrennecke/matlab-utils
addpath ../../../Matlab/etc/matlab-utils/;

% open the file modal and get some '.raw' files
[file,path] = uigetfile({'*xlsx','Excel Spreadsheet (*.xlsx)';'*.*','All Files'; },'Select Excel File','MultiSelect','Off');

% instantiate an XL ActiveX object
xl = XL([ path file ]);

% get a reference to the sheet containing the 5000Hz data
sheet = xl.Sheets.Item('5000 Hz');
[ numcols, numrows ] = xl.sheetSize(sheet);

% get the triggered and random data into two (very large) cell arrays
header = xl.getCells( sheet, [1 1 numcols 1]);
trigData = xl.getCells( sheet, [ 1 2 (numcols/2 + 1) numrows] );
randData = xl.getCells( sheet, [ numcols/2+3 2 numcols/2-2 numrows] );

% find where 'Trig 0' and 'Rand 0' occur in the file
trig0 = find( cellfun(@(x)strcmp(x,'Trig 0'),header) == 1);
rand0 = find( cellfun(@(x)strcmp(x,'Rand 0'),header) == 1)- numcols/2 - 2;

for i=1:numrows

	try
		% parse the file info from each line to get the Hz
        num = Utils.split(trigData{i,3},'ms');
		hz =  str2num( num{1} ); % '0.5ms' -> {int} 0.5
		fc = 2 * round( hz * 10 / 2 ) * .0001; % 0.5 -> .0006 ( round s up to nearest even number, multiplies by .0001)
	catch
		continue
	end

	% get 71 data points starting at 'Trig X'
	trigRow(i,:) = trigData( i, trig0 + (fc * 5000) : trig0 + (fc * 5000)+70);
	randRow(i,:) = randData( i, rand0 + (fc * 5000) : rand0 + (fc * 5000)+70);  

end

xl = XL;
sheets = xl.addSheets({'0.5ms','1ms','2.5ms','5ms','10ms'});
xl.rmDefaultSheets();

randX = 20;

% set some preliminary header info to xl
for i=1:length(sheets)

    value = Utils.split(sheets{i}.Name,'ms');
	startAt = 2 * round(  str2num( value{1} ) * 10 / 2 ) * .0001;

	xl.setCells(sheets{i},[1,2],{ 'Triggered', sheets{i}.Name });
	xl.setCells(sheets{i},[1,3],[ startAt : 0.0002 : startAt + 0.0002 * 70 ]', hex2dec('99FFCC'));

	% we'll start the rand data at 100
	xl.setCells(sheets{i},[randX,2],{ 'Randomized', sheets{i}.Name });
	xl.setCells(sheets{i},[randX,3],[ startAt : 0.0002 : startAt + 0.0002 * 70 ]', hex2dec('99FFCC'));

end

blocks = struct( 't0p5ms', [], 't1ms', [], 't2p5ms', [], 't5ms', [], 't10ms', [], 'r0p5ms', [], 'r1ms', [], 'r2p5ms', [], 'r5ms', [], 'r10ms', [] );
filenames = struct( 't0p5ms', {{}}, 't1ms', {{}}, 't2p5ms', {{}}, 't5ms', {{}}, 't10ms', {{}} );

% for each row in trigData...
for i=1:size(trigRow,1)

	% the filename is the first element in trigData
	filename = trigData{i,1};

	if isstr(filename) 

		% extract filename info
		nameparts = regexp(filename, [
			'(?<date>\d+-\d+-\d+)'...		% date like M-D-Y
            '\s+'...						% space(s)						 
			'(?<stimtype>LED|Opto|US)' ...
            '\s+' ...
			'(?<freq>(\d*[.]?\d+))\s*(?=ms)' ... % freq
			],'names');
        
		try
			% append the triggered data to the appropriate field in 'blocks'
			key = [ 't' strrep([ nameparts.freq 'ms' ],'.','p') ];
			field = getfield( blocks, key );
			field(end+1,:) = cell2mat( trigRow(i,:) );
			blocks = setfield( blocks, key, field );

			% append the random data to the appropriate field in 'blocks'
			key2 = [ 'r' strrep([ nameparts.freq 'ms' ],'.','p') ];
			field2 = getfield( blocks, key2 );
			field2(end+1,:) = cell2mat( randRow(i,:) );
			blocks = setfield( blocks, key2, field2 );

			% append the filename to the appropriate field in 'filenames'
			field3 = getfield( filenames, key );
			field3{end+1} = filename;
			filenames = setfield( filenames, key, field3 );

		catch err
		end
	end
end

% finally, loop through the sheets and assign values
for i=1:length(sheets)

	% determine which sheet to write to
	names = fieldnames(blocks);
	sheet = xl.Sheets.Item( char( strrep( strrep( names(i),'p','.'), 't', '') ) );

	% get the triggered values and write them
	field = getfield( blocks, char( names(i) ) );
	xl.setCells( sheet, [ 2 3 ], field', hex2dec('FFFFCC') );

	% get the random values and write them
	field2 = getfield( blocks, char( names( 0.5 * length(names) + i) ) );
	xl.setCells( sheet, [ ( randX + 1 ) 3 ], field2', hex2dec('FFFFCC') );

	% next write the filenames over 'Trig' and 'Rand'
	field3 = getfield( filenames, char(names(i) ) );
	xl.setCells( sheet, [ 2 1 ], field3, hex2dec('FF6666'));
	xl.setCells( sheet, [ ( randX + 1 ) 1 ], field3, hex2dec('FF6666'));

	% write the vertical row labels
	xl.setCells(sheet,[1,76], {'Sum of column', 'Max of column', '', 'Average of the sums', 'Std/sqrt(length) of the sums', '', 'Average of the max', 'Std/sqrt(length) of the max' }' );
	xl.setCells(sheet,[randX,76], {'Sum of column', 'Max of column', '', 'Average of the sums', 'Std/sqrt(length) of the sums', '', 'Average of the max', 'Std/sqrt(length) of the max' }' );

	% write the sum of the columns
	xl.setCells(sheet,[2,76], sum( field') / 10 );
	xl.setCells(sheet,[( randX + 1 ),76], sum( field2')  / 10 );

	% write the max of the columns
	xl.setCells(sheet,[2,77], max( field' ) );
	xl.setCells(sheet,[( randX + 1 ),77], max( field2' ) );

	% write the average of the sums
	xl.setCells(sheet,[2,79], mean( sum(field') / 10 ) );
	xl.setCells(sheet,[( randX + 1 ),79], mean( sum(field2') / 10 ) );

	n = size(field,1);

	% write the std/sqrt(n) of the sums
	xl.setCells(sheet,[2,80], std(sum(field') / 10 )/sqrt( n ) );
	xl.setCells(sheet,[( randX + 1 ),80], std(sum(field2') / 10 )/sqrt( n ) );

	% write the average of the max
	xl.setCells(sheet,[2,82], mean( max( field' ) ) );
	xl.setCells(sheet,[( randX + 1 ),82], mean( max( field2' ) ) );

	% write the std/sqrt(n) of the max
	xl.setCells(sheet,[2,83], std(max(field'))/sqrt( n ) );
	xl.setCells(sheet,[( randX + 1 ),83], std(max(field2'))/sqrt( n ) );

end

name = Utils.split(file(1:31),'_');
xl.saveAs( strcat( name(1), '_Excel_SigmaPlot.xlsx' ) )

% ============================================================================================================================
% =================================================	Transpose the sheet for Statistica	======================================
% ============================================================================================================================

xl = XL; % new workbook

for i=1:length(sheets)
	[c,r] = xl.sheetSize( sheets{i} );
	data = xl.getCells( sheets{i}, [1 1 c r] );
	sheet = xl.addSheet( sheets{i}.Name );
	xl.setCells( sheet, [1,1], data' );
end

xl.rmDefaultSheets();

name = Utils.split(file(1:31),'_');
xl.saveAs( strcat( name(1), '_Excel_Statistica.xlsx' ) )