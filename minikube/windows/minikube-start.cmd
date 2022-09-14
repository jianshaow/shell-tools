@echo off

CALL goto-home.cmd

CALL set-proxy-env.cmd

minikube start %*

CALL minikube-profile.cmd %*
CALL minikube-set-proxy.cmd
CALL minikube-ssh-key.cmd

@echo on
