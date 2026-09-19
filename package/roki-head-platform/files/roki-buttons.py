import os
import subprocess
import sys
import time
from evdev import InputDevice, ecodes, list_devices


DEVICE_SYMLINK = "/dev/input/roki-head-buttons"
DEVICE_NAME = "roki-head-buttons"
RESET_ANNOUNCE_SECONDS = 2.0
POWEROFF_SECONDS = 3.5
POLL_SECONDS = 0.05


class ResetButtonService:
    def __init__(self):
        self.press_started_at = None
        self.reboot_announced = False
        self.poweroff_announced = False

    def find_device(self):
        if os.path.exists(DEVICE_SYMLINK):
            return DEVICE_SYMLINK
        for path in list_devices():
            dev = InputDevice(path)
            if dev.name == DEVICE_NAME:
                return path
        raise FileNotFoundError(f"input device {DEVICE_NAME!r} not found")

    def say(self, text):
        try:
            subprocess.Popen(
                ["/usr/bin/espeak", "-ven-m1", "-a50", text],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except OSError:
            print(f"roki-buttons: espeak unavailable, message: {text}", flush=True)

    def on_press(self):
        self.press_started_at = time.monotonic()
        self.reboot_announced = False
        self.poweroff_announced = False

    def on_release(self):
        if self.press_started_at is None:
            return
        duration = time.monotonic() - self.press_started_at
        self.press_started_at = None

        if duration >= POWEROFF_SECONDS:
            print(f"BTN_RST {duration:.2f}s -> poweroff", flush=True)
            os.execl("/usr/sbin/shutdown", "shutdown")
        if duration >= RESET_ANNOUNCE_SECONDS:
            print(f"BTN_RST {duration:.2f}s -> reboot", flush=True)
            os.execl("/usr/sbin/reboot", "reboot")

    def poll_hold(self):
        if self.press_started_at is None:
            return
        duration = time.monotonic() - self.press_started_at
        if duration >= RESET_ANNOUNCE_SECONDS and not self.reboot_announced:
            self.reboot_announced = True
            self.say("Reset")
        if duration >= POWEROFF_SECONDS and not self.poweroff_announced:
            self.poweroff_announced = True
            self.say("Shut down")

    def run(self):
        while True:
            try:
                device_path = self.find_device()
                print(f"roki-buttons: using {device_path}", flush=True)
                dev = InputDevice(device_path)
                while True:
                    event = dev.read_one()
                    if event is None:
                        self.poll_hold()
                        time.sleep(POLL_SECONDS)
                        continue
                    if event.type != ecodes.EV_KEY:
                        continue
                    if event.code != ecodes.KEY_POWER:
                        continue
                    if event.value == 1:
                        self.on_press()
                    elif event.value == 0:
                        self.on_release()
            except FileNotFoundError as exc:
                print(f"roki-buttons: {exc}", flush=True)
                time.sleep(1.0)
            except OSError as exc:
                print(f"roki-buttons: device error: {exc}", flush=True)
                time.sleep(1.0)


def main():
    try:
        ResetButtonService().run()
    except KeyboardInterrupt:
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
