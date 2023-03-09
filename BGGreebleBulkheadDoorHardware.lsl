// BG [Greeble] Bulkhead Door Hardware
// Replacement script for these doors at Black Gazza
// Timberwoof Lupindo
// May 20, 2018 - May 29, 2018
// June 15, 2020
// 3.0 Separates Hardware and Logic Layers

// ========================================
// custom for Greeble

// Frame
integer LINK_FRAME = 1;
integer FACE_FRAME_BEVEL = 0; // bevel
integer FACE_FRAME_FRONT = 1; // font side
integer FACE_FRAME_BACK = 2; // back side

// Doors
integer LINK_DOOR_1 = 3; // facing the front, the left one, has icon
integer LINK_DOOR_2 = 2; // facing the front, the right one

integer FACE_ICON = 5;
integer FACE_MULLION_1 = 3; // left door's facing mullion; right door's back mullion
integer FACE_MULLION_2 = 1; // left door's back mullion; right door's facing mulllion
integer FACE_PANEL_1 = 4; // left doors' facing panel; right dor's back panel
integer FACE_PANEL_2 = 2; // left door's back panel; right door's facing panel

// icon textures
vector ICON_TEXTURE_SCALE = <30.0, 23.0, 0>;
vector ICON_TEXTURE_OFFSET = <0.34, 0.23, 0>;

// Physical Sizes
vector SCALE_DOOR = <0.5, 0.5, 1.0>; // thickness width height
float CLOSE_FACTOR = 0.2;
float OPEN_FACTOR = 0.575;
float ZOFFSET_FACTOR = 0.0;

// Options
vector OPTION_COLOR_FRAME = <1,1,1>;
vector OPTION_COLOR_PANELS = <0.5,0.5,0.5>;
vector OPTION_COLOR_CLEATS = <1,1,1>;



// ========================================
// Common

// colors
vector BLACK = <0,0,0>;
vector DARK_GRAY = <0.2, 0.2, 0.2>;
vector DARK_BLUE = <0.0, 0.0, 0.2>;
vector BLUE = <0.0, 0.0, 1.0>;
vector MAGENTA = <1.0, 0.0, 1.0>;
vector CYAN = <0.0, 1.0, 1.0>;
vector WHITE = <1.0, 1.0, 1.0>;
vector RED = <1.0, 0.0, 0.0>;
vector REDORANGE = <1.0, 0.25, 0.0>;
vector ORANGE = <1.0, 0.5, 0.0>;
vector YELLOW = <1.0, 1.0, 0.0>;
vector GREEN = <0.0, 1.0, 0.0>;

// my textures
string texture_auto_close = "d04fe5a2-d59e-d92d-3498-a0f4b1279356";
string texture_edgeStripes = "622233c6-10b8-0df0-720f-72d6627d5e04";
string texture_padlock = "8e3485b0-3fb0-ef68-2fcb-b88b3ee929df";
string texture_press_to_open = "f80eb0af-0ecf-06bc-c708-64397285b40b";
string texture_bump_to_open = "55a465d3-32e6-9de4-54e7-a7168bcc74d2";

// sounds
string sound_slide = "b3845015-d1d5-060b-6a63-de05d64d5444";
string sound_granted = "a4a9945e-8f73-58b8-8680-50cd460a3f46";
string sound_denied = "d679e663-bba3-9caa-08f7-878f65966194";
string sound_lockdown = "2d9b82b0-84be-d6b2-22af-15d30c92ad21";
string sound_warning = "fb0a28c3-4e7a-7554-0403-d8c3f56d1ccc";
string sound_door = "ccab0df8-8819-9840-9327-ae2791a9d2e2";
string sound_slam = "fc85aee3-2358-55aa-ba3d-d2d40f58e2bc";
string sound_latch = "e96de4ba-b21c-03e4-03f9-31b5da9b6f99";

float fwidth;
float fopen;
float fclose;
float fdelta;
float fZoffset;

// Door States
integer doorState; // 1 = door is open
integer OPEN = 1;
integer CLOSED = 0;
integer QUIETLY = 0;
integer NOISILY = 1;

// power states
integer gPowerState = 0;
integer POWER_OFF = 0;
integer POWER_ON = 1;
integer POWER_FAILING = 2;

// lockdown
integer gLockdownState = 0; // not locked down
integer LOCKDOWN_OFF = 0;
integer LOCKDOWN_IMMINENT = 1;
integer LOCKDOWN_ON = 2;
integer LOCKDOWN_TEMP = 3; // for normally-open door closed fair-game release

// options
integer OPTION_DEBUG = 0;
vector OUTLINE_COLOR = <0,0,0>;
vector FRAME_COLOR = <1,1,1>;
integer OPTION_NORMALLY_OPEN;
integer OPTION_GROUP;
integer OPTION_BUTTON;
integer OPTION_BUMP; // need to know which icon to present
integer OPTION_POWER; // need to know power state

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llWhisper(0,"DOOR "+message);
    }
}

sendJSON(string jsonKey, string value, key avatarKey){
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, [jsonKey, value]), avatarKey);
}
    
sendJSONCheckbox(string jsonKey, string value, key avatarKey, integer ON) {
    if (ON) {
        sendJSON(jsonKey, value+"ON", avatarKey);
    } else {
        sendJSON(jsonKey, value+"OFF", avatarKey);
    }
}
    
sendJSONinteger(string jsonKey, integer value, key avatarKey){
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, [jsonKey, (string)value]), avatarKey);
}
    
string getJSONstring(string jsonValue, string jsonKey, string valueNow){
    string result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = value;
    }
    return result;
}
    
integer getJSONinteger(string jsonValue, string jsonKey, integer valueNow){
    integer result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = (integer)value;
    }
    return result;
}

reportStatus()
{
    llWhisper(0,"Door Hardware Status:");
    llWhisper(0,"doorState: "+(string)doorState);
    llWhisper(0,"gLockdownState: "+(string)gLockdownState);
    llWhisper(0,"gPowerState: "+(string)gPowerState);
    llWhisper(0,"group: "+(string)OPTION_GROUP);
    llWhisper(0,"normally-open: "+(string)OPTION_NORMALLY_OPEN);
    llWhisper(0,"button: "+(string)OPTION_BUTTON);
    llWhisper(0,"bump: "+(string)OPTION_BUMP);
    llWhisper(0,"debug: "+(string)OPTION_DEBUG);
    llWhisper(0,"power: "+(string)OPTION_POWER);
}

// ========================================
// custom
open()
{
    sayDebug("open()");
    if ((CLOSED == doorState) & (gPowerState == POWER_ON))
    {
        llSetLinkPrimitiveParamsFast(LINK_FRAME, [PRIM_COLOR, FACE_FRAME_BEVEL, REDORANGE, 1.0]);
        llSetLinkPrimitiveParamsFast(LINK_FRAME, [PRIM_GLOW, FACE_FRAME_BEVEL, 0.1]);
        setIconColor(GREEN);
        setIconTexture(texture_edgeStripes);

        llPlaySound(sound_door, 1.0);
        float f;
        for (f = fclose; f < fopen; f = f + fdelta)
        {
            llSetLinkPrimitiveParamsFast(LINK_DOOR_1,[PRIM_POS_LOCAL, <0.0, -f, fZoffset> ]);
            llSetLinkPrimitiveParamsFast(LINK_DOOR_2,[PRIM_POS_LOCAL, <0.0, f, fZoffset>]);
        }
        llSetLinkPrimitiveParamsFast(LINK_DOOR_1,[PRIM_POS_LOCAL, <0.0, -fopen, fZoffset> ]);
        llSetLinkPrimitiveParamsFast(LINK_DOOR_2,[PRIM_POS_LOCAL, <0.0, fopen, fZoffset>]);
        llPlaySound(sound_latch, 1.0);
        llSetLinkPrimitiveParamsFast(LINK_FRAME, [PRIM_GLOW, FACE_FRAME_BEVEL, 0.0]);
        llSetLinkPrimitiveParamsFast(LINK_FRAME, [PRIM_COLOR, FACE_FRAME_BEVEL, WHITE, 1.0]);
        doorState = OPEN;
        sendJSONinteger("doorState", doorState, "");
    }
    setColorsAndIcons();
}

close()
{
    sayDebug("close");
    if (OPEN == doorState)
    {
        llSetLinkPrimitiveParamsFast(LINK_FRAME, [PRIM_COLOR, FACE_FRAME_BEVEL, REDORANGE, 1.0]);
        llSetLinkPrimitiveParamsFast(LINK_FRAME, [PRIM_GLOW, FACE_FRAME_BEVEL, 0.1]);
        setIconColor(REDORANGE);
        setIconTexture(texture_edgeStripes);

        llPlaySound(sound_door, 1.0);
        float f;
        for (f = fopen; f >= fclose; f = f - fdelta)
        {
            llSetLinkPrimitiveParamsFast(LINK_DOOR_1,[PRIM_POS_LOCAL, <0.0, -f, fZoffset>]);
            llSetLinkPrimitiveParamsFast(LINK_DOOR_2,[PRIM_POS_LOCAL, <0.0, f, fZoffset>]);
        }
        llSetLinkPrimitiveParamsFast(LINK_DOOR_1,[PRIM_POS_LOCAL, <0.0, -fclose, fZoffset>]);
        llSetLinkPrimitiveParamsFast(LINK_DOOR_2,[PRIM_POS_LOCAL, <0.0, fclose, fZoffset>]);
        llPlaySound(sound_latch, 1.0);
        llSetLinkPrimitiveParamsFast(LINK_FRAME, [PRIM_GLOW, FACE_FRAME_BEVEL, 0.0]);
        llSetLinkPrimitiveParamsFast(LINK_FRAME, [PRIM_COLOR, FACE_FRAME_BEVEL, WHITE, 1.0]);
        doorState = CLOSED;
        sendJSONinteger("doorState", doorState, "");
    }
    setColorsAndIcons();
}

setColorsAndIcons()
{
    sayDebug("setColorsAndIcons gPowerState:"+(string)gPowerState+" gLockdownState:"+(string)gLockdownState+" doorState:"+(string)doorState);
    if (gPowerState == POWER_OFF)
    {
        sayDebug("setColorsAndIcons gPowerState POWER_OFF");
        setIconColor(BLACK);
        return;
    }

    if (gPowerState == POWER_FAILING)
    {
        sayDebug("setColorsAndIcons gPowerState POWER_FAILING");
        setIconColor(BLUE);
        return;
    }

    if (gLockdownState == LOCKDOWN_IMMINENT)
    {
        sayDebug("setColorsAndIcons gLockdownState LOCKDOWN_IMMINENT");
        setIconColor(REDORANGE);
        setIconTexture(texture_edgeStripes);
        return;
    }

    if (gLockdownState == LOCKDOWN_ON)
    {
        sayDebug("setColorsAndIcons gLockdownState LOCKDOWN_ON");
        setIconColor(RED);
        setIconTexture(texture_padlock);
        return;
    }
    
    if (OPEN == doorState)
    {
        sayDebug("setColorsAndIcons doorState OPEN");
        setIconColor(WHITE);
        setIconTexture(texture_edgeStripes);
    }
    else // (CLOSED == doorState)
    {
        if (OPTION_NORMALLY_OPEN) // temporarily closed
        {
            sayDebug("setColorsAndIcons CLOSED OPTION_NORMALLY_OPEN");
            setIconColor(WHITE);
            setIconTexture(texture_padlock);
        }
        else // (!OPTION_NORMALLY_OPEN)
        {
            sayDebug("setColorsAndIcons CLOSED !OPTION_NORMALLY_OPEN");
            if(OPTION_GROUP)
            {
                setIconColor(ORANGE);
            }
            else
            {
                setIconColor(WHITE);
            }
            if(OPTION_BUTTON)
            {
                if (OPTION_BUMP)
                {
                    setIconTexture(texture_bump_to_open);
                }
                else
                {
                    setIconTexture(texture_press_to_open);
                }
            }
            else
            {
                if (OPTION_BUMP)
                {
                    setIconTexture(texture_bump_to_open);
                }
                else
                {
                    setIconTexture(texture_padlock);
                }
            }
        }
    }
}

setIconColor(vector Color)
{
    llSetLinkColor(LINK_DOOR_1, Color, FACE_ICON);
    llSetLinkColor(LINK_DOOR_2, Color, FACE_ICON);
}

setIconTexture(string texture)
{
    llSetLinkTexture(LINK_DOOR_1, texture, FACE_ICON);
    llSetLinkTexture(LINK_DOOR_2, texture, FACE_ICON);
}

default
{
    state_entry()
    {
        sayDebug("state_entry");
        gPowerState = POWER_OFF;
        
        // panel texture scale and offset
        setIconColor(BLACK);
        llSetLinkPrimitiveParams(LINK_DOOR_1, [PRIM_TEXTURE, FACE_ICON, texture_padlock, ICON_TEXTURE_SCALE, ICON_TEXTURE_OFFSET, 0.0]);
        llSetLinkPrimitiveParams(LINK_DOOR_2, [PRIM_TEXTURE, FACE_ICON, texture_padlock, ICON_TEXTURE_SCALE, ICON_TEXTURE_OFFSET, 0.0]);
        llSetLinkPrimitiveParams(LINK_DOOR_1, [PRIM_GLOW, FACE_ICON, 0.1]);
        llSetLinkPrimitiveParams(LINK_DOOR_2, [PRIM_GLOW, FACE_ICON, 0.1]);
        
        // calculate the leaf movements
        // get the size of the door frame and calculate the sizes of the leaves
        vector frameSize = llGetScale( );
        vector leafsize = <frameSize.x * SCALE_DOOR.x, frameSize.y * SCALE_DOOR.y, frameSize.z * SCALE_DOOR.z>;
        fwidth = frameSize.y;
        fclose = fwidth * CLOSE_FACTOR;
        fopen = fwidth * OPEN_FACTOR;
        fZoffset = frameSize.z * ZOFFSET_FACTOR;
        fdelta = llFabs(fopen - fclose) * 0.003;
        
        // set the initial leaf sizes and positions
        llSetLinkPrimitiveParamsFast(LINK_DOOR_1,[PRIM_SIZE,leafsize]);
        llSetLinkPrimitiveParamsFast(LINK_DOOR_2,[PRIM_SIZE,leafsize]);
        llSetLinkPrimitiveParamsFast(LINK_DOOR_1,[PRIM_POS_LOCAL, <0.0, -fclose, 0.0>]);
        llSetLinkPrimitiveParamsFast(LINK_DOOR_2,[PRIM_POS_LOCAL, <0.0,  fclose, 0.0>]);

        gPowerState = POWER_ON;
        
        if (OPTION_NORMALLY_OPEN) {
            open();
            close();
            open();
        }
        else
        {
            close();
            open();
            close();
        }
        
        sendJSON("command", "getStatus", llDetectedKey(0));
        setColorsAndIcons();
        llPlaySound(sound_granted,1);
        sayDebug("initialized");
    }

    touch_start(integer total_number)
    {
        sayDebug("touch_start link:"+(string)llDetectedLinkNumber(0)+" face:"+(string)llDetectedTouchFace(0));
        setIconColor(YELLOW);
        llResetTime();
        llSetTimerEvent(1);
    }
    
    touch_end(integer num_detected)
    {
        sayDebug("touch_end num_detected "+(string)num_detected);
        if ( (llDetectedLinkNumber(0) == LINK_DOOR_1 & llDetectedTouchFace(0) == FACE_ICON) |
             (llDetectedLinkNumber(0) == LINK_DOOR_2 & llDetectedTouchFace(0) == FACE_ICON) )
        {
            if (llGetTime() >= 2.0)
            {
                setIconColor(ORANGE);
                sendJSON("command", "admin", llDetectedKey(0));
            }
            else if (OPTION_BUTTON)
            {
                setIconColor(GREEN);
                sendJSON("command", "button", llDetectedKey(0));
            }
            else {
                setIconColor(WHITE);
            }
            llSetTimerEvent(0);
        }
    }
    
    timer() {
        if (llGetTime() >= 2.0) {
            setIconColor(CYAN);
        }
    }
    
    collision_start(integer total_number)
    {
        sayDebug("collision_start");
        if (OPTION_BUMP)
        {
             sendJSON("command", "bump", llDetectedKey(0));
        }
    }
    
    link_message(integer sender_num, integer num, string json, key avatarKey){
        sayDebug("link_message "+json);
        OPTION_DEBUG = getJSONinteger(json, "OPTION_DEBUG", OPTION_DEBUG);
        OPTION_GROUP = getJSONinteger(json, "OPTION_GROUP", OPTION_GROUP);
        OPTION_NORMALLY_OPEN = getJSONinteger(json, "OPTION_NORMALLY_OPEN", OPTION_NORMALLY_OPEN);
        OPTION_BUMP = getJSONinteger(json, "OPTION_BUMP", OPTION_BUMP);
        OPTION_BUTTON = getJSONinteger(json, "OPTION_BUTTON", OPTION_BUTTON);
        OPTION_COLOR_FRAME = (vector)getJSONstring(json, "OPTION_COLOR_FRAME", (string)OPTION_COLOR_FRAME);
        OPTION_COLOR_PANELS = (vector)getJSONstring(json, "OPTION_COLOR_PANELS", (string)OPTION_COLOR_PANELS);
        OPTION_COLOR_CLEATS = (vector)getJSONstring(json, "OPTION_COLOR_CLEATS", (string)OPTION_COLOR_CLEATS);
        
        if (llSubStringIndex(json,"OPTION_COLOR_FRAME") > -1) {
            // LINK_FRAME x FACE_FRAME_FRONT FACE_FRAME_BACK
            llSetLinkPrimitiveParamsFast(LINK_FRAME, [PRIM_COLOR, FACE_FRAME_FRONT, OPTION_COLOR_FRAME, 1.0]);
            llSetLinkPrimitiveParamsFast(LINK_FRAME, [PRIM_COLOR, FACE_FRAME_BACK, OPTION_COLOR_FRAME, 1.0]);
        }
        if (llSubStringIndex(json,"OPTION_COLOR_PANELS") > -1) {
            // LINK_DOOR_1 LINK_DOOR_2 x FACE_PANEL_1 FACE_PANEL_2
            llSetLinkPrimitiveParamsFast(LINK_DOOR_1, [PRIM_COLOR, FACE_PANEL_1, OPTION_COLOR_PANELS, 1.0]);
            llSetLinkPrimitiveParamsFast(LINK_DOOR_1, [PRIM_COLOR, FACE_PANEL_2, OPTION_COLOR_PANELS, 1.0]);
            llSetLinkPrimitiveParamsFast(LINK_DOOR_2, [PRIM_COLOR, FACE_PANEL_1, OPTION_COLOR_PANELS, 1.0]);
            llSetLinkPrimitiveParamsFast(LINK_DOOR_2, [PRIM_COLOR, FACE_PANEL_2, OPTION_COLOR_PANELS, 1.0]);
        }
        if (llSubStringIndex(json,"OPTION_COLOR_CLEATS") > -1) {
            // LINK_DOOR_1 LINK_DOOR_2 x FACE_MULLION_1 FACE_MULLION_2
            llSetLinkPrimitiveParamsFast(LINK_DOOR_1, [PRIM_COLOR, FACE_MULLION_1, OPTION_COLOR_CLEATS, 1.0]);
            llSetLinkPrimitiveParamsFast(LINK_DOOR_1, [PRIM_COLOR, FACE_MULLION_2, OPTION_COLOR_CLEATS, 1.0]);
            llSetLinkPrimitiveParamsFast(LINK_DOOR_2, [PRIM_COLOR, FACE_MULLION_1, OPTION_COLOR_CLEATS, 1.0]);
            llSetLinkPrimitiveParamsFast(LINK_DOOR_2, [PRIM_COLOR, FACE_MULLION_2, OPTION_COLOR_CLEATS, 1.0]);
        }
            
        
        gLockdownState = getJSONinteger(json, "lockdownState", gLockdownState);
        gPowerState = getJSONinteger(json, "powerState", gPowerState);
        
        string command = "";
        command = getJSONstring(json, "command", command);
        if (command == "reset") {
            llResetScript();
        } else if (command == "close") {
            close();
        } else if (command == "open") {
            open();
        } else if (command == "setColorsAndIcons") {
            setColorsAndIcons();
        } else if (command == "reportStatus") {
            reportStatus();
        }
    }
}
