#include <amxmodx>
#include <amxmisc>

#define PLUGIN_NAME    "Announcer"
#define PLUGIN_VERSION "1.3"
#define PLUGIN_AUTHOR  "sakulmore"

#define TASK_ANNOUNCER   50011
#define MIN_INTERVAL_SEC 5
#define MAX_MSG_LEN      191

#define ANN_RELOAD_FLAG ADMIN_LEVEL_H

new g_szCfgPath[256];
new g_iInterval = 120;
new bool:g_bRandom = false;

new Array:g_aMsgs;
new g_iMsgIndex = 0;
new g_iLastRandom = -1;

new g_msgSayText;
new bool:g_bReloading = false;

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    new datadir[128];
    get_datadir(datadir, charsmax(datadir));
    formatex(g_szCfgPath, charsmax(g_szCfgPath), "%s/announcer.cfg", datadir);

    g_msgSayText = get_user_msgid("SayText");

    register_concmd("ann_reload", "CmdAnnReload", ANN_RELOAD_FLAG, "Reload Announcer config");

    EnsureConfigFileExists();
    LoadAnnouncerConfig();
}

public plugin_end()
{
    if (g_aMsgs) ArrayDestroy(g_aMsgs);
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
    fprintf(fp, "; Escape asterisk with backslash to print it literally: \\*%c%c", 10, 10);

    fprintf(fp, "Interval: 120%c", 10);
    fprintf(fp, "Random: false%c%c", 10, 10);

    fprintf(fp, "Messages:%c", 10);
    fprintf(fp, "%c%s%c%c", 34, "*g[MY-WEBSITE]*d Visit our *twebsite*d!", 34, 10);
    fprintf(fp, "%c%s%c%c", 34, "This prints a literal asterisk: \\* star", 34, 10);
    fprintf(fp, "%c%s%c%c", 34, "*gWelcome*d to *tserver*d!", 34, 10);

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

stock SendColoredMessageAll(const msg[])
{
    new buf[MAX_MSG_LEN + 8];
    ToSayTextColors(msg, buf, sizeof(buf));

    new players[32], num;
    GetEligiblePlayers(players, num);
    if (num <= 0) return;

    for (new i = 0; i < num; i++)
    {
        new id = players[i];
        message_begin(MSG_ONE, g_msgSayText, _, id);
        write_byte(id);
        write_string(buf);
        message_end();
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

    new msg[MAX_MSG_LEN + 1];
    ArrayGetString(g_aMsgs, idx, msg, charsmax(msg));

    SendColoredMessageAll(msg);
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

    if (!cmd_access(id, level, cid, 1))
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