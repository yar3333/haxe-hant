@cd library

del /Q ndll\Windows\*.ilk
del /Q ndll\Windows\*.pdb
del /Q src\neko\*.ncb
del /Q src\neko\*.user
del /Q src\neko\Debug\*
del /Q src\neko\Release\*

7z a -tzip ..\library.zip *

@cd ..
