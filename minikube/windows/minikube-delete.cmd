@echo off

CALL goto-home.cmd

CALL minikube-profile.cmd %*

minikube delete %*

set MINIKUBE_PROFILE=
prompt

@echo on
