# insert_files
This program inserts files located on your computer into student Cumulative Folders on google drive using Google Filestream. insert_files can be used by any ASH employee that has write access to the `Student Cumulative Folders` shared drive.

This is useful for inserting report cards, Admissions documentation or test results into student folders. Each file must have a valid PowerSchool student number in the file name or the folder that contains multiple files.

Files are inserted into one of the following sub folders within each student's cumulative folder. All of the files in a selected folder will be inserted into the SAME grade level folder.
* Admissions
* 00-Preschool
* 00-Transition Kindergarten
* 00-Kindergarten
* 01-Grade
* 02-Grade
* 03-Grade
* 04-Grade
* 05-Grade
* 06-Grade
* 07-Grade
* 08-Grade
* 09-Grade
* 10-Grade
* 11-Grade
* 12-Grade


## Running the Program
Make sure you have the latest version fo the program. The latest version can be found on GitHub. See the main application window for the exact URL.

Before you can get started inserting files into Google Drive, you must have Google Filestream installed and must be signed in with an account that has write access to the `Student Cumulative Folders` shared drive.

File stream can be downloaded at https://support.google.com/a/answer/7491144?hl=en. IT Support can assist you with the installation process.

### Preparing Files
Locate a folder on your local computer that contains several files such as report cards or MAP test results. Each file must have the student number in the file name. Any six-digit number in the filename will be treated as if it were a student number. Please make sure file names do not include multiple six-digit numbers.
Examples:

OK:

* Washington, George 453256.pdf
* van Oranje, Willem-338125-2020 Map Results.pdf
* Fields, Sally - work sample Grade 2 247152.pdf
* 998541_Terry_Pratchet-08-09-2018_Results.txt
* Peter Buck - class photo 192364.png
* Peter_Buck-folder-192364
    
NOT OK:

* Washington, George.pdf
    * No student number
* van Oranje, Willem-338125-190801 Map Results.pdf
    * Two possible student numbers
* Fields, Sally - work sample Grade 2 24715.pdf
    * Student number is only 5 digits

### Inserting Files
Click the "Insert Files" folder and follow the instructions.

Use the "Browse" button to locate a folder full of files that will be inserted into one grade-year folder. Then choose which grade-level folder those files will be inserted into. This is **VERY** difficult to undo. Please act with care.

insert_files will attempt to find the appropriate folders and insert each file into the correct sub folder. When it is complete, insert_files will generate a report indicating files that were inserted and those which could not be inserted.

In general, it is best to manually handle any files that had issues. Re-running the same batch of files is possible, but not advisable as it can lead to duplicate files in the folders.

### Deleting Files
If a batch of files was inserted into the wrong grade level folder in error, or should not have been distributed, it is possible to delete some files. insert_files keeps a limited record of files that were inserted within the last 28 calendar days. insert_files can attempt to delete these files. If the files have been moved, renamed, or otherwise altered, insert_files will fail to remove them. 

It is best to delete files as soon as an error is detected. After 28 calendar days, files must be remove manually by locating them in Google Drive and deleting them one-by-one.

Any files removed by insert files are **VERY** difficult to un-delete; these files must be restored using the Google Drive undelete features. You have exactly 28 calendar days to restore a deleted file before it is removed forever.

## Getting More Help
Check the GitHub Repository for more detailed instructions with tutorials, images and detailed contact information -- see the title bar above in this applicaiton for the exact URL. 


```python

```
