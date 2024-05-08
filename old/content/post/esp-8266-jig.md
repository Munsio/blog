---
date: 2018-02-19 13:12:53 +0200
title: A small "fast flash" jig for the esp-8266
description: A small tutorial on how to build an esp-8266 flash jig
tags:
- esp-8266
- tutorial
categories:
- electronics

---
After receiving my esp-8266 modules and the corresponding adapter PCBs to use the chips with my breadboard the idea of soldering and desoldering it for the initial flash seems a bit tedious to me so i decided to make a "fast flash board" or "jig" to get the latest version of mongooseOS on it before using it in my projects.

![](/uploads/2018/06/08/esp8266-jig-finished-jig.jpg)

In the end I'm very happy with the outcome and after a few initial problems (with mongooseOS) the reliability is better than expected. If you want to build it by yourself it is even for a newcomer to electronics like me an easy task to solder it all together.

### Parts:

* [esp-8266 adapter pcb](https://www.aliexpress.com/item/1pcs-ESP8266-serial-WIFI-module-adapter-plate-Applies-to-ESP-07-ESP-08-ESP-12E/32721304582.html)
* [2mm single row female+male pin header](https://www.aliexpress.com/item/20PCS-Lot-1x40-Pin-2-mm-Single-Row-Female-Male-Pin-Header-connector/32691922480.html)
* [esp-8266 12E/F module](https://www.aliexpress.com/item/2015-New-version-1PCS-ESP-12F-ESP-12E-upgrade-ESP8266-remote-serial-Port-WIFI-wireless-module/32521015580.html)

### Tools:

* Soldering iron
* Helping Hand
* Table drill with 2mm drill bit

We start by drilling holes in the inner contacts of the adapter PCB, keep in mind that those holes should be in line, because we need to put male pin headers through it.

![](/uploads/2018/06/08/esp8266-jig-drilling-holes.jpg)

The next step is to modify some of the pin headers by moving the plastic down to the end.

With that we are now able to solder those pin headers to the PCB and use the female pin header on top of it. These are the parts where the ESP gets clamped into.

![](/uploads/2018/06/08/esp8266-jig-pin-headers-female.jpg)

The last step is to solder the pin headers shipped with the PCB to the outside facing down.

![](/uploads/2018/06/08/esp8266-jig-outer-pin-headers.jpg)

In the end we use the arduino IDE and the blink example to verify that the chip is able to flash. Keep in mind that the pin of the connected LED could change. It may vary due to a different layout at the board you are using. It also may change if you are using an other esp-8266 board.