---
date: 2018-02-19 13:12:53 +0200
title: An small "fast flash" jig for the esp-8266
description: An small tutorial on how to build an esp-8266 flash jig
tags:
- esp-8266
- tutorial
categories:
- electronics
draft: true

---
After receiving my esp-8266 modules and the corresponding adapter PCBs to use the chips with my breadboard the idea of soldering and desoldering it for the initial flash seems a bit tedious to me so i decided to make a "fast flash board" or "jig" to get the latest version of mongooseOS on it before using it in my projects.

\[image full version\]

In the end i am very happy with the outcome and after a few initial problems (with mongooseOS) the reliability is better than expected. If you want to build it by yourself it is even for a newcomer to electronics like me an easy task to solder it all together.

### Parts:

* [esp-8266 adapter pcb](https://www.aliexpress.com/item/1pcs-ESP8266-serial-WIFI-module-adapter-plate-Applies-to-ESP-07-ESP-08-ESP-12E/32721304582.html)
* [2mm single row female+male pin header](https://www.aliexpress.com/item/20PCS-Lot-1x40-Pin-2-mm-Single-Row-Female-Male-Pin-Header-connector/32691922480.html)
* [esp-8266 12E/F module](https://www.aliexpress.com/item/2015-New-version-1PCS-ESP-12F-ESP-12E-upgrade-ESP8266-remote-serial-Port-WIFI-wireless-module/32521015580.html)

### Tools:

* Soldering iron
* Helping Hand
* Table drill with 2mm drill bit

We start by drilling holes in the inner contacts of the adapter pcb, keep in mind that those holes should be in line cause we need to put male pin headers through it.

\[image pcb with holes\]

The next step is to modify some of the pin headers by moving the plastic down to the end.

\[image pin headers\]

With that we are now able to solder those pin headers to the adapter pcb and use the female pin header on top of it (thats where the esp gets clamped into).

\[image female pin header\]

The last step is to solder the pin headers shipped with the adapter pcb to the outside facing down.

\[image finished jig\]

In the end we use the arduino IDE and the blink example to to verify that the chip is able to flash. Please note that we need to change the pin of the LED cause this pin can change if you use other esp-8266 boards.

\[code - arduino\]

\[video - code upload and blinking LED\]