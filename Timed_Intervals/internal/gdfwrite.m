function [count]=gdfwrite(EDF,data)
% count=gdfwrite(EDF_Struct,data)
% Appends data to an EDF File (European Data Format for Biosignals) 
% one block per column (EDF raw form)
%

%	Version 0.40
%	4. Dec.1998
%	Copyright (c) 1997-98 by Alois Schloegl
%	a.schloegl@ieee.org	
                      
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the  License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

if EDF.AS.spb~=size(data,1)
        fprintf(2,'error EDFWRITE: datasize must fit according to the Headerinfo %i %i %i\n',EDF.AS.spb,size(data));
end;

if ~strcmp(EDF.VERSION(1:3),'GDF');
        data(data>2^15-1)=2^15-1;
        data(data<-2^15)=-2^15;
        count=fwrite(EDF.FILE.FID,data,'integer*2');
else
        count=0;
        bi=EDF.AS.bi;
        for k=1:EDF.NS,
                if EDF.GDFTYP(k)==0
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),'uchar');
                elseif EDF.GDFTYP(k)==1
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),'int8');
                elseif EDF.GDFTYP(k)==2
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),'uint8');
                elseif EDF.GDFTYP(k)==3
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),'int16');
                elseif EDF.GDFTYP(k)==4
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),'uint16');
                elseif EDF.GDFTYP(k)==5
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),'int32');
                elseif EDF.GDFTYP(k)==6
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),'uint32');
                elseif EDF.GDFTYP(k)==7
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),'int64');
                elseif 0; EDF.GDFTYP(k)==8
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),'uint64');
                elseif EDF.GDFTYP(k)==16
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),'float32');
                elseif EDF.GDFTYP(k)==17
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),'float64');
                        
                elseif 0;EDF.GDFTYP(k)>255 & EDF.GDFTYP(k) 256+64
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),['bit' int2str(EDF.GDFTYP(k))]);
                elseif 0;EDF.GDFTYP(k)>511 & EDF.GDFTYP(k) 511+64
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),['ubit' int2str(EDF.GDFTYP(k))]);
                        
                elseif EDF.GDFTYP(k)==256
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),'bit1');
                elseif EDF.GDFTYP(k)==512
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),'ubit1');
                elseif EDF.GDFTYP(k)==255+12
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),'bit12');
                elseif EDF.GDFTYP(k)==511+12
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),'bit12');
                elseif EDF.GDFTYP(k)==255+22
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),'bit22');
                elseif EDF.GDFTYP(k)==511+22
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),'bit22');
                elseif EDF.GDFTYP(k)==255+24
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),'bit24');
                elseif EDF.GDFTYP(k)==511+24
                        [cnt]=fwrite(EDF.FILE.FID,data(bi(k)+1:bi(k+1)),'bit24');
                else 
                        fprintf(2,'Error GDFWRITE: Invalid GDF channel type in %s at channel %i',EDF.FileName,k);
                        cnt=0;
                end;
                count=count+cnt;
        end;
%        count
 end;

