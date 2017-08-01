import subprocess
cwd=r"C:\\Apache24\\htdocs\\AWD\\AWD_Zanasi"
res = subprocess.call(".\matlab_script.cmd "+cwd, shell=True)
print(res)