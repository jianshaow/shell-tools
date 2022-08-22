@echo off

set HOMEDRIVE=F:
set HOMEPATH=\Users\ejiowuu

%HOMEDRIVE%
cd %HOMEPATH%

call minikube-profile.cmd %1 %2

minikube stop %1 %2

@echo on
