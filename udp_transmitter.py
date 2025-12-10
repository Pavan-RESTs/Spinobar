import socket
import time
import threading
import tkinter as tk
from tkinter import ttk

PHONE_IP = "10.47.105.4"
PORT = 5000

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

sending = False


def send_loop():
    global sending
    while sending:
        msg = (
            f"f1:{f1_var.get()},"
            f"f2:{f2_var.get()},"
            f"f3:{f3_var.get()},"
            f"f4:{f4_var.get()},"
            f"rf:{rf_var.get()},"
            f"ta:{ta_var.get()},"
            f"bt:{bt_var.get()},"
            f"ws:{ws_var.get()},"
            f"temp:{temp_var.get()}"
        )

        sock.sendto(msg.encode(), (PHONE_IP, PORT))
        status_label.config(text="Sent: " + msg)

        time.sleep(interval_var.get() / 1000)


def start_sending():
    global sending
    if sending:
        return
    sending = True
    threading.Thread(target=send_loop, daemon=True).start()


def stop_sending():
    global sending
    sending = False
    status_label.config(text="Stopped")


def update_preview(*args):
    """Live update preview message."""
    msg = (
        f"f1:{f1_var.get()}, f2:{f2_var.get()}, f3:{f3_var.get()}, "
        f"f4:{f4_var.get()}, rf:{rf_var.get()}, ta:{ta_var.get()}, "
        f"bt:{bt_var.get()}, ws:{ws_var.get()}, temp:{temp_var.get()}"
    )
    preview_label.config(text=msg)


root = tk.Tk()
root.title("Live Sensor GUI Sender")
root.geometry("420x520")


f1_var = tk.IntVar(value=55)
f2_var = tk.IntVar(value=55)
f3_var = tk.IntVar(value=66)
f4_var = tk.IntVar(value=66)
rf_var = tk.IntVar(value=55)
ta_var = tk.IntVar(value=22)
bt_var = tk.IntVar(value=19)
ws_var = tk.IntVar(value=5)
temp_var = tk.IntVar(value=40)
interval_var = tk.IntVar(value=500)

vars_list = [
    ("F1", f1_var),
    ("F2", f2_var),
    ("F3", f3_var),
    ("F4", f4_var),
    ("RF", rf_var),
    ("TA", ta_var),
    ("BT", bt_var),
    ("WS", ws_var),
    ("TEMP", temp_var),
]


for name, var in vars_list:
    frame = ttk.Frame(root)
    frame.pack(fill="x", pady=2)

    ttk.Label(frame, text=name, width=6).pack(side="left")
    scale = ttk.Scale(
        frame,
        from_=0,
        to=255,
        orient="horizontal",
        variable=var,
        command=lambda val: update_preview(),
    )
    scale.pack(side="left", fill="x", expand=True)

    entry = ttk.Entry(frame, width=4, textvariable=var)
    entry.pack(side="right")
    var.trace_add("write", update_preview)


interval_frame = ttk.Frame(root)
interval_frame.pack(pady=10)

ttk.Label(interval_frame, text="Send Interval (ms):").pack(side="left")
ttk.Entry(interval_frame, width=6, textvariable=interval_var).pack(side="left")


ttk.Label(root, text="Preview:", font=("Arial", 10, "bold")).pack()
preview_label = ttk.Label(root, text="", wraplength=380)
preview_label.pack(pady=4)
update_preview()


status_label = ttk.Label(root, text="Stopped", foreground="blue")
status_label.pack(pady=10)


btn_frame = ttk.Frame(root)
btn_frame.pack(pady=10)

ttk.Button(btn_frame, text="Start Sending", command=start_sending).pack(
    side="left", padx=10
)
ttk.Button(btn_frame, text="Stop", command=stop_sending).pack(side="left", padx=10)

root.mainloop()
