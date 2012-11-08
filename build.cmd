@cd library

del /Q ndll\Windows\*.ilk
del /Q src\neko\*.ncb
del /Q src\neko\*.user
del /Q src\neko\Debug\*

7z a -tzip ..\library.zip *

@cd ..
