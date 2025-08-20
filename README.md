# CS 1.6 - Announcer
A plugin that sends announcement messages to players at a chosen interval.

# Installation
- Just download the plugin and upload the .amxx file to your plugins folder on your server (or you can of course compile the .sma file and then upload the compilated .amxx file to your server).

# Requirements
- AMX Mod X 1.10

# Features
- You can choose whether you want the messages to be sent sequentially or randomly.
- Color support
- You can choose the interval in seconds
- Easy to use

# Config File
Default:
```
; Announcer
; You can use colors:
;
; ^1 = default chat color
; ^3 = team color
; ^4 = green

Interval: 5 // In Seconds
Random: true

Messages:
"^4Welcome to the server!"
"^4[Info]^1 This message uses ^3colors^1."
"Message 3"
```

# Known Issues
After the plugin generates the config file, instead of color codes (^1, ^3, ^4), strange characters appear in the .cfg file. Simply replace these characters with "^1, ^3, or ^4" and everything will work as it should. A fix is in progress.

# Support
If you having any issues please feel free to write your issue to the issue section :) .
