# Apple Keyboard auto connecting service

The btkbd service auto-connects the wireless Apple Keyboard to Arch Linux.

The keyboard must be paired and trusted before the btkbd service will work:

```
$ bluetoothctl -a
[bluetooth]# power on
[bluetooth]# agent KeyboardOnly
[bluetooth]# default-agent
[bluetooth]# pairable on
[bluetooth]# scan on
[bluetooth]# pair <MAC ADDRESS OF KBD>
[bluetooth]# trust <MAC ADDRESS OF KBD>
[bluetooth]# connect <MAC ADDRESS OF KBD>
[bluetooth]# quit
```

Then run `./install` to set up the service (also flips function keys mode from the
fn+F<num> default).
