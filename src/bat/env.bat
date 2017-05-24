set HOME=%HOMEDRIVE%%HOMEPATH%
cd %HOME%

set PATH=%PATH%;%gubg%\bin

rem Try to load local settings
call gubg.bat

cmd
