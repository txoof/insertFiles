from pathlib import Path

VERSION = '1.0.0-devel-2020.08.11'
APP_NAME = 'insert_files'
DEVEL_NAME = 'com.txoof'
APP_DESC = '''insert individual student files into cumulative folders'''
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
FORMAT = '%(asctime)-15s %(module)s F:%(funcName)s - %(levelname)s: %(message)s'
DATEFMT = '%Y.%m.%d %H:%M.%S'

# GUI #
#######
FONT_FACE = 'Courier'
FONT_SIZE = 14
FONT = f'{FONT_FACE} {FONT_SIZE}'
TEXT_WIDTH = 65
TEXT_ROWS = 40

WIN_LOCATION = (80, 80)

POPUP_LOCATION = (WIN_LOCATION[0], WIN_LOCATION[1]+TEXT_ROWS*FONT_SIZE)

# RUNTIME #
###########
SENTRY_FILE = 'sentryFile_DO_NOT_REMOVE.txt'

