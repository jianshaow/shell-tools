@echo off

set HOMEDRIVE=F:
set HOMEPATH=\Users\ejiowuu

%HOMEDRIVE%
cd %HOMEPATH%

CALL minikube-profile.cmd %*

minikube stop %*

@echo on
