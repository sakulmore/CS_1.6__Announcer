# CS 1.6 - Announcer
A plugin that sends announcement messages to players at a chosen interval.

# Installation
- Just download the plugin and upload the .amxx file to your plugins folder on your server (or you can of course compile the .sma file and then upload the compilated .amxx file to your server).
- Then write the plugin name (with .amxx) to `/cstrike/addons/amxmodx/configs/plugins.ini`.

# Requirements
- AMX Mod X 1.10

# Features
- You can choose whether you want the messages to be sent sequentially or randomly.
- Color support
- You can choose the interval in seconds
- When no player is connected to the server, the messages will not be displayed (optimization).
- Variables (see below)
- In-Game Admin Flag changing
- Easy to use

# Chat Commands
`/ann_menu` = Opens the menu for changing admin flags.

# Console Commands
`ann_reload` = When you modify the .cfg file you don't need to restart the whole server, just enter this command and the .cfg file will automatically reload with the current (new) values.

The command is protected by an Admin Flag. To change the Admin Flag, simply edit the line `#define ANN_RELOAD_FLAG ADMIN_LEVEL_H` in the .sma file.

`ann_menu` = Opens the menu for changing admin flags.

# Config File
Default:
```
; Announcer
; You can use colors (prefixes):
;   *d = default chat color
;   *t = team color
;   *g = green
;
; Dynamic variables:
;   {PLAYERS}    - Current player count
;   {MAXPLAYERS} - Server slots
;   {MAP}        - Current map name
;   {TIME}       - Current server time
;   {IMPO}       - Plays an alert sound
;   {MVP}        - Message visible only to admins
;
; Escape asterisk with backslash to print it literally: \\*

Interval: 120
Random: false

Messages:
"*g[INFO]*d Now playing *t{PLAYERS} / {MAXPLAYERS}*d on map *g{MAP}*d."
"{IMPO}*g[IMPORTANT]*d This message played alert sound!"
"{MVP}*t[VIP]*d World-Time is *g{TIME}*d. Enjoy your game!"
```
- After installing the plugin on the server, a new .cfg file `announcer.cfg` will be created in the `/cstrike/addons/amxmodx/data` folder.

# Variables
```
{PLAYERS} - Displays the current number of players on the server.
{MAXPLAYERS} - Shows the maximum number of players (slots) on the server.
{MAP} - Shows the currently played map.
{IMPO} - Plays a sound when the message is displayed.
{MVP} - The message will only be displayed to players with the appropriate admin flag.
```

# Video Showcase
https://youtu.be/nnMBCE5T-DQ

# Support
If you having any issues please feel free to write your issue to the issue section :) .
