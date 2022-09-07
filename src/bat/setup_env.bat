@echo off
echo Setting-up GUBG environment...

pushd %~dp0..
set gubg=%cd%
popd
echo gubg=%gubg%

set HOME=%HOMEDRIVE%%HOMEPATH%
echo HOME=%HOME%

set PATH=%PATH%;%gubg%\bin
echo Added %gubg%\bin to PATH

if exist %HOME%\gubg.bat (
	echo Loading local gubg touches from %HOME%\gubg.bat
	call %HOME%\gubg.bat
) else (
	echo No local gubg touches file %HOME%\gubg.bat found
)

echo ...done
@echo on
