@echo off

set HOMEDRIVE=F:
set HOMEPATH=\Users\ejiowuu

%HOMEDRIVE%
cd %HOMEPATH%

call minikube-profile.cmd %1 %2

minikube delete %1 %2

set MINIKUBE_PROFILE=
prompt

@echo on
