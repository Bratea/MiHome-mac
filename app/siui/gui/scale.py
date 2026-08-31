import ctypes
import os
import sys


def get_windows_scaling_factor():
    if sys.platform != "win32":
        return 1.0
    try:
        # 调用 Windows API 函数获取缩放比例
        user32 = ctypes.windll.user32
        user32.SetProcessDPIAware()
        scaling_factor = user32.GetDpiForSystem()

        # 计算缩放比例
        return scaling_factor / 96.0

    except Exception as e:
        print("无法获取缩放比例，设置为1，错误:", e)
        return 1


def reload_scale_factor():
    # Qt 在 macOS 上自行处理 Retina 与系统缩放；不覆写环境变量。
    if sys.platform != "win32":
        return
    set_scale_factor(get_windows_scaling_factor(), identity="Windows API")


def set_scale_factor(factor, identity="External calls"):
    os.environ["QT_SCALE_FACTOR"] = str(factor)
    print("已将环境变量 QT_SCALE_FACTOR 设为", factor, f" (来源: {identity})")
