@echo off

set HOMEDRIVE=F:
set HOMEPATH=\Users\ejiowuu

%HOMEDRIVE%
cd %HOMEPATH%

call set-proxy-env.cmd

minikube start %1 %2 %3 %4 %5 %6 %7 %8 %9

call minikube-profile.cmd %1 %2
call minikube-set-proxy.cmd
call minikube-ssh-key.cmd

@echo on
