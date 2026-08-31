"""macOS 应用退出时后台 QThread 必须先停止的回归测试。"""

import os

os.environ["QT_QPA_PLATFORM"] = "offscreen"

from PySide6.QtCore import QTimer
from PySide6.QtWidgets import QApplication

from app.ui.main_window import MainWindow


app = QApplication([])
window = MainWindow()
app.aboutToQuit.connect(window.shutdown)
QTimer.singleShot(0, app.quit)
assert app.exec() == 0
assert not window._jobs._thread.isRunning()
print("SHUTDOWN REGRESSION PASS")
