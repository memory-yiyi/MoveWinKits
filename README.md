## About
Move the "Windows Kits" folder without causing serious errors.
## Usage Method
1. Download the code into a new folder.
2. Run the following code as an administrator.
```shell
PowerShell -NoExit -File .\MoveWindowsKits.ps1
```
3. Enter the path <font color=red>(please see [Note](#note) for input rules)</font> and wait for the program to run.
### <span id='note'>Note</span>
* The path is the parent folder of "Windows Kits". <br>
For example, if "D:\\Windows Kits", you should enter "D:\\".<br>
* Both entries follow the above rules.
## Version Log
### V2.0
* Further reduce the difficulty of script operations by using a single language (just kidding)
* Improve the prompts for each stage so that you can clearly know which stage the script is currently in.
### V1.0
Compared with the previous version (although it has not been released), this version has flexibility, and users can specify the path. The robustness of the program has also been improved.
### VAlpha
Semi automatic, cumbersome process, discontinued.
## At Last
If you have any good ideas, you are welcome to propose or submit changes directly.