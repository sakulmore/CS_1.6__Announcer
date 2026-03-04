#include <amxmodx>
#include <amxmisc>

#define PLUGIN_NAME    "Announcer"
#define PLUGIN_VERSION "1.5"
#define PLUGIN_AUTHOR  "sakulmore"

#define TASK_ANNOUNCER   50011
#define MIN_INTERVAL_SEC 5
#define MAX_MSG_LEN      191

#define IMPO_SOUND "announcer/blip1.wav"

new g_iFlagReload = ADMIN_LEVEL_H;
new g_iFlagMVP = ADMIN_LEVEL_H;

new g_szCfgPath[256];
new g_szFlagsCfgPath[256];
new g_iInterval = 120;
new bool:g_bRandom = false;

new Array:g_aMsgs;
new g_iMsgIndex = 0;
new g_iLastRandom = -1;

new g_msgSayText;
new bool:g_bReloading = false;

new g_iMenuTarget[33];

new const g_szFlagNames[][] = {
    "a (Immunity)", "b (Reservation)", "c (Kick)", "d (Ban)", "e (Slay)",
    "f (Map)", "g (Cvar)", "h (Cfg)", "i (Chat)", "j (Vote)",
    "k (Password)", "l (Rcon)", "m (Level A)", "n (Level B)", "o (Level C)",
    "p (Level D)", "q (Level E)", "r (Level F)", "s (Level G)", "t (Level H)",
    "u (Menu)", "z (User)"
};

new const g_iFlagValues[] = {
    ADMIN_IMMUNITY, ADMIN_RESERVATION, ADMIN_KICK, ADMIN_BAN, ADMIN_SLAY,
    ADMIN_MAP, ADMIN_CVAR, ADMIN_CFG, ADMIN_CHAT, ADMIN_VOTE,
    ADMIN_PASSWORD, ADMIN_RCON, ADMIN_LEVEL_A, ADMIN_LEVEL_B, ADMIN_LEVEL_C,
    ADMIN_LEVEL_D, ADMIN_LEVEL_E, ADMIN_LEVEL_F, ADMIN_LEVEL_G, ADMIN_LEVEL_H,
    ADMIN_MENU, ADMIN_USER
};

public plugin_precache()
{
    precache_sound(IMPO_SOUND);
}

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    new datadir[128];
    get_datadir(datadir, charsmax(datadir));
    formatex(g_szCfgPath, charsmax(g_szCfgPath), "%s/announcer.cfg", datadir);
    formatex(g_szFlagsCfgPath, charsmax(g_szFlagsCfgPath), "%s/ann_flags.cfg", datadir);

    g_msgSayText = get_user_msgid("SayText");

    register_concmd("ann_reload", "CmdAnnReload", ADMIN_ALL, "Reload Announcer config");
    
    register_clcmd("say /ann_menu", "CmdShowMainMenu");
    register_concmd("amx_ann_menu", "CmdShowMainMenu");

    LoadFlagsConfig();
    EnsureConfigFileExists();
    LoadAnnouncerConfig();
}

public plugin_end()
{
    if (g_aMsgs) ArrayDestroy(g_aMsgs);
}

LoadFlagsConfig()
{
    if (!file_exists(g_szFlagsCfgPath))
    {
        SaveFlagsConfig();
        return;
    }

    new fp = fopen(g_szFlagsCfgPath, "rt");
    if (!fp) return;

    new line[128], key[32], val[32];
    while (!feof(fp))
    {
        fgets(fp, line, charsmax(line));
        trim(line);

        if (!line[0] || line[0] == ';' || line[0] == '#') continue;

        strtok(line, key, charsmax(key), val, charsmax(val), '=');
        trim(key);
        trim(val);

        if (equali(key, "reload"))
        {
            g_iFlagReload = read_flags(val);
        }
        else if (equali(key, "mvp"))
        {
            g_iFlagMVP = read_flags(val);
        }
    }
    fclose(fp);
}

SaveFlagsConfig()
{
    new fp = fopen(g_szFlagsCfgPath, "wt");
    if (!fp) return;

    new szReload[32], szMVP[32];
    get_flags(g_iFlagReload, szReload, charsmax(szReload));
    get_flags(g_iFlagMVP, szMVP, charsmax(szMVP));

    fprintf(fp, "; Announcer Flags Configuration%c", 10);
    fprintf(fp, "reload=%s%c", szReload, 10);
    fprintf(fp, "mvp=%s%c", szMVP, 10);

    fclose(fp);
}

public CmdShowMainMenu(id)
{
    if (!(get_user_flags(id) & ADMIN_RCON))
    {
        client_print(id, print_chat, "[Announcer] You do not have access to the flag settings.");
        return PLUGIN_HANDLED;
    }

    new menu = menu_create("\yAnnouncer: \wFlag Settings", "MainMenu_Handler");
    new szItem[128], szFlagName[64];

    GetFlagNameByValue(g_iFlagReload, szFlagName, charsmax(szFlagName));
    formatex(szItem, charsmax(szItem), "Change flag for: \yReload\w (Current: \r%s\w)", szFlagName);
    menu_additem(menu, szItem, "0");

    GetFlagNameByValue(g_iFlagMVP, szFlagName, charsmax(szFlagName));
    formatex(szItem, charsmax(szItem), "Change flag for: \yMVP Messages\w (Current: \r%s\w)", szFlagName);
    menu_additem(menu, szItem, "1");

    menu_display(id, menu, 0);
    return PLUGIN_HANDLED;
}

public MainMenu_Handler(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new data[6], szName[64], access, callback;
    menu_item_getinfo(menu, item, access, data, charsmax(data), szName, charsmax(szName), callback);
    
    new selection = str_to_num(data);
    menu_destroy(menu);
    
    ShowFlagMenu(id, selection);
    return PLUGIN_HANDLED;
}

public ShowFlagMenu(id, settingType)
{
    g_iMenuTarget[id] = settingType; 
    
    new menuTitle[128];
    formatex(menuTitle, charsmax(menuTitle), "\ySelect a new flag for \w%s:", settingType == 0 ? "Reload" : "MVP");
    new menu = menu_create(menuTitle, "FlagMenu_Handler");
    
    new currentFlag = (settingType == 0) ? g_iFlagReload : g_iFlagMVP;
    
    for (new i = 0; i < sizeof(g_szFlagNames); i++)
    {
        new szItem[64], szNum[4];
        num_to_str(i, szNum, charsmax(szNum));
        
        if (currentFlag == g_iFlagValues[i])
        {
            formatex(szItem, charsmax(szItem), "\r%s [*]", g_szFlagNames[i]);
        }
        else
        {
            formatex(szItem, charsmax(szItem), "\w%s", g_szFlagNames[i]);
        }
        
        menu_additem(menu, szItem, szNum);
    }
    
    menu_display(id, menu, 0);
}

public FlagMenu_Handler(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        CmdShowMainMenu(id);
        return PLUGIN_HANDLED;
    }
    
    new data[6], szName[64], access, callback;
    menu_item_getinfo(menu, item, access, data, charsmax(data), szName, charsmax(szName), callback);
    
    new flagIndex = str_to_num(data);
    new newFlag = g_iFlagValues[flagIndex];
    
    if (g_iMenuTarget[id] == 0)
    {
        g_iFlagReload = newFlag;
        client_print(id, print_chat, "[Announcer] Reload flag has been changed to: %s", g_szFlagNames[flagIndex]);
    }
    else
    {
        g_iFlagMVP = newFlag;
        client_print(id, print_chat, "[Announcer] MVP flag has been changed to: %s", g_szFlagNames[flagIndex]);
    }
    
    SaveFlagsConfig();
    
    menu_destroy(menu);
    
    ShowFlagMenu(id, g_iMenuTarget[id]); 
    return PLUGIN_HANDLED;
}

GetFlagNameByValue(flagValue, output[], maxlen)
{
    for (new i = 0; i < sizeof(g_iFlagValues); i++)
    {
        if (g_iFlagValues[i] == flagValue)
        {
            copy(output, maxlen, g_szFlagNames[i]);
            return;
        }
    }
    copy(output, maxlen, "Unknown");
}

EnsureConfigFileExists()
{
    if (file_exists(g_szCfgPath))
        return;

    new fp = fopen(g_szCfgPath, "wt");
    if (!fp) return;

    fprintf(fp, "; Announcer%c", 10);
    fprintf(fp, "; You can use colors (prefixes):%c", 10);
    fprintf(fp, ";   *d = default chat color%c", 10);
    fprintf(fp, ";   *t = team color%c", 10);
    fprintf(fp, ";   *g = green%c", 10);
    fprintf(fp, ";%c", 10);
    fprintf(fp, "; Dynamic variables:%c", 10);
    fprintf(fp, ";   {PLAYERS}    - Current player count%c", 10);
    fprintf(fp, ";   {MAXPLAYERS} - Server slots%c", 10);
    fprintf(fp, ";   {MAP}        - Current map name%c", 10);
    fprintf(fp, ";   {TIME}       - Current server time%c", 10);
    fprintf(fp, ";   {IMPO}       - Plays an alert sound%c", 10);
    fprintf(fp, ";   {MVP}        - Message visible only to admins%c", 10);
    fprintf(fp, ";%c", 10);
    fprintf(fp, "; Escape asterisk with backslash to print it literally: \\*%c%c", 10, 10);

    fprintf(fp, "Interval: 120%c", 10);
    fprintf(fp, "Random: false%c%c", 10, 10);

    fprintf(fp, "Messages:%c", 10);
    fprintf(fp, "%c%s%c%c", 34, "*g[INFO]*d Now playing *t{PLAYERS} / {MAXPLAYERS}*d on map *g{MAP}*d.", 34, 10);
    fprintf(fp, "%c%s%c%c", 34, "{IMPO}*g[IMPORTANT]*d This message played alert sound!", 34, 10);
    fprintf(fp, "%c%s%c%c", 34, "{MVP}*t[VIP]*d World-Time is *g{TIME}*d. Enjoy your game!", 34, 10);

    fclose(fp);
}

LoadAnnouncerConfig()
{
    g_bReloading = true;

    if (g_aMsgs) ArrayClear(g_aMsgs);
    else g_aMsgs = ArrayCreate(MAX_MSG_LEN + 1);

    g_iInterval   = 120;
    g_bRandom     = false;
    g_iMsgIndex   = 0;
    g_iLastRandom = -1;

    new fp = fopen(g_szCfgPath, "rt");
    if (!fp)
    {
        if (task_exists(TASK_ANNOUNCER)) remove_task(TASK_ANNOUNCER);
        set_task(float(g_iInterval), "Task_Announce", TASK_ANNOUNCER, _, _, "b");
        g_bReloading = false;
        return;
    }

    new line[256];
    new bool:inMessages = false;

    while (!feof(fp))
    {
        fgets(fp, line, charsmax(line));
        trim(line);

        if (!line[0]) continue;
        if (line[0] == ';' || line[0] == '/') continue;

        if (!inMessages)
        {
            if (containi(line, "Messages:") == 0)
            {
                inMessages = true;
                continue;
            }

            if (containi(line, "Interval:") == 0)
            {
                new p = contain(line, ":");
                if (p != -1)
                {
                    new valStr[32];
                    copy(valStr, charsmax(valStr), line[p+1]);
                    trim(valStr);
                    new iv = str_to_num(valStr);
                    if (iv < MIN_INTERVAL_SEC) iv = MIN_INTERVAL_SEC;
                    g_iInterval = iv;
                }
                continue;
            }

            if (containi(line, "Random:") == 0)
            {
                new p = contain(line, ":");
                if (p != -1)
                {
                    new valStr[32];
                    copy(valStr, charsmax(valStr), line[p+1]);
                    trim(valStr);
                    g_bRandom = (equali(valStr, "true") || equali(valStr, "yes") || str_to_num(valStr) == 1);
                }
                continue;
            }

            continue;
        }
        else
        {
            new msg[MAX_MSG_LEN + 1];
            copy(msg, charsmax(msg), line);

            new len = strlen(msg);
            if (len >= 2 && msg[0] == '"' && msg[len-1] == '"')
            {
                msg[len-1] = 0;
                copy(msg, charsmax(msg), msg[1]);
            }

            trim(msg);
            if (!msg[0]) continue;

            msg[MAX_MSG_LEN] = 0;
            ArrayPushString(g_aMsgs, msg);
        }
    }

    fclose(fp);

    if (ArraySize(g_aMsgs) == 0)
    {
        ArrayPushString(g_aMsgs, "Welcome to the server!");
    }

    if (task_exists(TASK_ANNOUNCER)) remove_task(TASK_ANNOUNCER);
    set_task(float(g_iInterval), "Task_Announce", TASK_ANNOUNCER, _, _, "b");

    g_bReloading = false;
}

stock GetEligiblePlayers(players[], &num)
{
    num = 0;

    new all[32], nall;
    get_players(all, nall, "ch");

    for (new i = 0; i < nall; i++)
    {
        new id = all[i];
        if (!is_user_connected(id)) continue;

        if (get_user_team(id) == 0) continue;

        players[num++] = id;
    }
}

stock ToSayTextColors(const input[], output[], outlen)
{
    new i = 0, j = 0;

    if (input[0] != 0x01 && input[0] != 0x03 && input[0] != 0x04)
    {
        if (j < outlen - 1) output[j++] = 0x01;
    }

    while (input[i] && j < outlen - 1)
    {
        if (input[i] == 92 && input[i+1] == 42)
        {
            output[j++] = 42;
            i += 2;
            continue;
        }

        if (input[i] == 42 && input[i+1])
        {
            new c = input[i+1];
            if (c == 'd' || c == 'D')
            {
                if (j < outlen - 1) output[j++] = 0x01;
                i += 2;
                continue;
            }
            if (c == 't' || c == 'T')
            {
                if (j < outlen - 1) output[j++] = 0x03;
                i += 2;
                continue;
            }
            if (c == 'g' || c == 'G')
            {
                if (j < outlen - 1) output[j++] = 0x04;
                i += 2;
                continue;
            }
        }

        output[j++] = input[i++];
    }

    output[j] = 0;
}

stock SendColoredMessageAll(const msg[], bool:bIsMVP, bool:bPlaySound)
{
    new buf[MAX_MSG_LEN + 8];
    ToSayTextColors(msg, buf, sizeof(buf));

    new players[32], num;
    GetEligiblePlayers(players, num);
    if (num <= 0) return;

    for (new i = 0; i < num; i++)
    {
        new id = players[i];
        
        if (bIsMVP && !(get_user_flags(id) & g_iFlagMVP))
            continue;

        message_begin(MSG_ONE, g_msgSayText, _, id);
        write_byte(id);
        write_string(buf);
        message_end();
        
        if (bPlaySound)
        {
            client_cmd(id, "spk ^"%s^"", IMPO_SOUND);
        }
    }
}

public Task_Announce()
{
    if (g_bReloading) return;

    new elig[32], eligNum;
    GetEligiblePlayers(elig, eligNum);
    if (eligNum <= 0)
        return;

    new count = ArraySize(g_aMsgs);
    if (count <= 0)
        return;

    new idx;

    if (g_bRandom)
    {
        if (count == 1) idx = 0;
        else
        {
            idx = random_num(0, count - 1);
            if (idx == g_iLastRandom) idx = (idx + 1) % count;
        }
        g_iLastRandom = idx;
    }
    else
    {
        if (g_iMsgIndex < 0 || g_iMsgIndex >= count) g_iMsgIndex = 0;
        idx = g_iMsgIndex;
        g_iMsgIndex = (g_iMsgIndex + 1) % count;
    }

    new msg[MAX_MSG_LEN * 2];
    ArrayGetString(g_aMsgs, idx, msg, charsmax(msg));

    new bool:bIsMVP = (replace_all(msg, charsmax(msg), "{MVP}", "") > 0);
    new bool:bPlaySound = (replace_all(msg, charsmax(msg), "{IMPO}", "") > 0);

    if (contain(msg, "{MAP}") != -1)
    {
        new map[32];
        get_mapname(map, charsmax(map));
        replace_all(msg, charsmax(msg), "{MAP}", map);
    }

    if (contain(msg, "{MAXPLAYERS}") != -1)
    {
        new maxpl[8];
        num_to_str(get_maxplayers(), maxpl, charsmax(maxpl));
        replace_all(msg, charsmax(msg), "{MAXPLAYERS}", maxpl);
    }

    if (contain(msg, "{PLAYERS}") != -1)
    {
        new plStr[8];
        num_to_str(get_playersnum(), plStr, charsmax(plStr));
        replace_all(msg, charsmax(msg), "{PLAYERS}", plStr);
    }

    if (contain(msg, "{TIME}") != -1)
    {
        new timeStr[32];
        get_time("%H:%M:%S", timeStr, charsmax(timeStr));
        replace_all(msg, charsmax(msg), "{TIME}", timeStr);
    }

    trim(msg);
    msg[MAX_MSG_LEN] = 0;

    SendColoredMessageAll(msg, bIsMVP, bPlaySound);
}

public CmdAnnReload(id, level, cid)
{
    if (id == 0)
    {
        LoadAnnouncerConfig();
        server_print("[Announcer] Config Reloaded.");
        log_amx("[Announcer] Config reloaded by server console.");
        return PLUGIN_HANDLED;
    }

    if (!(get_user_flags(id) & g_iFlagReload))
    {
        client_print(id, print_console, "[Announcer] You do not have access to this command.");
        return PLUGIN_HANDLED;
    }

    LoadAnnouncerConfig();

    client_print(id, print_console, "[Announcer] Config Reloaded.");
    server_print("[Announcer] Config reloaded by admin #%d.", id);
    log_amx("[Announcer] Config reloaded by admin #%d.", id);

    return PLUGIN_HANDLED;
}