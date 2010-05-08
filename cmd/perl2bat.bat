@ECHO OFF
if "%~1"=="" goto USAGE
if "%XR_PERL_SOURCE_DIR%"=="" goto noenv
goto okenv
:noenv
set XR_PERL_SOURCE_DIR=%~dp0
set XR_PERL_SOURCE_DIR=%XR_PERL_SOURCE_DIR:\cmd\=%
set XR_PERL_SOURCE_DIR=%XR_PERL_SOURCE_DIR:\cmd=%
:okenv
setlocal
set scriptfullname=%~1
if "%~2"=="" set scriptname=%scriptfullname:.pl=%
if not "%~2"=="" set scriptname=%~2
echo For "%XR_PERL_SOURCE_DIR%\%scriptfullname%" +
echo Creating "%XR_PERL_SOURCE_DIR%\bcmd\%scriptname%.bat" ...
type "%~dp0\perl2bat.tmpl" >"%XR_PERL_SOURCE_DIR%\cmd\%scriptname%.bat"
echo perl "%%XR_PERL_SOURCE_DIR%%\%scriptfullname%" %%* >>"%XR_PERL_SOURCE_DIR%\cmd\%scriptname%.bat"
echo OK.
endlocal




 
