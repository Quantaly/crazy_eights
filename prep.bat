cd common
cmd /c pub get
cmd /c pub run build_runner build
cd ..\server
cmd /c pub get
cd ..\web_client
cmd /c pub get
cmd /c tools\zip_images.bat
cmd /c webdev build
@echo off
echo Preparations complete! From "server", run `pub run bin\server.dart` to host.