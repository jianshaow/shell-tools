@echo off

set HOMEDRIVE=F:
set HOMEPATH=\Users\ejiowuu

%HOMEDRIVE%
cd %HOMEPATH%

CALL minikube-profile.cmd %*

set MINIKUBE_IP=
set /p="getting minikube ip ... " < nul
FOR /F %%i IN ('minikube ip %*') DO (
  IF NOT DEFINED MINIKUBE_IP (
    set MINIKUBE_IP=%%i
    set ERROR=false
  ) ELSE (
    IF %%i NEQ "" (
      set ERROR=true
    )
  )
)
IF %ERROR% == true (
  echo cluster[%MINIKUBE_PROFILE%] is not started.
) ELSE (
  echo done
  set DOCKER_HOST=ssh://docker@%MINIKUBE_IP%
  set DOCKER
)

@echo on
