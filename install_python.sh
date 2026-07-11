# Download Python 3.12.9
curl -o python-installer.exe https://www.python.org/ftp/python/3.12.9/python-3.12.9-amd64.exe

# Install silently (with PATH)
python-installer.exe /quiet InstallAllUsers=1 PrependPath=1

# Clean up
rm python-installer.exe

# Verify
python --version