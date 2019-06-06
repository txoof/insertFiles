# insertFiles
Insert multiple PDF into cumulative student folders on a google Shared drive (formerly Team Drive)

insertFiles.app accepts one or more PDF files that contain a PowerSchool student number; the supplied files are copied into the student portfolio folders and are prepended with the current school year. The supplied file `SRP_DoeJohn_023451.pdf` is will be inserted into John Doe's portfolio folder with the name `SY2018-2019_SRP_DoeJohn_023451.pdf`.


Any files that failed to copy will be listed.

## Installation and Configuration Requirements
* Google Filestream
  * Filestream is signed in with an account with editing rights to the Student Cumulative folders Shared Drive
* This script or the associated Platypus application

## Use
This application expects one or more PDFs that contain the student number. File names can be in any configuration, but must ONLY contain the student number once:

**Valid Filename Formats**
* `SPR_DoeJohn_324566.pdf`
* `ISA_Autumn-345566-Doe Jon.pdf`
* `555457 John Doe.pdf`
* `334577.pdf`

**Invalid Filename Formats**
* `20182019_ISA Test Results_443556.pdf` ↢ Too many numbers
* `John Doe.pdf` ↢ No student number
* `222334 John Doe.doc` ↢ Not a pdf

### GUI - Drag and Drop
1. Open the insertFiles.app application 
    - it may be required to right click on the application and choose "Open" if OS X identifies the application as coming from an unidentified developer
2. Drag one or more PDFs onto the application window
3. Note any failed files and manually insert them (listed at the end)

## Command Line
$ insertFiles.zsh File1_555663.pdf File2_334567.pdf FileN_223416.pdf
