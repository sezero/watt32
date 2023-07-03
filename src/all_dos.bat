@echo off
if not %1. == clean. call configur.bat all
if %1. == clean.     call configur.bat clean

echo ---- running djgpp.mak %1 ---- > make.log
make  -f djgpp.mak %1 >&> make.log

echo ---- running highc.mak %1 ---- >> make.log
maker -f highc.mak %1  >> make.log

echo ---- running watcom_s.mak %1 ---- >> make.log
wmake -h -f watcom_s.mak %1 >> make.log

echo ---- running watcom_l.mak %1 ---- >> make.log
wmake -h -f watcom_l.mak %1 >> make.log

echo ---- running watcom_f.mak %1 ---- >> make.log
wmake -h -f watcom_f.mak %1 >> make.log

echo ---- running watcom_w.mak %1 ---- >> make.log
wmake -h -f watcom_s.mak %1 >> make.log

call setbcc 4
echo ---- running bcc_s.mak %1 ---- >> make.log
maker -f bcc_s.mak %1 >> make.log

echo ---- running bcc_l.mak %1 ---- >> make.log
maker -f bcc_l.mak %1 >> make.log

call setbcc 5
echo ---- running bcc_f.mak %1 ---- >> make.log
maker -f bcc_f.mak %1 >> make.log

