# import os
# filepath = "test"
# os.system('"C:\Apache24\htdocs\AWD\AWD_Zanasi\matlab.bat" [filepath]')

from subprocess import Popen
p = Popen("matlab.bat", cwd=r"C:\\Apache24\\htdocs\\AWD\\AWD_Zanasi", shell=True)
stdout, stderr = p.communicate()

exit()