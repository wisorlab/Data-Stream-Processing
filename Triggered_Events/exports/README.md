Exports
======================

In the data analytics pipeline, 'Export' scripts act as an intermediary between software system.  Scripts categorized as 'Exports' are scripts whose main purpose is to output data from a source filetype ('*.raw','*.txt','*.edf' or similar), into another software system (i.e., from the TDT system -> Excel).  

Export scripts may optionally process the data in some way that ought to be specific to their file name.

### Table of Contents
- AvgStimRealDeal.m
	- No idea what this does.
- DoseResponse.m
	- Likewise
- VaryingPulseDuration
	- Main analysis script for Michele's 'Varying Pulse Duration' experiment
- UltraRealDeal.m
	- *@input* - 
	- *@output* - gives averages of *all* 'time zero' stimulation onsets.
- WindowingAnalysis.m
	- looks for stim onsets, and extracts a window of 500ms before and after each onset. The windowed data is then averaged and exported to Excel.
	- *@input* - an edf file
	- *@output* - Excel spreadsheet (and optioinally a plot) of processed data
