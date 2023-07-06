@echo off
setlocal
set FILE_TO_UPLOAD=some-local-file.txt
set FTP_HOST=ftp.somewhere.com
set FTP_DIRECTORY=/some/remote/directory

set FTP_USER=username
set FTP_PASS=passord

wput-vc.exe -D -u %FTP_USER% -p %FTP_PASS% -h %FTP_HOST% -i %FILE_TO_UPLOAD% -d %FTP_DIRECTORY% %$
