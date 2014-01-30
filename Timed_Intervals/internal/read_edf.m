function edf = edf_read(filename)
	try
		% open file for reading
		fid = fopen(filename,'r');
		content = fread(fid,'*char');

		% create edf struct
		% first 256 bytes contains basic file information
		edf.h1.version = strtrim(sprintf('%c',content(1:8)));
		edf.h1.local_pat_id = strtrim(sprintf('%c',content(9:88)));
		edf.h1.local_rec_id = strtrim(sprintf('%c',content(89:168)));
		edf.h1.startdate = strtrim(sprintf('%c',content(169:176)));
		edf.h1.starttime = strtrim(sprintf('%c',content(177:184)));
		edf.h1.header_bytes = strtrim(sprintf('%c',content(185:192)));
		edf.h1.num_records = strtrim(sprintf('%c',content(237:244)));
		edf.h1.duration = strtrim(sprintf('%c',content(245:252)));
		edf.h1.num_signals = strtrim(sprintf('%c',content(253:256)));

		ns = str2num(edf.h1.num_signals);

		% the next ns*256 bytes contains information specific to each signal recorded
		% and depedent on the value of 'ns' (number of signals).
		label = sprintf('%c',content(257:256+ns*16));
		transducer = sprintf('%c',content(257+ns*16:256+ns*80));
		dimension = sprintf('%c',content(257+ns*80:256+ns*88));
		pmin = sprintf('%c',content(257+ns*88:256+ns*96));
		pmax = sprintf('%c',content(257+ns*96:256+ns*104));
		dmax = sprintf('%c',content(257+ns*104:256+ns*112));
		dmin = sprintf('%c',content(257+ns*112:256+ns*120));
		prefiltering = sprintf('%c',content(257+ns*120:256+ns*200));
		nr = sprintf('%c',content(257+ns*216:256+ns*232));

		% parse the data and return as fields of the struct
		expand = { regexp(label,'\w+','match'), regexp(transducer,'\w+','match'), regexp(dimension,'\w+','match'), ...
			regexp(dimension,'\w+','match'), regexp(dimension,'\w+','match'), regexp(dmax,'-\d+\.\d+','match'), ...
			regexp(dmin([1:8 ' ' 9:16 ' ' 17:24 ' ' 25:32]),'\S+','match'), regexp(prefiltering,'\w+','match'), regexp(nr,'\w+','match')};

		[edf.h2.label edf.h2.transducer edf.h2.dimension edf.h2.pmin edf.h2.pmax edf.h2.dmax edf.h2.dmin edf.h2.prefiltering edf.h2.nr] = expand{:};

		% create data arrays
		% samples are stored as 2-byte integers in 2's complement format

		% content(257+ns*256:256+ns*256+2*str2num(edf.h2.nr{1}))

	catch err
		msg = getReport(err);
		warning(msg);
	end
end