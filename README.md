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
; You can use colors (prefixes):
;   *d = default chat color
;   *t = team color
;   *g = green
;
; Escape asterisk with backslash to print it literally: \*

Interval: 120
Random: false

Messages:
"*g[MY-WEBSITE]*d Visit our *twebsite*d!"
"This prints a literal asterisk: \* star"
"*gWelcome*d to *tserver*d!"
```

# Known Issues
After the plugin generates the config file, instead of color codes (^1, ^3, ^4), strange characters appear in the .cfg file. Simply replace these characters with "^1, ^3, or ^4" and everything will work as it should. A fix is in progress.

# Support
If you having any issues please feel free to write your issue to the issue section :) .
