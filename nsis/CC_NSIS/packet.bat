:: file list
cd %~dp0
del bin\filelist.txt
filelist.exe Config # input=%~dp0bin # output=%~dp0filelist.txt # filter=.svn
move %~dp0filelist.txt %~dp0bin\filelist.txt

:: NSIS
"nsis\makensisw.exe" CC2360_2_utf8.nsi
:: NSIS
:: sign instraller 
sign\signtool.exe sign /f sign\netease_hz_2016_renewal.pfx /p Nte20nL!ne /d CC直播安装程序 /du http://cc.163.com CC_Setup_3.19.2_11215_gfxz.exe

