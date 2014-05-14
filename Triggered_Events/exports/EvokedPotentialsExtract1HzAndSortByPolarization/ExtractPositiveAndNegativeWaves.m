function [PositiveRunOut,PosRunStart,PositiveRunMn,PositiveAuc,PositivePeak,PositiveRunDuration,NegativeRunOut,NegRunStart,NegativeAuc,NegativeTrough,NegativeRunDuration,NegativeRunMn]=ExtractPositiveAndNegativeWavesWithMaxAvgValues (startvector,samplingrate);

%program finds longest run of positive values and negative values within
%a vector and reports each of these two runs from start to finish as separate vectors.
%also reports  the 

 zerogone=(find(logical(startvector==0))); %identify all zero values in the original vector...
 startvector(zerogone)=0.0001;              % and make them 0.0001 to prevent division by zero.
 matrix2=(startvector(2:end));    %align each n+1 value with each n value for division and subtraction
 matrix1=startvector(1:end-1);     %lop off last matrix value since it cannot be compared to subsequent
 zeroUpcross=find(logical(matrix1./matrix2<0) + logical(matrix1-matrix2<0)==2)+1;  %if matrix1(n) / matrix 2(n) is negative and matrix 1(n) is less than matrix 2(n), value crosses from negative to positive at matrix1(n)+1  
 zeroDowncross=find(logical(matrix1./matrix2<0) + logical(matrix1-matrix2>0)==2)+1;%if matrix1(n) / matrix 2(n) is negative and matrix 1(n) is greater than matrix 2(n), value crosses from positive to negative at matrix1(n)+1
 
 
 
 for i=1:length(zeroUpcross)
    try ZeroUpDuration(i)=zeroDowncross(min(find(logical(zeroDowncross>zeroUpcross(i)))))-zeroUpcross(i); %find first cross below zero after current cross above zero and calculate # points between the two.
    catch
        ZeroUpDuration(i)=length(matrix1)-zeroUpcross(i);
    end
    AucUpCurve(i)= sum(matrix1(zeroUpcross(i):zeroUpcross(i)+ZeroUpDuration(i)-1));   %find average value within each positive run
 end

 for i=1:length(zeroDowncross)
    try ZeroDownDuration(i)=zeroUpcross(min(find(logical(zeroUpcross>zeroDowncross(i)))))-zeroDowncross(i); %find first cross below zero after current cross above zero and calculate # points between the two.
    catch
        ZeroDownDuration(i)=length(matrix1)-zeroDowncross(i);
    end
    AucDownCurve(i)= sum(matrix1(zeroDowncross(i):zeroDowncross(i)+ZeroDownDuration(i)-1));   %find average value within each positive run
end
 
 
 %...  highest average potential value across all runs. 
 ans=max(AucUpCurve);
 min2=min(AucDownCurve);
 %... the earliest instance of the positive run w/ highest avg potentialin the event that there is a tie.  Not ideal.
     ans=zeroUpcross(min(find(logical(AucUpCurve==(max(AucUpCurve))))));
     Mean2=min(find(logical(AucDownCurve==(min(AucDownCurve)))));
 %... the position in matrix1 of the start of the earliest instance of the positive run with highest avg potential.
 ans=zeroUpcross(min(find(logical(AucUpCurve==(max(AucUpCurve))))));
 ans2=zeroDowncross(min(find(logical(AucDownCurve==(min(AucDownCurve))))));
 %extract from this position through the length of that positive run to generate PositiveRun. 
 PositiveRun=matrix1(zeroUpcross(min(find(logical(AucUpCurve==(max(AucUpCurve)))))):zeroUpcross(min(find(logical(AucUpCurve==(max(AucUpCurve))))))+(ZeroUpDuration(min(find(logical(AucUpCurve==(max(AucUpCurve))))))-1)); 
 NegativeRun=matrix1(zeroDowncross(min(find(logical(AucDownCurve==(min(AucDownCurve)))))):zeroDowncross(min(find(logical(AucDownCurve==(min(AucDownCurve))))))+(ZeroDownDuration(min(find(logical(AucDownCurve==(min(AucDownCurve))))))-1));
 
 %now trying to align PositiveRun to center of a vector for output of all PositiveRunOut
 PositiveRunOut=zeros(length(matrix1));
 PositiveRunOut=PositiveRunOut(1,:);
 NegativeRunOut=zeros(length(matrix1));
 NegativeRunOut=NegativeRunOut(1,:);
 
 %to start positive trace at start of output matrix  
 PositiveRunOut(1:length(PositiveRun))=PositiveRun;

 %to end negative trace at end of output matrix  
 NegativeRunOut(length(matrix1)-(length(NegativeRun))+1:length(matrix1))=NegativeRun;
 
 %to place traces at center of output matrices  
 %PositiveRunOut(round(length(matrix1)/2)-(length(PositiveRun)/2):round(length(matrix1)/2)+(length(PositiveRun)/2)-1)=PositiveRun;
 %NegativeRunOut(round(length(matrix1)/2)-(length(NegativeRun)/2):round(length(matrix1)/2)+(length(NegativeRun)/2)-1)=NegativeRun;
 
PositiveAuc=sum(PositiveRun);
NegativeAuc=sum(NegativeRun);
PositivePeak=max(PositiveRun);
NegativeTrough=min(NegativeRun);
PositiveRunDuration=length(PositiveRun)/samplingrate;
NegativeRunDuration=length(NegativeRun)/samplingrate;
PositiveRunMn=mean(PositiveRun);
NegativeRunMn=mean(NegativeRun);
PosRunStart=zeroUpcross(min(find(logical(ZeroUpDuration==(max(ZeroUpDuration)))))); %time of run onset is how far we are into the matrix minus the moment of ttl onset.
NegRunStart=zeroDowncross(min(find(logical(AucDownCurve==(min(AucDownCurve)))))); %time of run onset is how far we are into the matrix minus the moment of ttl onset.
return