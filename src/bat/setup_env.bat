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

echo ...done
@echo on
