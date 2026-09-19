import select
import signal
import socket
import struct
import subprocess
import sys
import time

import numpy as np
import st7789

sys.path.insert(0, "/usr/lib/roki")

from roki_display_font import (
    FALLBACK_GLYPH,
    FONT_BITMAPS,
    FONT_HEIGHT,
    FONT_WIDTH,
    UNICODE_TO_GLYPH,
)

# =========================
# Frequently changed display contents.
# Set to False to avoid running "iw dev wlan0 link" and hide the SSID row.
SHOW_WIFI_SSID = True
# Optional static text. Newlines create separate display rows.
CUSTOM_TEXT = ""
CUSTOM_TEXT_SCALE = 1
CUSTOM_TEXT_COLOR = (255, 255, 255)
# =========================

INTERFACES = ("eth0", "wlan0")
TEXT_COLOR = (255, 255, 255)
LINK_UP_COLOR = (30, 150, 45)
LINK_DOWN_COLOR = (185, 35, 35)

RTM_NEWLINK = 16
RTM_DELLINK = 17
RTM_GETLINK = 18
RTM_NEWADDR = 20
RTM_DELADDR = 21
RTM_GETADDR = 22
RTNLGRP_LINK = 1
RTNLGRP_IPV4_IFADDR = 5

NLMSG_NOOP = 1
NLMSG_ERROR = 2
NLMSG_DONE = 3

NLM_F_REQUEST = 0x01
NLM_F_ROOT = 0x100
NLM_F_MATCH = 0x200
NLM_F_DUMP = NLM_F_ROOT | NLM_F_MATCH

IFADDRMSG_LEN = 8
RTATTR_HDR_LEN = 4
NLMSG_HDR_LEN = 16

IFA_ADDRESS = 1
IFA_LOCAL = 2
IFLA_IFNAME = 3
IFLA_OPERSTATE = 16

OPERSTATE_UP = 6
RT_SCOPE_UNIVERSE = 0
IFA_F_SECONDARY = 0x01

SSID_RETRY_ATTEMPTS = 5
SSID_RETRY_INTERVAL = 0.3

# The ST7789 driver imports numpy too, so keep bitmap expansion in RAM once.
FONT_MASKS = np.unpackbits(np.frombuffer(FONT_BITMAPS, dtype=np.uint8)).reshape(
    -1, FONT_HEIGHT, FONT_WIDTH
).astype(bool)


def nlmsg_align(length):
    return (length + 3) & ~3


def parse_rtattrs(payload):
    attrs = {}
    offset = 0
    while offset + RTATTR_HDR_LEN <= len(payload):
        rta_len, rta_type = struct.unpack_from("=HH", payload, offset)
        if rta_len < RTATTR_HDR_LEN:
            break
        data_start = offset + RTATTR_HDR_LEN
        data_end = offset + rta_len
        attrs[rta_type] = payload[data_start:data_end]
        offset += nlmsg_align(rta_len)
    return attrs


class NetlinkSnapshot:
    def __init__(self):
        self.seq = 1
        self.index_to_name = {}
        self.sock = socket.socket(socket.AF_NETLINK, socket.SOCK_RAW, socket.NETLINK_ROUTE)
        self.sock.bind((0, 0))

    def request_dump(self, msg_type):
        seq = self.seq
        self.seq += 1
        header = struct.pack(
            "=IHHII",
            NLMSG_HDR_LEN + 1,
            msg_type,
            NLM_F_REQUEST | NLM_F_DUMP,
            seq,
            0,
        )
        payload = b"\x00"
        self.sock.send(header + payload)
        return seq

    def recv_dump(self, seq):
        messages = []
        while True:
            payload = self.sock.recv(65535)
            offset = 0
            while offset + NLMSG_HDR_LEN <= len(payload):
                msg_len, msg_type, _, msg_seq, _ = struct.unpack_from("=IHHII", payload, offset)
                if msg_len < NLMSG_HDR_LEN:
                    break
                if msg_seq != seq:
                    offset += nlmsg_align(msg_len)
                    continue
                body_start = offset + NLMSG_HDR_LEN
                body_end = offset + msg_len
                body = payload[body_start:body_end]
                if msg_type == NLMSG_DONE:
                    return messages
                if msg_type == NLMSG_ERROR:
                    raise OSError("netlink dump failed")
                messages.append((msg_type, body))
                offset += nlmsg_align(msg_len)

    def get_snapshot(self):
        index_to_name = {}
        states = {}
        seq = self.request_dump(RTM_GETLINK)
        for msg_type, body in self.recv_dump(seq):
            if msg_type != RTM_NEWLINK or len(body) < 16:
                continue
            if_index = struct.unpack_from("=i", body, 4)[0]
            attrs = parse_rtattrs(body[16:])
            name = attrs.get(IFLA_IFNAME, b"").split(b"\x00", 1)[0].decode("ascii", "ignore")
            if name:
                index_to_name[if_index] = name
                raw_state = attrs.get(IFLA_OPERSTATE)
                states[name] = bool(raw_state and raw_state[0] == OPERSTATE_UP)

        address_candidates = {}
        seq = self.request_dump(RTM_GETADDR)
        for msg_type, body in self.recv_dump(seq):
            if msg_type != RTM_NEWADDR or len(body) < IFADDRMSG_LEN:
                continue
            family, prefixlen, flags, scope, if_index = struct.unpack_from("=BBBBI", body, 0)
            if family != socket.AF_INET:
                continue
            attrs = parse_rtattrs(body[IFADDRMSG_LEN:])
            raw = attrs.get(IFA_LOCAL) or attrs.get(IFA_ADDRESS)
            if not raw or len(raw) < 4:
                continue
            name = index_to_name.get(if_index)
            if not name:
                continue
            address_candidates.setdefault(name, []).append(
                (scope, bool(flags & IFA_F_SECONDARY), raw[:4], prefixlen)
            )

        addresses = {}
        for name, candidates in address_candidates.items():
            _, _, raw, prefixlen = min(
                candidates,
                key=lambda candidate: (
                    candidate[0] != RT_SCOPE_UNIVERSE,
                    candidate[1],
                    candidate[2],
                    candidate[3],
                ),
            )
            addresses[name] = f"{socket.inet_ntoa(raw)}/{prefixlen}"
        self.index_to_name = index_to_name
        return {"addresses": addresses, "link_up": states}

    def close(self):
        self.sock.close()


def build_status_items(snapshot):
    addresses = snapshot.get("addresses", {})
    link_up = snapshot.get("link_up", {})
    items = []
    for ifname in INTERFACES:
        up = bool(link_up.get(ifname))
        addr = addresses.get(ifname) or "No IPv4 addr"
        items.append({"ifname": ifname, "addr": addr, "up": up})
    return items


def status_items_key(items):
    return tuple((item["ifname"], item["addr"], item["up"]) for item in items)


def text_fits(text, columns):
    if len(text) <= columns:
        return text
    if columns <= 3:
        return text[:columns]
    return text[: columns - 3] + "..."


def draw_text(
    image,
    x,
    y,
    text,
    foreground=TEXT_COLOR,
    background=None,
    scale=1,
    cell_width=None,
    cell_height=None,
):
    foreground = np.asarray(foreground, dtype=np.uint8)
    background = None if background is None else np.asarray(background, dtype=np.uint8)
    glyph_width = cell_width or FONT_WIDTH * scale
    glyph_height = cell_height or FONT_HEIGHT * scale
    for char in text:
        if x + glyph_width > image.shape[1] or y + glyph_height > image.shape[0]:
            break
        glyph = UNICODE_TO_GLYPH.get(ord(char), FALLBACK_GLYPH)
        mask = FONT_MASKS[glyph]
        if glyph_width != FONT_WIDTH or glyph_height != FONT_HEIGHT:
            source_y = np.arange(glyph_height) * FONT_HEIGHT // glyph_height
            source_x = np.arange(glyph_width) * FONT_WIDTH // glyph_width
            mask = mask[source_y[:, np.newaxis], source_x]
        elif scale != 1:
            mask = np.repeat(np.repeat(mask, scale, axis=0), scale, axis=1)
        pixels = image[y : y + glyph_height, x : x + glyph_width]
        if background is not None:
            pixels[:] = background
        pixels[mask] = foreground
        x += glyph_width
    return x


def read_wifi_ssid():
    try:
        result = subprocess.run(
            ("iw", "dev", "wlan0", "link"),
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=1,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None

    for line in result.stdout.splitlines():
        if line.startswith("\tSSID: ") or line.startswith("SSID: "):
            return line.split(": ", 1)[1]
    return None


class DisplayReady:
    def __init__(self):
        self.disp = st7789.ST7789(
            height=240,
            rotation=90,
            port=0,
            cs=st7789.BG_SPI_CS_BACK,
            dc="userspace-lcd-dc",
            backlight="userspace-lcd-backlight",
            rst="userspace-lcd-reset",
            spi_speed_hz=80 * 1000 * 1000,
            offset_left=0,
            offset_top=0,
        )
        self.disp.begin()

        self.status_key = None
        self.snapshot = NetlinkSnapshot()
        self.event_netlink = None
        self.status_items = []
        self.ssid = None
        self.ssid_retry_remaining = 0
        self.ssid_retry_deadline = None
        self.closed = False

    def render(self):
        key = (status_items_key(self.status_items), self.ssid, CUSTOM_TEXT)
        if key == self.status_key:
            return
        self.status_key = key
        image = np.zeros((240, 240, 3), dtype=np.uint8)

        y = 8
        for line in CUSTOM_TEXT.splitlines():
            glyph_height = FONT_HEIGHT * CUSTOM_TEXT_SCALE
            if y + glyph_height > 80:
                break
            columns = (240 - 16) // (FONT_WIDTH * CUSTOM_TEXT_SCALE)
            draw_text(
                image,
                8,
                y,
                text_fits(line, columns),
                foreground=CUSTOM_TEXT_COLOR,
                scale=CUSTOM_TEXT_SCALE,
            )
            y += glyph_height + 8

        for item in self.status_items:
            color = LINK_UP_COLOR if item["up"] else LINK_DOWN_COLOR
            draw_text(image, 8, y, item["ifname"].upper(), background=color, scale=2)
            y += 32
            draw_text(
                image,
                8,
                y,
                text_fits(item["addr"], (240 - 16) // 12),
                cell_width=12,
                cell_height=24,
            )
            y += 32

        if SHOW_WIFI_SSID and y + FONT_HEIGHT <= 240:
            draw_text(image, 8, y, "SSID: ")
            draw_text(image, 56, y, text_fits(self.ssid or "not connected", 23))

        self.disp.display(image)
        status_line = " ".join(
            f'{item["ifname"]}:{"up" if item["up"] else "down"}:{item["addr"]}'
            for item in self.status_items
        )
        print(f"roki-display: {status_line} ssid={self.ssid!r}", flush=True)

    def wlan_link_up(self):
        return any(item["ifname"] == "wlan0" and item["up"] for item in self.status_items)

    def schedule_ssid_retry(self):
        self.ssid_retry_remaining = SSID_RETRY_ATTEMPTS
        self.ssid_retry_deadline = time.monotonic() + SSID_RETRY_INTERVAL

    def refresh_ssid(self, retry=False):
        self.ssid = read_wifi_ssid()
        if self.ssid is not None or not self.wlan_link_up():
            self.ssid_retry_remaining = 0
            self.ssid_retry_deadline = None
        elif retry and self.ssid_retry_remaining > 0:
            self.ssid_retry_remaining -= 1
            self.ssid_retry_deadline = (
                time.monotonic() + SSID_RETRY_INTERVAL if self.ssid_retry_remaining else None
            )
        else:
            self.schedule_ssid_retry()
        self.render()

    def refresh_network(self, refresh_ssid=True):
        self.status_items = build_status_items(self.snapshot.get_snapshot())
        if SHOW_WIFI_SSID and refresh_ssid:
            self.refresh_ssid()
        else:
            self.render()

    def open_event_netlink(self):
        sock = socket.socket(socket.AF_NETLINK, socket.SOCK_RAW, socket.NETLINK_ROUTE)
        groups = (1 << (RTNLGRP_LINK - 1)) | (1 << (RTNLGRP_IPV4_IFADDR - 1))
        sock.bind((0, groups))
        return sock

    def close(self):
        if self.closed:
            return
        self.closed = True

        def cleanup(action):
            try:
                action()
            except Exception as error:
                print(f"roki-display: cleanup failed: {error}", file=sys.stderr, flush=True)

        if self.event_netlink is not None:
            cleanup(self.event_netlink.close)
            self.event_netlink = None
        cleanup(self.snapshot.close)

        # Restore the bootloader's safe LCD state before GPIO ownership ends.
        cleanup(lambda: self.disp.command(st7789.ST7789_DISPOFF))
        cleanup(lambda: self.disp.set_backlight(False))
        cleanup(lambda: self.disp.set_pin(self.disp._dc, False))
        cleanup(lambda: self.disp.set_pin(self.disp._rst, False))

    def event_refresh_flags(self, payload):
        refresh_network = False
        refresh_ssid = False
        offset = 0
        while offset + NLMSG_HDR_LEN <= len(payload):
            msg_len, msg_type, _, _, _ = struct.unpack_from("=IHHII", payload, offset)
            if msg_len < NLMSG_HDR_LEN:
                break
            body_start = offset + NLMSG_HDR_LEN
            body_end = offset + msg_len
            body = payload[body_start:body_end]
            ifname = None
            if msg_type in (RTM_NEWLINK, RTM_DELLINK) and len(body) >= 16:
                if_index = struct.unpack_from("=i", body, 4)[0]
                attrs = parse_rtattrs(body[16:])
                ifname = attrs.get(IFLA_IFNAME, b"").split(b"\x00", 1)[0].decode("ascii", "ignore")
                if ifname:
                    self.snapshot.index_to_name[if_index] = ifname
            elif msg_type in (RTM_NEWADDR, RTM_DELADDR) and len(body) >= IFADDRMSG_LEN:
                if_index = struct.unpack_from("=I", body, 4)[0]
                ifname = self.snapshot.index_to_name.get(if_index)

            if ifname in INTERFACES:
                refresh_network = True
                refresh_ssid |= ifname == "wlan0"
            offset += nlmsg_align(msg_len)
        return refresh_network, refresh_ssid

    def run(self):
        self.event_netlink = self.open_event_netlink()
        self.refresh_network()
        try:
            while True:
                timeout = None
                if self.ssid_retry_deadline is not None:
                    timeout = max(0, self.ssid_retry_deadline - time.monotonic())
                readable, _, _ = select.select([self.event_netlink], [], [], timeout)
                if self.event_netlink in readable:
                    payload = self.event_netlink.recv(65535)
                    refresh_network, refresh_ssid = self.event_refresh_flags(payload)
                    if refresh_network:
                        self.refresh_network(refresh_ssid=refresh_ssid)
                if (
                    self.ssid_retry_deadline is not None
                    and time.monotonic() >= self.ssid_retry_deadline
                ):
                    self.refresh_ssid(retry=True)
        finally:
            if self.event_netlink is not None:
                self.event_netlink.close()
                self.event_netlink = None


def terminate(_signum, _frame):
    raise SystemExit(0)


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, terminate)
    signal.signal(signal.SIGINT, terminate)

    display = None
    try:
        display = DisplayReady()
        display.run()
    finally:
        if display is not None:
            display.close()
