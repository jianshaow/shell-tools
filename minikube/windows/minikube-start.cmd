@echo off

set HOMEDRIVE=F:
set HOMEPATH=\Users\ejiowuu

%HOMEDRIVE%
cd %HOMEPATH%

CALL set-proxy-env.cmd

minikube start %*

CALL minikube-profile.cmd %*
CALL minikube-set-proxy.cmd
CALL minikube-ssh-key.cmd

@echo on
