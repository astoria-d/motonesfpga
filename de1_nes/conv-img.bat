rem @echo off

set /p bin=Enter .bin file name:%=%

bin2hex %bin% %bin%.hex
@echo done.

pause

