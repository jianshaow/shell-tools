@echo off

FOR /F "delims=" %%i IN (.ssh\id_rsa.pub) DO set ID_KEY=%%i
echo waiting ...
minikube ssh "echo '%ID_KEY%' >> .ssh/authorized_keys"
minikube ssh cat .ssh/authorized_keys
echo done.

@echo on