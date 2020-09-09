# -*- mode: python ; coding: utf-8 -*-

block_cipher = None


a = Analysis(['insert_files.py'],
             pathex=['/Users/aciuffo/Documents/src/insertFiles/insert_files'],
             binaries=[],
             datas=[('insert_files.ini', '.'), ('logging_cfg.ini', '.'), ('Help.md', '.')],
             hiddenimports=[],
             hookspath=[],
             runtime_hooks=[],
             excludes=['IPython'],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher,
             noarchive=False)
pyz = PYZ(a.pure, a.zipped_data,
             cipher=block_cipher)
exe = EXE(pyz,
          a.scripts,
          a.binaries,
          a.zipfiles,
          a.datas,
          [],
          name='insert_files',
          debug=False,
          bootloader_ignore_signals=False,
          strip=False,
          upx=True,
          upx_exclude=[],
          runtime_tmpdir=None,
          console=True )
