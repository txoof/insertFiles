from pathlib import Path

VERSION = '1.1.1-devel-2020.08.31'
APP_NAME = 'insert_files'
DEVEL_NAME = 'com.txoof'
APP_DESC = '''insert individual student files into cumulative folders'''
URL = 'https://github.com/txoof/'
CONTACT = 'aaron.ciuffo@gmail.com'



# use this to avoid relative path hell elsewhere
__root_dir = Path(__file__).absolute().parent


# CONFIG FILES #
################

# base configuration file
CONFIG_FILE = '.'.join((APP_NAME, 'ini'))
CONFIG_DIR = '.'.join((DEVEL_NAME, APP_NAME))
USER_CONFIG_PATH = Path('~/.config').expanduser()/CONFIG_DIR/CONFIG_FILE


# LOGGING #
###########
#FORMAT = '%(asctime)-15s %(module)s F:%(funcName)s - %(levelname)s: %(message)s'
#DATEFMT = '%Y.%m.%d %H:%M.%S'
LOGGING_CONFIG = __root_dir/'logging_cfg.ini'
LOG_FILE = Path('~/'+APP_NAME+'.log').expanduser().absolute()

# GUI #
#######
FONT_FACE = 'Courier'
FONT_SIZE = 14
FONT = f'{FONT_FACE} {FONT_SIZE}'
TEXT_WIDTH = 80
TEXT_ROWS = 40

WIN_LOCATION = (80, 80)

POPUP_LOCATION = (WIN_LOCATION[0], WIN_LOCATION[1]+TEXT_ROWS*FONT_SIZE)

# RUNTIME #
###########
SENTRY_FILE = 'sentryFile_DO_NOT_REMOVE.txt'

STORAGE = Path('~/Library/Application Support/').expanduser()/'.'.join((DEVEL_NAME, APP_NAME))
DATABASE = APP_NAME+'.db'
DATABASE_PATH = STORAGE/DATABASE

# student grade level directories
STUDENT_DIRS = ['Admissions',
                '00-Preschool',
                '00-Transition Kindergarten',
                '00-Kindergarten',
                '01-Grade',
                '02-Grade',
                '03-Grade',
                '04-Grade',
                '05-Grade',
                '06-Grade',
                '07-Grade',
                '08-Grade',
                '09-Grade',
                '10-Grade',
                '11-Grade',
                '12-Grade']

HELP_FILE = 'Help.md'
# DATABASE #
############
INTERVAL = {'minute': 60,
            'hour': 60*60,
            'day': 60*60*24,
            'week': 60*60*24*7,
            'year': 60*60*24*365}

RETIRE_AGE = 4*INTERVAL['week']

TABLES = {'file_list': {
                    'job_id': None,
                    'local_path': None,
                    'remote_path': None,
                    'sub_folder': None,
                    'student_number': None,
                    'failure': None,
                    'failure_function': None,
                    'inserted_timestamp': None,
                    'del_path': None,
                    'deleted': False},

          }

FAILURE_CODES = { 0: 'unknown error',
                  10: 'file contains no student number',
                  11: 'entity is not a file or directory',
                  20: 'multiple folders with the same student number found on Google drive for this student',
                  21: 'no matching folders found on Google drive for this student',
                  22: 'could not copy file -- see logs',
                  23: 'error copying file -- see logs',
                  90: 'error when accessing dictionary values -- see logs',
                  100: None

}

