# insertFiles
Distribute multiple files into appropriate cumulative student folders on a google Shared drive (formerly Team Drive)

insertFiles.app accepts one or more files that contain a PowerSchool student number; the supplied files are copied into the student portfolio folders and are prepended with the current school year. The supplied file `SRP_DoeJohn_023451.pdf` is will be inserted into John Doe's portfolio folder with the name `SY2018-2019_SRP_DoeJohn_023451.pdf`.


Any files that failed to copy will be listed.

## Installation and Configuration Requirements
* Google Filestream
  * Filestream is signed in with an account with editing rights to the Student Cumulative folders Shared Drive
* This script or the associated Platypus application

## Use
This application expects one or more files that contain the student number. File names can be in any configuration, but **must ONLY contain the student number once**. 

**Valid Filename Formats**
* `SPR_DoeJohn_324566.pdf` 
* `ISA_Autumn-345566-Doe Jon.pdf`
* `555457 John Doe.PDF`
* `334577.doc`

**Invalid Filename Formats**
* `20182019_ISA Test Results_443556.pdf` ↢ Too many numbers
* `John Doe.pdf` ↢ No student number

### GUI - Drag and Drop
1. Open the insertFiles.app application 
    - it may be required to right click on the application and choose "Open" if OS X identifies the application as coming from an unidentified developer
2. Drag one or more files onto the application window
3. Note any failed files and manually insert them (listed at the end)

## Command Line
`insertFiles.zsh [--GradeLevel (optional)] /Folder/With/Files/*.foo`

### Valid GradeLevel options:
* --ps (preschool)
* --tk (transition kindergarden)
* --kg (kindergarten)
* --1 (grade 1)..--12 (grade 12)

### Examples
*  Insert files into the root folder of each student - this is usefulf for MAP tests
   -  `$ insertFiles.zsh File1_555663.pdf File2_334567.pdf FileN_223416.pdf`
   -  This command will add File1_555663 into the Shared Drive (formerly Team Drive) ASH Student Cumulative Folders/Student Cumlative Folders (AKA Student Portfolios)/Class of 2099/Washington, George - 555663/
* Insert files into a GRADE level folder
   -  `$ insertFiles.zsh --4 ~/Downloads/grade 4 Report Cards/*.pdf`
   -  This command will add each individual report card stored in the Downloads/grade 4 Report Cards/ folder into the folder ASH Student Cumulative Folders/Student Cumlative Folders (AKA Student Portfolios)/Class of 2099/Washington, George - 555663/04-Grade
   
## Trouble Shooting
### Problem: Recieve the following message
`FATAL ERROR
Sentry file is missing from ASH Student Cumulative Folders`

There is a file that exists in the Shared drive (formerly team drive) called "`sentryFile_DO_NOT_REMOVE.txt`" The program will not opperate if the file is missing. 

### Solutions
#### Check that Filestream is running
1.  Look for the FileStream icon in the menu bar at the top of the screen ![FileStream Icon](Resources/filestream_icon.png)
2.  If the icon does not appear, use finder to locate the FileStream application and launch it 

#### Check that you are signed in
1.  Click on the FileStream icon and check that you are signed in with an account that can access the appropriate Shared Drive
![FileStream Signed In](Resources/filestream_signedin.png)

#### Check that the Sentry File Exists
1.  Browse to the Shared Drive on google Drive and check if the file "`sentryFile_DO_NOT_REMOVE.txt`" is located in the root of the Shared Drive.
2.  If the file is missing or does not have the proper name, recreate it using the following command from a Terminal prompt:
   * touch "/Volumes/GoogleDrive/Shared drives//ASH Student Cumulative Folders/sentryFile_DO_NOT_REMOVE.txt"
   
#### Check if the Shared Drive name changed
1.  The program expects the Shared Drive to be named exactly "ASH Student Cumulative Folders". 
2.  Either update The program or the shared drive name to fix this.


### Problem recieve the following message:
```
insertFiles inserts multiple test files into a Google Shared drive
folder based on student numbers

command line usage:
insertFiles [--<grade sub-folder>] StudentID-File1 FileN-StudentID
insertFiles [--<grade sub-folder>] /path/to/files/.*

Grade Sub Folders: --ps, --tk, --kg, --1..--12
```
### Solutions:
#### Supply files for the program to work with:
1.  Make sure you are supplying a folder of files for the program to work with. Try typing or pasting the following command
   *  `./insertFiles.zsh ~/D`
2.  Then press the TAB key (⇥) twice to show all of the possible folders that start with "D":
```
$ ./insertFiles.zsh ~/D
Desktop/   Documents/ Downloads/
```
3.  Type a few more characters and press the TAB key again to complete the line. 
4.  Repeat steps 2 and 3 until you have the right folder.
5.  Add `*.pdf` at the end of the line to select all (\* = ALL) the PDFs in that folder: `./insertFiles.zsh ~/Downloads/grade\ 3 MAP Results/*.pdf`

#### Use valid Grade Level Options:
1.   Make sure you supply a valid grade level folder option FIRST. It must be the first option after the command: `./insertFiles.zsh --3  ~/Downloads/grade\ 3 reports/*.pdf`
2. Valid Grade level options: --ps, --tk, --kg, --1, --2, --3 .. --12

### Problem receive the following message after running program:
```
Could not process the following files - no student number in name:
/Users/aciuffo/Downloads/g3test/foo.pdf
```
### Solution:
1.  One or more of the PDFs do not have valid looking student numbers in the file name. The file "`foo.pdf`" is missing a student number all together. Rename the file to include the student number.

### Problem receive the following message after running program:
```
Could not process following files - students not found on Shared Drive:
/Users/aciuffo/Downloads/g3test/SPR_van KattenBillie_5033479.pdf
```
### Solution
1.  Only students with cumulative/portfolio folders on the Google Shared Drive can be processed. Billie van Katten (SN 5033479) does not have a student folder.
2.  Create a folder for Billie van Katten and try again with the following command: `./insertFiles.zsh /Users/aciuffo/Downloads/g3test/SPR_vanKattenBillie_5033479.pdf`
   * This will only retry the failed file


