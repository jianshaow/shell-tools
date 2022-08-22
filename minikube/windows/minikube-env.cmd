@echo off

set HOMEDRIVE=F:
set HOMEPATH=\Users\ejiowuu

%HOMEDRIVE%
cd %HOMEPATH%

call minikube-profile.cmd %1 %2

set /p="getting minikube ip ... " < nul
FOR /F %%i IN ('minikube ip %1 %2') DO set MINIKUBE_IP=%%i
echo %ERRORLEVEL%
IF %ERRORLEVEL% == 89 (
  echo minikube is not started.
) ELSE (
  echo done
  set DOCKER_HOST=ssh://docker@%MINIKUBE_IP%
  set DOCKER
)

@echo on
