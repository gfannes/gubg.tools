set PATH=%PATH%;%gubg%/bin

set _ac_vs_version=2017

set _ac_bs=cbs
set _ac_bs=rbs
set _ac_arch=x64
set _ac_arch=x32
set _ac_type=debug
set _ac_type=release
set auro_compiler=%_ac_bs%-cl-%_ac_arch%-%_ac_type%

rem Translate the arch into something VS can understand
if "%_ac_arch%" == "x32" set _vs_arch=x86
if "%_ac_arch%" == "x64" set _vs_arch=x64

rem VS2017, cl 19.1
if "%_ac_vs_version%" == "2017" set _vs_path=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build
rem VS2015, cl 19.0
if "%_ac_vs_version%" == "2015" set _vs_path=C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC
rem VS2013, cl 18
if "%_ac_vs_version%" == "2013" set _vs_path=C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC
rem VS2010, cl 16
if "%_ac_vs_version%" == "2010" set _vs_path=C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC

call "%_vs_path%\vcvarsall.bat" %_vs_arch%

set dir=auro-codec-v4
set dir=fusion-am4car
cd %dir%

cmd
