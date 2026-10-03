# PyInstaller runtime hook: chạy trước seedvis_app.py trong bản exe NovaGate.exe
# → khóa app ở chế độ chỉ dùng NovaGateway (google/flow-veo).
import os
os.environ["SEEDVIS_APP_MODE"] = "nova"
