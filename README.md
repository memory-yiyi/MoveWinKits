## About
Move the "Windows Kits" folder without causing serious errors.
## Usage Method
1. Download the code into a new folder.
2. Run the following code as an administrator.
```shell
PowerShell -NoExit -File .\MoveWindowsKits.ps1 -ExecutionPolicy Bypass
```
3. Enter the path <font color=red>(please see [Note](#note) for input rules)</font> and wait for the program to run.
### <span id='note'>Note</span>
* The path is the parent folder of "Windows Kits". <br>
For example, if "D:\\Windows Kits", you should enter "D:\\".<br>
* Both entries follow the above rules.
## Manual
* Please manually move when folder move fails.
* Please manually import `ChangeLogxxx.reg` when registry import fails.
* When there is an exception, you can manually import `BackupLogxxx.reg` and move the folder to its original location.
### Note
You can check the problem through `BackupLogxxx.reg` and report it to the Issue to make the script more comprehensive.
## Version Log
### V2.3
* Add running checks to reduce the possibility of movement failure.
### V2.2
* Add backup registry. Enable clearer identification of the problem when encountering it.
### V2.1
* Fix some bugs.
### V2.0
#### New
* Further reduce the difficulty of script operations by using a single language (just kidding).
* Improve the prompts for each stage so that you can clearly know which stage the script is currently in.
#### Fix bugs
* If the key is just at the end of the file when extracting the key registry, it will be omitted.
### V1.0
Compared with the previous version (although it has not been released), this version has flexibility, and users can specify the path. The robustness of the program has also been improved.
### VAlpha
Semi automatic, cumbersome process, discontinued.
## At Last
If you have any good ideas, you are welcome to propose or submit changes directly.