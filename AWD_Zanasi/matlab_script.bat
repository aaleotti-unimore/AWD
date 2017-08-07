cd C:\Apache24\htdocs\AWD\AWD_Zanasi\
start matlab -nosplash -nodesktop -minimize -noFigureWindows -logfile "%~1\out\logfile.txt" -r "Analizza_il_Sistema('%~2');exit;"
exit