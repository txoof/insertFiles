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
### Problem:
Recieve the following message:
`FATAL ERROR
Sentry file is missing from ASH Student Cumulative Folders`

There is a file that exists in the Shared drive (formerly team drive) called "`sentryFile_DO_NOT_REMOVE.txt`" The program will not opperate if the file is missing. 

### Solutions
1.  Check that Google File Stream is running 
