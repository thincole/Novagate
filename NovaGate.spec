# -*- mode: python ; coding: utf-8 -*-
from PyInstaller.utils.hooks import collect_all

datas = [('shopeevideo.py', '.'), ('novagate_icon.ico', '.'), ('novagate_logo.png', '.')]
binaries = []
hiddenimports = ['customtkinter', 'PIL', 'edge_tts', 'google.genai', 'groq']
tmp_ret = collect_all('customtkinter')
datas += tmp_ret[0]; binaries += tmp_ret[1]; hiddenimports += tmp_ret[2]

a = Analysis(
    ['novagate_app.py'],
    pathex=[],
    binaries=binaries,
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=['rthook_mode_novagate.py'],
    excludes=['torch', 'torchvision', 'tensorflow', 'onnxruntime', 'scipy', 'pandas', 'numpy', 'cv2',
              'matplotlib', 'sqlalchemy', 'psycopg2', 'lxml', 'av', 'google.generativeai', 'pystray'],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='NovaGate',
    icon='novagate_icon.ico',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='NovaGate',
)
