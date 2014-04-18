run(VaryingPulseDuration_fromGenXL)

xl = XL; % new workbook

for i=1:length(sheets)
	[c,r] = xl.sheetSize( sheets{i} );
	data = xl.getCells( sheets{i}, [1 1 c r] );
	sheet = xl.addSheet( sheets{i}.Name );
	xl.setCells( sheet, [1,1], data' );
end

xl.rmDefaultSheets();

% % xl.saveAs( strcat( name(1), '_Excel_Statistica.xlsx' ) )