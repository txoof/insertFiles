#!/usr/bin/env python
# coding: utf-8


# In[1]:


#get_ipython().run_line_magic('load_ext', 'autoreload')

#get_ipython().run_line_magic('autoreload', '2')
#get_ipython().run_line_magic('reload_ext', 'autoreload')




# In[6]:


#get_ipython().system(' ~/bin/develtools/nbconvert insert_files.ipynb')




# In[8]:


import builtins

# I'm not sure why this is needed, but this resolves a runtime crash when run from the command line
# reassign the builtins.print function to bprint
bprint = builtins.print

try:
    from . import constants
except ImportError:
    import constants

try:
    from . import error_msgs
except ImportError:
    import error_msgs

try:
    from .filestream import GoogleDrivePath, GDStudentPath
except ImportError:
    from filestream import GoogleDrivePath, GDStudentPath
    
import logging
from logging import handlers
from logging import config

logging.config.fileConfig(constants.LOGGING_CONFIG, defaults={'logfile': constants.LOG_FILE} )


import sys
from pathlib import Path
import textwrap
from datetime import datetime
import re
import subprocess
import shlex
import shutil
# trailing slash -- os agnostic
from os import sep
import time




# In[9]:


import PySimpleGUI as sg
import ArgConfigParse
from tinydb import TinyDB, Query
from rich.console import Console
from rich.markdown import Markdown





# In[5]:


# FORMAT = constants.FORMAT
# DATEFMT = constants.DATEFMT
# logging.basicConfig(format=FORMAT, datefmt=DATEFMT,
#                     level=logging.DEBUG)




# In[6]:


def do_exit(e='unknown error in unknown module!', exit_status=99):
    '''handle exits and return exit function with either a soft_exit or hard_exit -
        The returned function can be executed by the calling process when it is ready 
        rather than forcing an exit immediately 
    
        soft_exit prints message and optionally logs message
        hard_exit prints message, logs and calls sys.exit(exit_status)
    
    Args:
        e(`str`): error or message detailing reason for exiting
        exit_status(int): exit value --
            0: soft_exit with no logging -- normal exit with no issues
            1: soft_exit with logging -- exit due to recoverable issue
            >1: hard_exit with logging -- abort execution with sys.exit(exit_status)
            
    Returns:
        function: soft_exit, hard_exit'''
    help_msg = f'try:\n{sys.argv[0]} -h for help'
    def hard_exit():
        print(e)
        sys.exit(exit_status)
        
    def soft_exit():
        print(e)
        return(e)
    
    if exit_status > 1:
        logging.error(f'fatal error:\n\t{e}')
        return(hard_exit)
    
    if exit_status == 1:
        logging.warning(f'exited before completion with code {exit_status}')
        logging.warning(e)
        print(help_msg)
        return(soft_exit)
    
    if exit_status < 1:
        logging.debug(e)
        return(soft_exit)




# In[7]:


def adjust_handler(handler=None, new_level=None):
    '''adjust a logging handler
    
    Args:
        handler(`str`): partial string in handler name - if none, returns list of all handlers attached to root
            '*' adjusts all handlers to new_level
        new_level(`str`): DEBUG, INFO, WARNING, ERROR
    
    Returns:
        `list`: list of handlers and levels currently set'''
    if not handler:
        return(logging.getLogger().handlers)
    
    my_handler = None    
    for index, val in enumerate(logging.getLogger().handlers):
        if handler == '*':
            my_handler = logging.getLogger().handlers[index]
        else:
            if handler in str(val):
                my_handler = logging.getLogger().handlers[index]
        if my_handler:
            logging.info(f'setting {str(my_handler)} to {new_level}')
            my_handler.setLevel(new_level)
        else:
            logging.warning(f'handler: "{handler}" not found')
        
    return logging.getLogger().handlers




# In[8]:


class multi_line_string():
    '''multi-line string object 
    
    each time  multi_line_string.string is set equal to a string, it is added to 
    the existing string with a new line character
    
    Properties:
        string(`str`): string'''

    def __init__(self, s=''):
        self._string = ''
        self.append(s)
    
    def __str__(self):
        return str(self.string)
    
    def __repr__(self):
        return(str(self.string))
    
    @property
    def string(self):
        return self._string
    
    @string.setter
    def string(self, s):
        self._string = s
    
    def append(self, s):
        self._string = self._string + s + '\n'
        
    




# In[9]:


def wrap_print(t='', width=None, supress_print=False):
    '''print a text-wrapped string
    
    Args:
        t(`str`): text to wrap
        width(`int`): characters to wrap -- defaults to constants.TEXT_WIDTH
        
    Returns:
        str'''
    if not width:
        width = constants.TEXT_WIDTH
        
    wrapper = textwrap.TextWrapper(width=width, break_long_words=False, replace_whitespace=False)
    result = '\n'.join([wrapper.fill(line) for line in t.splitlines()])
# this causes a runtime crash; it's unclear why, but is resolved by reassigning bprint = builtins.print 
#     builtins.print(result)
    if not supress_print:
        bprint(result)
    return result




# In[10]:


def parse_cmdargs():
    args = ArgConfigParse.CmdArgs()
    
    args.add_argument('-i', '--insert_source', ignore_none=True, 
                      metavar='/path/to/student/records/',
                      type=str, dest='insert_source', help='Full path to file to be inserted')
    
    args.add_argument('-g', '--google_drive', ignore_none=True, 
                      metavar='/Volumes/GoogleDrive/Shared drives/ASH Cum Folders/folder/',
                      type=str, dest='main__drive_path', help='Full path to Google Drive Shared Drive containing cumulative files')

    args.add_argument('-l', '--log_level', ignore_none=True, metavar='ERROR, WARNING, INFO, DEBUG', 
                      type=str, dest='main__log_level', help='Logging level -- Default: WARNING')
    args.add_argument('-v', '--version', dest='version', action='store_true',
                      default=False, help='Print version number and exit')
    
    args.add_argument('-u', '--update_drive', action='store_true',
                       default=False, dest ='update_drive', help='Update config file with supplyed -g option')
    
    args.add_argument('--more_help', dest='more_help', action='store_true',
                       default=False, help='Print extened help and exit')


    args.parse_args()
    return args.nested_opts_dict
    




# In[11]:


def read_config(files):
    '''parse .ini files 
    
    Args:
        files(`list`): list of `str` containing files in .ini format to parse
    
    Returns:
        `dict`: nested dict of configuration'''
    parser = ArgConfigParse.ConfigFile(config_files=files, ignore_missing=True)
    parser.parse_config()
    
    return parser.config_dict




# In[12]:


def check_drive_path(drive_path=None):
    '''check that path is a valid google drive path and contains the appropriate sentry file
    
    Args:
        drive_path(`str`): path to google drive containg cummulative folders and sentry file
    
    Retruns:
        `tuple` of `bool`, `str`: When true, drive is OK; when false, drive is not valid; str contains errors'''
    # this is super redundant -- checks the following:
    # * is a path
    # * is a google drive path
    # * if sentry file exists
    # this may be a good idea considering how some users have run into many problems with this
    SENTRY_FILE = constants.SENTRY_FILE    
    sentry_file_path = drive_path/Path(SENTRY_FILE)
    drive_ok = True
    msg = None
    
    if not drive_path:
        logging.info('no google drive specified')
        drive_ok = False
        msg = 'No Google Drive specified'
        return drive_ok, msg
    else:
        drive_path = Path(drive_path)
    
    if not drive_path.exists():
        logging.warning(f'specified path "{drive_path}" does not exist')
        drive_ok = False
#         msg = f'The Google Drive "{drive_path}" does not appear to exist on Google Drive'
        msg = error_msgs.PATH_ERROR.format(drive_path=drive_path)
        return drive_ok, msg
    else:
        google_drive = GoogleDrivePath(drive_path)
    
    try:
        google_drive.get_xattr('user.drive.id')
    except ChildProcessError as e:
        logging.warning(f'specified path "{drive_path}" is not a Google Drive path')
#         msg = f'The Google Drive "{drive_path}" does not appear to be a valid google Shared Drive'
        msg = error_msgs.NON_GDRIVE_ERROR.format(drive_path=drive_path)
        drive_ok = False
        return drive_ok, msg

 
    if not sentry_file_path.is_file():
        logging.warning(f'sentry file is missing in specified path "{drive_path}"')
        msg = error_msgs.SENTRY_ERROR.format(drive_path=drive_path, sentry_file=SENTRY_FILE)
        drive_ok = False
        
    
    
    
    return drive_ok, msg




# In[13]:


def print_help():
    logging.debug('getting help')
    console = Console()
    console.options.max_width = constants.TEXT_WIDTH
    try:
        with open(constants.HELP_FILE) as help_file:
            markdown = Markdown(help_file.read())
    except Exception as e:
        logging.error(e)
        return do_exit(f'Error getting help!\n{e}', 1)
    
    console.print(markdown)
    return do_exit(' ', 0)




# In[14]:


def init_db():
    db_file = Path(constants.STORAGE/constants.DATABASE)
    
    if not db_file.parent.exists():
        try:
            db_file.parent.mkdir(parents=True, exist_ok=True)
        except Exception as e:
            logging.error(f'failed to create DB Directory -- fatal error: {e}')
            db = None
    
    
    try:
        db = TinyDB(db_file)
    except Exception as e:
        logging.error(f'failed to open DB File: {e}')
        db = None
        
    
    return db    




# In[15]:


class job_time():
    def __init__(self):
        self.job_id = int(time.time())
        
    def date_time(self, job=None):
        if not job:
            job = self.job_id
        return(time.ctime(job))




# In[16]:


# def window_get_dir():
#     file_list = None
#     glob_path = sg.popup_get_folder('Choose a folder containing files to insert into Google Shared Drive',
#                                    title='Choose a folder',
#                                    initial_folder = '~/',
#                                    keep_on_top=True,
#                                    font=constants.FONT,
#                                    location=constants.POPUP_LOCATION)
    
#     if glob_path:
#         file_list = [f for f in Path(glob_path).glob('*')]
#     else:
#         logging.info('no folder selected by user')
        
    
        
    
    
#     return file_list




# In[17]:


def window_drive_path():
    '''sg window that prompts to pick a google drive folder'''
    drive_path = sg.popup_get_folder('Choose the Google Shared Drive **AND** folder that contains student cumulative folders.', 
                                     title='Select A Shared Drive', 
                                     initial_folder='/Volumes/GoogleDrive/',
                                     keep_on_top=True, font=constants.FONT, 
                                     location=constants.POPUP_LOCATION)
    if drive_path:
        drive_path=Path(drive_path)
        logging.debug(f'user selected: {drive_path}')
    else:
        drive_path = None
        logging.info('no drive path selected by user')
    return drive_path




# In[18]:


def window_get_dir():
    '''sg window that prompts for a folder
    
    Returns:
        (event(`str`), file_list(`list`)): tuple of window read event, list of selected files or None'''
    file_list = None
    layout = [ [sg.Text('Choose a folder containing files to insert into Cumulative Folders',
                        font=f'{constants.FONT_FACE} {constants.FONT_SIZE+2}')],
               [sg.Text(wrap_print(f'{constants.APP_NAME} will insert the selected files into a Cumulative Folders'), font=constants.FONT)],
               [sg.Input(key='-INSERT-', font=constants.FONT), sg.FolderBrowse(font=constants.FONT, target='-INSERT-')],
               [sg.Button('OK', font=constants.FONT), sg.Button('Cancel', font=constants.FONT), ]
             ]
    
    window = sg.Window('Choose a Folder', layout, keep_on_top=True, location=constants.POPUP_LOCATION)
    
    while True:
        event, values = window.read()
        
        if event in (sg.WIN_CLOSED, 'Cancel'):
            event = 'Cancel'
            break
        if event == 'OK':
            break
            
    if values['-INSERT-']:
        file_list = [f for f in Path(values['-INSERT-']).glob('*')]
    
    window.Close()
    return event, file_list
            




# In[19]:


def get_grade_level():
    '''sg window that prompts for a slection from constants.STUDENT_DIRS
    
    Returns:
        `str`: selected list item'''
    grade_level = None
    width = 45
    layout = [ [sg.Text('Choose A Grade Level', font=constants.FONT)],
               [sg.Text(wrap_print(f'{constants.APP_NAME} will insert the chosen files into this grade-level folder for each student', width, True), 
                                  font=f'{constants.FONT_FACE} {constants.FONT_SIZE-2}')],
               [sg.Listbox(values=constants.STUDENT_DIRS, font=constants.FONT, size=(width-15, len(constants.STUDENT_DIRS)), key='-LIST-', enable_events=True)],
               [sg.Button('OK'), sg.Button('Cancel')]
             ]
    window = sg.Window('Choose a Grade Level', layout, keep_on_top=True, location=constants.POPUP_LOCATION)
    
    while True:
        event, values = window.read()
        logging.debug(f'user slected: {values}')
        
        if event in (sg.WIN_CLOSED, 'Cancel'):
            break
        if event == 'OK':
            grade_level = values['-LIST-'][0]
            break
    window.close()
    return event, grade_level




# In[20]:


def list_jobs(show_deleted=False):
    '''return list of jobs stored in database
    Args:
        None
    
    Returns:
        `list` of `dict` [{'Mon Day Year - H:M:S': job_id}]'''
#     try:
#         db = TinyDB(constants.DATABASE_PATH)
#     except (OSError) as e:
#         logging.error(f'failed to open database {constants.DATABASE_PATH}: {e}')
#         return False
    db = init_db()
    
    if not db:
        job_list = []
        logging.warning('failed to read jobs from DB -- See previous errors')
    else:
        job_set = set()
        job_list = {}
        format = "%b %d %Y - %H:%M:%S"
        [job_set.add(i['job_id']) for i in db.search((Query().job_id.exists())  ) ]


        for job_id in job_set:
            job_summary = {}
            date = datetime.fromtimestamp(job_id).strftime(format)
            result = db.search((Query().job_id == job_id) & (Query().deleted == show_deleted))

            location = f"{result[0]['sub_folder']} folder" if not result[0]['sub_folder'] == None else 'No valid files remain'
            title = f'{date}: {len(result)} files --> {location}'
            job_list[title] = job_id
    #     [job_list.update({datetime.fromtimestamp(i).strftime(format) :i}) for i in job_set]

    
    return job_list




# In[21]:


def window_get_past_job():
    '''sg window that prompts user to select previously run job id
    
    Returns:
        event, `int`: job_id from database'''
    
    logging.debug('prompt user to select past job id for deletion')
    job_id = None
    job_list = list_jobs()
    values=sorted(job_list.keys())
    if len(job_list) < 1:
        job_list.append({'No previous jobs found': None})

    width = 50
    for j in job_list:
        if len(j) + 20 > width:
            width = len(j)+20
    height = 10
    layout = [ [sg.Text('Choose A Past Job to Delete', font=constants.FONT)],
               [sg.Text(wrap_print(f'{constants.APP_NAME} will attempt to permenently remove files inserted on a previous job', width, True), 
                                  font=f'{constants.FONT_FACE} {constants.FONT_SIZE-2}')],
               [sg.Text(wrap_print(f'Past jobs are listed by date, number of files inserted and grade-level folder chosen', width, True), 
                                  font=f'{constants.FONT_FACE} {constants.FONT_SIZE-2}')],              
               [sg.Listbox(values=values, font=constants.FONT, size=(width-15, height), key='-LIST-', enable_events=True, )],
               [sg.Button('OK'), sg.Button('Cancel')]
             ]
    window = sg.Window('Choose a Previous Job', layout, keep_on_top=True, location=constants.POPUP_LOCATION)
    
    while True:
        event, values = window.read()
        logging.debug(f'user slected: {values}')
        
        if event in (sg.WIN_CLOSED, 'Cancel'):
            logging.info('user canceled')
            break
        if event == 'OK':
            try:
                job_id = job_list[values['-LIST-'][0]]
            except KeyError as e:
                logging.error(f'error fetching job_id with key: {values["-LIST-"][0]}: {e}')
                job_id = None
            except IndexError:
                logging.info('user did not select a job')
                job_id = None
            break
    window.close()
    return event, job_id




# In[22]:


# def open_db():
#     try:
#         db = TinyDB(constants.DATABASE_PATH)
#     except Exception as e:
#         logging.error(f'error opening database: {constants.DATABASE_PATH}: {e}')
#         db = None
#     return db




# In[11]:


def db_cleanup(retire_age=None):
    '''remove db entries older than retire_age
    
    Args:
        retire_age(`int`): time in seconds 
        
    Returns:
        set(): doc ids deleted'''
    
    logging.debug(f'removing db entries older than {retire_age}')
    db = init_db()
    
    if not db:
        logging.error('could not read database -- see previous errors')
        del_queue = set()
    else:
        if not retire_age:
            retire_age = constants.RETIRE_AGE

        if not isinstance(retire_age, (int, float)):
            raise TypeError 

        del_queue = set()
        now = int(time.time())

        try:
            old_items = db.search(Query().job_id < now - retire_age)
        except (AttributeError ) as e:
            logging.error(f'error opening database: {e}')
            return []


            [del_queue.add(i.doc_id) for i in old_items]


        try:
            db.remove(doc_ids=del_queue)
        except KeyError as e:
            logging.error(f'error removing documents {del_queue}: {e}')
            return []

        logging.info(f'removed {len(del_queue)} db entries')
    return del_queue
    




# In[24]:


def delete_files():
    logging.debug('prompt user to delete files')
    db = init_db()
    if not db:
        return do_exit("Could not open the database of inserted files -- perhaps it does not exist?\nSee the log file for more information", 1)
    
    event, job_id = window_get_past_job()
    
    
    
    if not job_id:
        return do_exit("no files selected", 0)
    
    result = db.search((Query().job_id == job_id) & (Query().failure == None) & (Query().deleted != True))
        
    delete_list = []
    width = 100
    
    for index, i in enumerate(result):
        try:
            del_path = Path(i['remote_path'][0])/i['sub_folder']/Path(i['local_path']).name
            delete_list.append(del_path)
            
            result[index].update({'del_path': str(del_path)})
            
            if len(str(delete_list[-1])) > width:
                width = len(str(delete_list[-1])) + 1
        except (IndexError, KeyError) as e:
            logging.warning(f'error fetching remote_path for deletion: {e}')
            continue
    
    width = 200 if width > 200 else width
    
    if len(delete_list) < 1:
        return do_exit("no files to delete", 0)
    
    s = multi_line_string()
    s.append('DELETE THESE FILES FOREVER?')
    s.append('This is very hard to undo!\n')
    [s.append(str(i)) for i in delete_list]
            
    

    proceed = sg.popup_scrolled(s, title='Delete These Files?', 
                                background_color="red", 
                                yes_no=True,
                                size=(width, 10),
                                font=constants.FONT,
                                keep_on_top=True)
    
    if proceed == "Yes":
        errors = []
        for index, file in enumerate(result):
            del_status = 'unknown error'
            path = Path(file['del_path'])
            try:
                if path.exists():
                    if path.is_file():
                        del_status = path.unlink()
                    elif path.is_dir():
                        del_status = shutil.rmtree(path)
                    else:
                        del_status = 'Unknown file type'
                else:
                    status = 'File does not exist'
            except (FileNotFoundError, OSError) as e:
                status = e
                            
            if del_status != None:
                logging.info(f'error encountered while deleting {path}: {del_status}')
                file.update({'del_status': del_status})
                errors.append(file)
            else:
                logging.debug(f'deleted: {path}')
                file.update({'deleted': True, 'del_status': 'successfully deleted'})
            # update the documents
            result[index] = file
            # update the DB with the results
            db.update(file, doc_ids=[file.doc_id])
            
    deleted = db.search((Query().job_id == job_id) & (Query().deleted == True))
    delete_failed = db.search((Query().job_id == job_id) & (Query().deleted == False))

    ds = multi_line_string()   
    
    ds.append('*****Deletion Summary*****')
    ds.append('The following files were deleted: ')
    [ds.append(Path(i['del_path']).name) for i in deleted]
    ds.append('\nThe following files could not be deleted:')
    [ds.append(f'{Path(i["local_path"]).name}\n reason: file does not exist on google drive--{constants.FAILURE_CODES[i["failure"]]}') for i in delete_failed]
    
    print(ds)
    
    return do_exit('done', 0)




# In[25]:


def table_entry(job_id=None, local_path=None, remote_path=None, sub_folder=None,
                student_number=None, failure=None, failure_function=None, inserted_timestamp=None,
                del_path=None, deleted=False):
    '''build a database entry dictionary with all the required keys'''
    
    return {'job_id': job_id,
            'local_path': local_path,
            'remote_path': local_path,
            'sub_folder': sub_folder,
            'student_number': student_number,
            'failure': failure,
            'failure_function': failure_function,
            'inserted_timestamp': inserted_timestamp,
            'del_path': del_path,
            'deleted': deleted}




# In[26]:


def sort_files(files, job_id=0):
    '''sort list of Path() file objects in to a "good" and "bad" set
        "good" files contain 6 digit substring (likely PowerSchool SIS student number)
        "bad" not files, contain fewer than 6 digit substring, contain multiple 6 digit substring
        
    Args:
        files(`list`): list of Path() objects
    
    Returns:
        (good_files(`dict`), bad_files(`dict`))
    
    '''
    matches = {}
    file_list = []
    
    for each in files:
        if each.is_file() or each.is_dir():
#             matches[each] = re.match('^.*?\D?(\d{6})\D+(\d{6})?.*$', each.name)
            matches[each] = re.match('^.*?\D?(\d{6}).*$', each.name)
        else:
#             file_list.append({'job_id': })
            file_list.append(table_entry(**{'job_id': job_id, 'failure_function': 'sort_files', 
                                           'failure': 11, 'local_path': each}))


    for key, value in matches.items():
        try:
            # there should be only one match that appears to be a student number
            if value.group(1):
                file_list.append(table_entry(**{'job_id': job_id, 
                              'local_path': key, 
                              'student_number': value.group(1)}))

        except Exception:
            file_list.append(table_entry(**{'job_id': job_id,
                          'local_path': key,
                          'failure': 10, # file contains no student number
                          'failure_function': 'sort_files'}))
    return(file_list)




# In[27]:


def cache_dirs(path, depth=2):
    '''use system `find` command to cache directory paths into a list
    
    Args:
        path(`str`): path to cache
        depth(`int`): depth to search
        
    Returns:
        (`list`, `list`): list of directories, any errors from stdout'''
    def byte_to_list(byte): return [l for l in cache.decode('utf-8').split('\n')]
    
    command = shlex.split(f'find "{str(path)}" -maxdepth {depth} -type d')
    process = subprocess.Popen(command, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    cache, errors = process.communicate()
    
    return byte_to_list(cache), byte_to_list(errors)




# In[28]:


def match_dirs(files, cache):
    '''match dictionary of file paths and student id values to directories in cache list
    
        uses sub-string comparison -- if 'student id' substring is in directory string
        add this as a match
    
    Args:
        files(`dict`): dictionary of {Path(): 'Student ID'}
        cache(`list`): list of strings
    
    files items dict keys used here:
        [{'student_number': int         # student number (expected)
          'remote_path': str            # dest path (updated) with remote paths that contain student_number
          }
        ]
    
    
    Returns:
        `dict`: updated files dictionary including key 'remote_path' '''
    
#     matches = {}
#     for file, student_number in files.items():
#         matches[file] = [i for i in cache if student_number in i]
    update = []
    for index, file in enumerate(files):
        if file['student_number']:
            files[index].update({'remote_path': [i for i in cache if file['student_number'] in i]})
        else:
            files[index].update({'remote_path': []})
    return files




# In[29]:


def write_summary(file_list):
    '''create a summary of actions taken
    
    summarize files successfully inserted and failures with reasons for failure
    
    Args:
        file_list(`list` of `dict`)
        
    files item dict keys used here:
        [{'local_path': Path()          # src file (expected)
          'remote_path': str            # dest path (expected)
          'sub_folder': str             # sub folder within remote_path used 
          'failure': int                # integer code from constants.FAILURE_CODES if copy fails
          }
        ]
    
    Returns:
        `multi_line_string` object
    '''
    bad_file = []
    multiple_destination = []
    copy_failed = []
    other = []
    inserted = []
        
    for i in file_list:
        if not i['failure']:
            inserted.append(i)
        else:
            if 20 > i['failure'] >= 10 :

                bad_file.append(i)
            if 30 > i['failure'] >= 20:
                copy_failed.append(i)
                
            if 100 > i['failure'] >= 90:
                other.append(i)
    

    s = multi_line_string()
    s.append('******Summary******')
    if len(inserted) > 0:
        s.append(f'The following files were successfully inserted into student folders:')
        [s.append(f"{i['local_path'].name} ---> {i['remote_path'][0]}/{i['sub_folder']}\n") for i in inserted]
        
    s.append('\n\nEach of the files below were skipped and not inserted:')
    for each in [bad_file, copy_failed, other]:

        
        if len(each) > 0:
            [s.append(f"file: {i['local_path'].name}\n\treason: {constants.FAILURE_CODES[i['failure']]}\n") for i in each]

    return s
                 




# In[30]:


def write_db(file_list):
    '''sanitize and write file_list to tinydb database
    
    values that are not in (str, int, list, float or type(None)) are converted to str representations
    
    Args:
        file_list(`list` of `dict`)
        
    Returns:
        list of records'''
    logging.debug(f'writing DB to {constants.DATABASE_PATH}')
    ## FIXME -- purge entries older than N weeks
    try:
        db = TinyDB(constants.DATABASE_PATH)
    except (OSError) as e:
        logging.error(f'failed to write database {constants.DATABASE_PATH}: {e}')
        return False
    
    cleaned = []
    for file in file_list:
        temp_item = {}
        for key, value in file.items():            
            if isinstance(value, (str, int, list, float, type(None))):
                temp_item.update({key: value})
            else:
                temp_item.update({key: str(value)})
        cleaned.append(temp_item)
    
    
    doc_ids = db.insert_multiple(cleaned)
    return doc_ids

    
    




# In[31]:


def insert_files(files, sub_folder):
    '''copy list of files into `sub_folder`
    
    Args:
        files(`dict`): dictionary of files
        sub_folder(`str`): sub_folder to concatenate to dict item[remote_path]
        
    files item dict keys used here:
        [{'local_path': Path()          # src file (expected)
          'remote_path': str            # dest path (expected)
          'sub_folder': str             # sub folder within remote_path used (updated)
          'failure': int                # integer code from constants.FAILURE_CODES if copy fails (updated as needed)
          'failure_function': str       # `insert_files` if copy failes (updated as needed)
          'inserted_timestamp': float}  # epoch time copy was executed (updated as needed)
         }
        ]
    Returns:
        files(`dict`): updated dictonary of files
        '''
    func_name = 'insert_files'
    for index, file in enumerate(files):
        logging.debug(f'processing file: {file["local_path"]}')
        
        if file['failure']: # skip over failures 
            continue


        if len(file['remote_path']) > 1:
            logging.info(constants.FAILURE_CODES[20])
            files[index].update({'failure': 20,
                                'failure_function': func_name})
            continue

        if len(file['remote_path']) < 1:
            logging.info(constants.FAILURE_CODES[21])
            files[index].update({'failure': 21, 
                                'failure_function': func_name})
            continue


        if len(file['remote_path']) == 1:
            logging.debug(f'copying file to remote path: {file["remote_path"][0]}/{sub_folder}')
            result = False
            dest = Path(file['remote_path'][0])/sub_folder
            try:
                src = Path(file['local_path'])
            except (TypeError, KeyError) as e:
                logging.error(f'error accessing key: "local_path" in files dictionary: {e}')
                files[index].update({'failure': 90,
                                  'failure_function': func_name})
                continue

            if src.is_dir():
                logging.debug(f'source file is directory')
                try:
                    #### FIXME! -- needs to create and copy into directory
                    result = shutil.copytree(src, dest/src.name, dirs_exist_ok=True)
                except Exception as e:
                    logging.error(f'error copying file: {e}')
                    files[index].update({'failure': 22, # exception w
                                      'failure_function': func_name})
                    continue
            else:
                logging.debug(f'source file is single file')
                try:
                    result = shutil.copy(src, dest)
                except Exception as e:
                    logging.error(f'failed to copy file: "{file}": {e}')
                    files[index].update({'failure': 23,
                                        'failure_function': func_name})

        if result:
            file['inserted_timestamp'] = time.time()
            file['sub_folder'] = sub_folder
            files[index].update(file)
        else:
            logging.error(constants.FAILURE_CODES[23])
            files[index].update({'failure': 23,
                               'failure_function': func_name})
#             failed.append(file)
#             failed[-1].update({'failure': 23,
#                                'failure_function': func_name})


    return files




# In[ ]:







# In[1]:


def main_program(interactive=False, window=None, update_config=False):
    logger = logging.getLogger(__name__)
    logging.info('***** run main program *****')
    logging.info(f'interactive: {interactive}')
    
    # rebuild these so the match format of constants.TABLES
#     files_inserted = {}
#     files_failed = {}
#     good_files = {}
#     bad_file = {}
    file_glob = None
    file_list = []
    job_id = job_time()
    
    width = constants.TEXT_WIDTH

    
    if interactive:
        print = wrap_print    
    
    USER_CONFIG_PATH = Path(constants.USER_CONFIG_PATH)
    
    logging.debug(f'checking user config: {USER_CONFIG_PATH}')

    update_user_config = not(USER_CONFIG_PATH.exists())
    
    logging.debug(f'user config will be created: {update_user_config}')
    
    cmd_args_dict = parse_cmdargs()
    cfg_files_dict = read_config([constants.DEFAULT_CONFIG_FILE, USER_CONFIG_PATH])
    
    config = ArgConfigParse.merge_dict(cfg_files_dict, cmd_args_dict)
    
    logging.debug('processing command line options')    
    if config['__cmd_line']['version']:
        logging.debug('display version and exit')
        return do_exit(version_info, 0)
    
    if config['__cmd_line']['more_help'] and not interactive:
        logging.debug('display help and exit')
        print_help()
        return do_exit(' ', 0)
    
    if config['__cmd_line']['update_drive']:
        logging.debug('updating user configuration file with new google drive path')
        update_user_config = True
    
    if not config['main']['drive_path']:
        if interactive:
            logging.debug('prompt user to select shared drive & cum. folder')
            print('No Google Shared Drive has been set yet.')
            print('Locate the proper Google Shared Drive **and** then the `Student Cumulative Folders (AKA Student Portfolios)` folder')
            drive_path_interactive = window_drive_path()
            if not drive_path_interactive:
                return do_exit('Please choose a Google Shared Drive to proceed', 0)
            else:
                config['main']['drive_path'] = drive_path_interactive        
        if not interactive:
            return do_exit(f'Can not run without a Google Shared Drive configured.\ntry:\n{sys.argv[0]} -h for help', 1)


    
    # check that supplied path is indeed a valid cumulative folder path
    logging.debug(f"checking drive path is valid: {config['main']['drive_path']}")
    drive_path = Path(config['main']['drive_path'])
    drive_status = check_drive_path(drive_path)
    
    if window:
        window.Refresh()
    
    if not drive_status[0]:
        if interactive:
            error = sg.popup_error(wrap_print(f'{drive_path} does not appear to be valid! See the main window for more information.', width), 
                                       title='Google Drive Error', 
                                       font=constants.FONT,
                                       keep_on_top=True,
                                       line_width=constants.TEXT_WIDTH,
                                       background_color="Red")

        return do_exit(drive_status[1], 0)
    
    if interactive:
        logging.debug('prompt user for files to insert')
        print('Select a folder containing student files to insert')
        event, file_glob = window_get_dir()
    else:
        # use command line switch 
        # file_list = [f for f in Path(path from command line here).glob('*')]
        pass
    
    logging.debug(f'event: {event}, file_list: {file_glob}')        
    if file_glob == None or len(file_glob) < 1:
        logging.info('no files selected by user')
        return do_exit('Cannot proceed without files to insert', 0)

    # sort files into those with and without student numbers
    logging.debug('sorting files based on filename')
    file_list = sort_files(file_glob, job_id.job_id)
    
    # cache all the student directories 
    logging.debug(f'caching directories in {drive_path}')
    cache, errors = cache_dirs(drive_path)
    
    # check the cache and bail out with some logging!
    logging.error('FIXME! -- need some error catching on cache failures')
    
    # match files w/ student numbers to directories in the cache
    logging.debug('match student ID & files to cached dirs')
    file_list = match_dirs(file_list, cache)
    
    # ask for grade level
    logging.debug('prompt for grade level folder')
    while True:
        event, grade_level = get_grade_level()
        
        if grade_level:
            break
            
        if event == 'Cancel':
            logging.info('user canceled grade level selection')
            return do_exit('Processing of files canceled by user', 0)
        

    logging.debug('confirm chosen grade level folder')
    proceed = sg.PopupOKCancel(wrap_print(f'Files will be inserted into the folder: "{grade_level}" for each student.\nThis is difficult to undo!\n\nProceed?', supress_print=True), 
                               title='Proceed?', 
                               font=constants.FONT,
                               keep_on_top=True,
                               line_width=constants.TEXT_WIDTH,
                               background_color="Red")

    
    if proceed == 'OK':
        file_list = insert_files(file_list, grade_level)
    else:
        logging.info('user canceled')
        return do_exit('Processing of files canceled by user', 0)
    
    
    
    if update_user_config:
        logging.debug('updating user configuration file')
        try:
            logging.info(f'updating user configuration file: {USER_CONFIG_PATH}')
            ArgConfigParse.write(config, USER_CONFIG_PATH, create=True)
        except Exception as e:
            logging.warning(e)
        
    records_written = write_db(file_list)
    logging.debug(f'database records written: {records_written}')
    
    s = write_summary(file_list)
    
    cleaned_records = db_cleanup()
    
    s.append(f'Expired {len(cleaned_records)} old records from database')
    
    print(s.string)
    if interactive:
        window.Refresh()
        sg.popup_scrolled(s, title='Summary', font=constants.FONT, size=(int(constants.TEXT_WIDTH*2), None))
    
    

    
    return do_exit('done', 0)




# In[33]:


def main():
    
    logging.info(f'{constants.APP_NAME} v{constants.VERSION}')
    
    run_gui = False
    if len(sys.argv) <= 1:
        run_gui = True
    
    if '-f' in sys.argv:
        logging.debug('likely running in a jupyter environment')
        run_gui = True
    

    if run_gui:
        logging.debug('running gui')
        TEXT_WIDTH = constants.TEXT_WIDTH
        TEXT_ROWS = constants.TEXT_ROWS
        FONT_FACE = constants.FONT_FACE
        FONT_SIZE = constants.FONT_SIZE
        FONT = constants.FONT
        
        # create a wrapper that matches the text output size
        logging.debug('redefining builtin `print` to use `wrap_print`')
        print = wrap_print     


        def text_fmt(text, *args, **kwargs): return sg.Text(text, *args, **kwargs)
        layout = [ [text_fmt(f'{constants.APP_NAME}', font=f'{FONT_FACE} {FONT_SIZE+2}')],
                   [text_fmt(f'{constants.URL}', font=f'{FONT_FACE} {FONT_SIZE}')],
                   [text_fmt(f'v{constants.VERSION}', font=f'{FONT_FACE} {FONT_SIZE}')],              
                   [text_fmt(f'{constants.APP_DESC}', font=f'{FONT_FACE} {FONT_SIZE}')],
                   [sg.Output(size=(TEXT_WIDTH+15, TEXT_ROWS), font=FONT)],
                   [sg.Button('Insert Files', font=FONT), sg.Button('Remove Files', font=FONT)],
                   [sg.Button('Change Shared Drive', font=FONT)],
                   [sg.Button('Help', font=FONT), sg.Button('Exit', font=FONT)]
                 ]

        window = sg.Window(f'{constants.APP_NAME}', layout=layout, keep_on_top=False,
                           location=constants.WIN_LOCATION)
        
        
        window.finalize()
        window.BringToFront()
        
        print(f'{constants.APP_NAME} adds files into Student Cumulative Folders stored on Google Drive. Each file or folder full of files must contain a valid PowerSchool Student ID')
        print('\nSelect an action by clicking the buttons below.')
        window.Refresh()
        

        while True:
            (event, value) = window.read()

            if event == 'Exit' or event == sg.WIN_CLOSED:
                break
            if event == 'Help':
                print_help()
            if event == 'Insert Files':
                logging.debug(f'sys.argv: {sys.argv}')
                ret_val = main_program(interactive=True, window=window)
                ret_val()
                window.Refresh()
            if event == 'Remove Files':
                ret_val = delete_files()
                ret_val()
            if event == 'Change Shared Drive':
                drive = window_drive_path()
                if drive:
                    print('')
                    print(f'Changed drive to: {drive}')
                    window.Refresh()
                    sys.argv.extend(['-g', str(drive)])
                    sys.argv.append('-u')                        
                logging.debug('run set shared drive here')
            
        window.close()

    else:
        ret_val = main_program()
        ret_val()
    
    logging.debug('done')
        




# In[34]:


# from IPython.core.debugger import set_trace




# In[37]:


if __name__ =='__main__':
    f = main()




# In[ ]:


# adjust_handler(handler='Stream', new_level='DEBUG')


