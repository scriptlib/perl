@ECHO OFF
if "%XR_PERL_SOURCE_DIR%"=="" goto noenv
goto end
:noenv
set XR_PERL_SOURCE_DIR=%~dp0
set XR_PERL_SOURCE_DIR=%XR_PERL_SOURCE_DIR:\bin\=%
set XR_PERL_SOURCE_DIR=%XR_PERL_SOURCE_DIR:\bin=%
:end

 
perl "%XR_PERL_SOURCE_DIR%\plrm" %* 
