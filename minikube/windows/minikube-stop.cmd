@echo off

CALL goto-home.cmd

CALL minikube-profile.cmd %*

minikube stop %*

@echo on
