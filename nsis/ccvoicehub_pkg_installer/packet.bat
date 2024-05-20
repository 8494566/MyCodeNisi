@echo on
cd /d %~dp0
rmdir /S /Q %1%
rmdir /S /Q bin
::::tools\svn\svn.exe update
::::copy /y NewCharacter.txt "tools\cc res\NewCharacter.txt"
set svn_version=%2%
set svn_path=%3%
set version=%4%
set make_inner=%5%
tools\svn\svn.exe export %svn_path% -r%svn_version%
cd %1%
python3 setup_update/pack_for_installer.py ../../bin %version% %make_inner%
echo %errorlevel%
if %errorlevel% NEQ 0 exit /b %errorlevel%
cd ..

:: file list
cd %~dp0
del bin\filelist.txt
tools\filelist.exe Config # input=%~dp0bin # output=%~dp0tools\filelist.txt # filter=.svn


move %~dp0tools\filelist.txt %~dp0bin\%version%\filelist.txt


"tools\nsis\makensis.exe" tools\CC2360_2_utf8.nsi

rmdir /S /Q %1%
rmdir /S /Q bin
::exit

:: packet.bat ccvoice_dev 181013 https://svn-cc.gz.netease.com/release/cc/client/ccvoice_dev