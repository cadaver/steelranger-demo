/*
 * Military Scifi game world editor
 */

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
#include <ctype.h>
#include <vector>
#include <map>

extern "C" {

#include "bme.h"
#include "editio.h"
#include "stb_image_write.h"

}

#define MAXPATH 4096

#define COLOR_DELAY 10
#define NUMZONES 2048
#define NUMLEVELS 32
#define NUMCHARSETS 32
#define NUMSHAPES 256
#define NUMBLOCKS 256
#define NUMLVLACT 128
#define NUMLVLOBJ 32
#define NUMLVLZONES 32
#define NUMGLOBALACT 32

#define EM_SHAPE 0
#define EM_MAP 1
#define EM_ZONE 2
#define EM_ACTORS 3

#define SINGLECOLOR 0
#define MULTICOLOR 1

#define SPR_C 0
#define SPR_FONTS 1
#define COL_WHITE 0
#define COL_HIGHLIGHT 1
#define COL_NUMBER 2

#define MAPSIZEX 4096
#define MAPSIZEY 1024

#define BLOCKSIZE 2
#define BLOCKDATASIZE 4
#define BLOCKPIXELSIZE 16
#define BLOCKPIXELSIZE_ZOOMOUT 4
#define SCREENSIZEX 19
#define SCREENSIZEY 10
#define MAXSHAPESIZE 16
#define MAXSHAPEBLOCKSIZE 8
#define ZOOMSHAPEVIEW 6
#define MAXZONESIZE 255

#define COLOR_DELAY 10

#define ZONEBUFFERSIZE 3*1024

struct Shape
{
    unsigned char sx;
    unsigned char sy;
    unsigned char chardata[MAXSHAPESIZE*MAXSHAPESIZE*8];
    unsigned char charcolors[MAXSHAPESIZE*MAXSHAPESIZE];
    unsigned char blockinfos[MAXSHAPEBLOCKSIZE*MAXSHAPEBLOCKSIZE];
    int usecount;
};

struct Charset
{
    Shape shapes[NUMSHAPES];
    unsigned char chardata[2048];
    unsigned char charcolors[256];
    unsigned char blockdata[NUMBLOCKS*BLOCKDATASIZE];
    unsigned char blockinfos[NUMBLOCKS];
    unsigned char shapeblocks[NUMSHAPES][MAXSHAPEBLOCKSIZE*MAXSHAPEBLOCKSIZE];
    unsigned char shapechars[NUMSHAPES][MAXSHAPESIZE*MAXSHAPESIZE];
    std::vector<unsigned char> objectanim;
    std::map<unsigned char, unsigned char> objectanimmap;
    int usedchars;
    int usedblocks;
    bool dirty;
    bool errored;
};

struct Tile
{
    unsigned char x;
    unsigned char y;
    unsigned char s;
};

struct Actor
{
    unsigned char x;
    unsigned char y;
    unsigned char t;
    unsigned char flags;
    unsigned char id;
};

struct Object
{
    unsigned char x;
    unsigned char y;
    unsigned char sx;
    unsigned char sy;
    unsigned char flags;
    unsigned char frames;
    unsigned short data;
    unsigned char id;
};

struct Zone
{
    int sx;
    int sy;
    int x;
    int y;
    unsigned char bg1;
    unsigned char bg2;
    unsigned char bg3;
    unsigned char charset;
    unsigned char fill;
    unsigned char level;
    unsigned char id;
    std::vector<Tile> tiles;
    std::vector<Actor> actors;
    std::vector<Object> objects;
};

struct LevelInfo
{
    bool used;
    std::vector<int> zones;  
    std::vector<unsigned char> zonex;
    std::vector<unsigned char> zoney;
    std::vector<unsigned char> zonesize;
    int actors;
    int nonrespawnactors;
    int actorbitstart;
    int objects;
    int objectbitstart;
    int zonestart;
};

typedef std::pair<unsigned long long, unsigned char> CharKey;
typedef std::pair<unsigned, unsigned char> BlockKey;
typedef std::pair<int, int> CoordKey;

unsigned char slopetbl[] = {
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,  // Slope 0
  0x78,0x70,0x68,0x60,0x58,0x50,0x48,0x40,0x38,0x30,0x28,0x20,0x18,0x10,0x08,0x00,  // Slope 1
  0x78,0x78,0x70,0x70,0x68,0x68,0x60,0x60,0x58,0x58,0x50,0x50,0x48,0x48,0x40,0x40,  // Slope 2
  0x38,0x38,0x30,0x30,0x28,0x28,0x20,0x20,0x18,0x18,0x10,0x10,0x08,0x08,0x00,0x00,  // Slope 3
  0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,  // Slope 4
  0x00,0x08,0x10,0x18,0x20,0x28,0x30,0x38,0x40,0x48,0x50,0x58,0x60,0x68,0x70,0x78,  // Slope 5
  0x00,0x00,0x08,0x08,0x10,0x10,0x18,0x18,0x20,0x20,0x28,0x28,0x30,0x30,0x38,0x38,  // Slope 6
  0x40,0x40,0x48,0x48,0x50,0x50,0x58,0x58,0x60,0x60,0x68,0x68,0x70,0x70,0x78,0x78   // Slope 7
};



char* actorxlatsrc[] = {
"NONE",
"PLAYER",
"ROBOTSOLDIER",
"INTROSOLDIER",
"ELITESOLDIER",
"HEAVYSOLDIER",
"LARGEROBOT",
"ROBOTPRIEST",
"LARGETANK",
"LARGEDRILLTANK",
"LARGEWORM",
"SLIMEBOSS",
"PLAYERWHEEL",
"BULLET",
"BOUNCE",
"LASER",
"FLAME",
"ELECTRICITY",
"GRENADE",
"MISSILE",
"HEAVYPLASMA",
"SMOKETRAIL",
"EXPLOSION",
"WHEELMINE",
"SMALLSPLASH",
"LARGESPLASH",
"ITEM",
"OBJECTMARKER",
"LIFT",
"FLY",
"SPITFLY",
"SPITBALL",
"ARMADILLO",
"TREEMINE",
"CEILINGMINE",
"FLOORMINE",
"SPIKE",
"SPIDER",
"SPITSPIDER",
"TURRET",
"CEILINGTURRET",
"DROID",
"ROBOTMINE",
"FLYINGCRAFT",
"ELITEFLYINGCRAFT",
"ROBOTSPIDER",
"PLAYERNOARMOR",
"WATCHER",
"METALPIECE",
"SMALLWALKER",
"BARREL",
"SMALLTANK",
"DRILLTANK",
"DRILLMELEEHIT",
"WORKERTANK",
"WORKERMELEEHIT",
"CANNONH",
"CANNONV",
"CPUINVISIBLE",
"CPU",
"SQUID",
"LARGEDRILLMELEEHIT",
"SLIME",
"SLIMELAUNCHER",
"SLIMESHOT",
"WORMHEAD",
"WORMPART",
"WORMBOMB",
"MUSHROOMINVISIBLE",
"MUSHROOM",
"ROCKINVISIBLE",
"ROCK",
"FIREBALLSPAWNER",
"FIREBALL",
"LARGEFLY",
"LARGESPIDER",
"ENEMYCHUNK",
"DECONTAMINATOR",
"SPRAY",
"SCREENSAVER",
"DROIDBOSSINVISIBLE",
"DROIDBOSS",
"BOMBBOSSINVISIBLE",
"BOMBBOSS",
"FIGHTERBOSSINVISIBLE",
"FIGHTERBOSS",
"BRIDGEEXPLOSION",
"DISTILLERBOSSINVISIBLE",
"DISTILLERBOSS",
"FINALBOSSINVISIBLE",
"FINALBOSS",
"FINALBOSSBOMB",
"FINALBOSSBOMBEXPLOSION",
"FINALBOSSBRAIN",
"FINALBOSSLASER",
"WORMBOSS",
"WORMBOSSHEAD",
"WORMBOSSPART",
"WORMBOSSBOMB",
"SPIDERBOSS"
};

char* actorxlatdest[] = {
""
};

char* objmodetxts[] = {
    "NONE",
    "TRIG",
    "MAN.",
    "MAN.AD"
};

char* objtypetxts[] = {
    "NONE",
    "WALL",
    "SWITCH",
    "SCRIPT"
};

char* objautodeacttxts[] = {
    "",
    "AUTOD. "
};

unsigned char cwhite[] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35};
unsigned char chl[] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,35,35};
unsigned char cnum[] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35};
Uint8 *colxlattable[] = {cwhite, chl, cnum};
Charset charsets[NUMCHARSETS];
Zone zones[NUMZONES];
char textbuffer[256];
char* actorname[128];
char* itemname[128];

int screensizex = 512;
int screensizey = 384;
unsigned char charsetnum = 0;
unsigned char shapenum = 0;
unsigned zonenum = 0;
unsigned char acttype = 1;
int osx = 0; // Shape offset in zoomed view
int osy = 0;
unsigned char oss = 0; // Shape selector offset
unsigned char esx = 0; // Currently edited char in zoomed shape
unsigned char esy = 0;
unsigned char ccolor = 3; // Currently selected bit combination for char editing
int mapx = 0;
int mapy = 0;
int vsx; // View size x/y in blocks
int vsy;
int divisor = 16;
int divminusone = 15;
bool zoomout = false;
int editmode = EM_SHAPE;
char levelname[80];
bool shapeusedirty = true;
bool wholescreenshapeselect = false;
bool lockedmode = false;

unsigned char charcopybuffer[8];
unsigned char charcopycolor;
Shape shapecopybuffer;
bool scbblockinfos = false;
unsigned char grabmode = 0;
unsigned char grabx1, graby1, grabx2, graby2;
unsigned char mapgrabmode = 0;
unsigned mapgrabx1, mapgraby1, mapgrabx2, mapgraby2;
std::vector<Tile> mapcopybuffer;
int mapcopysx = 0;
int mapcopysy = 0;
std::vector<unsigned> visiblezones;

int dataeditmode = 0;
int dataeditcursor = 0;
int dataeditoidx = -1;

int mousex;
int mousey;
int mouseb;
int prevmouseb = 0;
int colordelay = 0;
int key;
int ascii;
int shiftdown;
int ctrldown;
int frameskip;
int framenum = 0;
int charmarkmode = 0;
int chardirtytimer = 0;

bool doframe();
bool initstuff();
bool confirmquit();
unsigned getcharsprite(char ch);
void printtext_color(const char *string, int x, int y, unsigned spritefile, int color);
void printtext_center_color(const char *string, int y, unsigned spritefile, int color);
void drawcbar(int x, int y, unsigned char col);
void drawbox(int x, int y, int sx, int sy, unsigned char col);
void drawfilledbox(int x, int y, int sx, int sy, unsigned char col);
void drawchar(int x, int y, const unsigned char* data, unsigned char color, const Zone& zone);
void drawcharsmall(int x, int y, const unsigned char* data, unsigned char color, const Zone& zone);
void drawchardest(unsigned char* dest, int modulo, const unsigned char* data, unsigned char color, const Zone& zone);
void drawzoomedchar(int x, int y, const unsigned char* data, unsigned char color, const Zone& zone);
void drawshape(int x, int y, const Shape& shape, const Zone& zone);
void drawshapeblockinfo(int x, int y, const Shape& shape);
void drawshapeblockinfolimit(int x, int y, int lx, int ly, const Shape& shape);
void drawshapelimit(int x, int y, int lx, int ly, const Shape& shape, const Zone& zone);
void drawzoomedshape(int x, int y, int ox, int oy, int sx, int sy, const Shape& shape, const Zone& zone);
void drawblockinfo(int x, int y, unsigned char blockinfo);
void drawmap();
void drawzoneshape(int x, int y, unsigned char num, bool drawnumber, bool drawinfo, const Zone& zone);
void drawzoneshapepng(int x, int y, unsigned char num, const Zone& zone, unsigned char* dest, int sizex, int sizey, int minx, int miny);
void movemap();
void editmap();
void addtile(int x, int y, unsigned char num, Zone& zone);
void removetile(int x, int y, Zone& zone);
int findtile(int x, int y, const Zone& zone, bool topmost = true);
int findobjectshape(int x, int y, const Zone& zone);
void editzone();
int findzone(int x, int y);
int findnearestzone(int x, int y);
bool checkzonelegal(int num, int newx, int newy, int newsx, int newsy);
void movezonetiles(Zone& zone, int xadd, int yadd);
void editactors();
void setmulticol(unsigned char& data, int x, unsigned char bits);
void setsinglecol(unsigned char& data, int x, unsigned char bits);
void scrollcharleft(unsigned char* chardata, unsigned char color);
void scrollcharright(unsigned char* chardata, unsigned char color);
void scrollcharup(unsigned char* chardata, unsigned char color);
void scrollchardown(unsigned char* chardata, unsigned char color);
void selectshape(unsigned char newshape);
void resetcharset(Charset& charset);
void resetshape(Shape& shape);
void deleteshape(int dsnum);
void insertshape();
void insertcharset();
void updateshapeuse();
void updatelockedmode();
void resetzone(Zone& zone);
bool isinsidezone(int x, int y, const Zone& zone);
bool ismouseinside(int x, int y, int sx, int sy);
int inputtext(char* buffer, int maxlength);
void mouseupdate();
void drawandeditshape();
void drawandeditpalette();
void editzonepalette();
void swapcolors(int c1, int c2);
void drawshapeselector();
void drawc64charset();
void loadshapes();
void loadshape(int handle, Shape& shape);
void saveshapes();
void saveshape(int handle, const Shape& shape);
void importblocks();
void loadalldata();
void savealldata();
std::vector<unsigned char> exomize(unsigned char* data, int datasize);
std::vector<unsigned char> rlepack(unsigned char* data, int datasize);
void exportpng();
void nukecharset();
void packcharset(Charset& charset);
void drawc64shape(int x, int y, unsigned char num, const Zone& zone, const Charset& charset, unsigned char* dest);

extern unsigned char datafile[];

int main (int argc, char *argv[])
{
    int c;
    FILE *names;

    io_openlinkeddatafile(datafile);

    if (!win_openwindow("World editor 2", NULL))
        return 1;
    win_fullscreen = 0;

    strcpy(levelname, "world");

    if (!initstuff())
        return 1;

    gfx_setpalette();

    while (doframe())
    {
    }

    return 0;
}

bool doframe()
{
    frameskip = win_getspeed(70);
    framenum += frameskip;
    chardirtytimer += frameskip;
    key = kbd_getkey();
    ascii = kbd_getascii();
    shiftdown = win_keystate[KEY_LEFTSHIFT] | win_keystate[KEY_RIGHTSHIFT];
    ctrldown = win_keystate[KEY_CTRL];
    if (ascii == 27)
    {
        if (confirmquit())
            return false;
    }
    if (key == KEY_F1)
        loadshapes();
    if (key == KEY_F2)
        saveshapes();
    if (key == KEY_F3)
        importblocks();
    if (key == KEY_F9)
        loadalldata();
    if (key == KEY_F10)
        savealldata();
    if (key == KEY_F11)
        exportpng();
    if (key == KEY_F12)
        nukecharset();
    if (key == KEY_F5)
    {
        editmode = EM_SHAPE;
        wholescreenshapeselect = false;
    }
    if (key == KEY_F6)
    {
        // Make sure charset is packed before moving away from shape edit
        if (charsets[charsetnum].dirty && !lockedmode)
            packcharset(charsets[charsetnum]);
        editmode = EM_MAP;
        charsetnum = zones[zonenum].charset;
        wholescreenshapeselect = false;
    }
    if (key == KEY_F7)
    {
        // Make sure charset is packed before moving away from shape edit
        if (charsets[charsetnum].dirty && !lockedmode)
            packcharset(charsets[charsetnum]);
        editmode = EM_ZONE;
        charsetnum = zones[zonenum].charset;
        wholescreenshapeselect = false;
    }
    if (key == KEY_F8)
    {
        // Make sure charset is packed before moving away from shape edit
        if (charsets[charsetnum].dirty && !lockedmode)
            packcharset(charsets[charsetnum]);
        editmode = EM_ACTORS;
        charsetnum = zones[zonenum].charset;
        wholescreenshapeselect = false;
    }

    if (key == KEY_B && editmode == EM_MAP && (!shiftdown && !ctrldown))
    {
        wholescreenshapeselect = !wholescreenshapeselect;
        if (wholescreenshapeselect)
            oss = 0;
    }

    mouseupdate();
    gfx_fillscreen(254);

    switch (editmode)
    {
    case EM_SHAPE:
        drawandeditshape();
        drawandeditpalette();
        drawc64charset();
        drawshapeselector();
        break;

    case EM_MAP:
        if (!wholescreenshapeselect)
        {
            movemap();
            editmap();
            drawmap();
            editzonepalette();
        }
        drawshapeselector();
        break;

    case EM_ZONE:
        movemap();
        drawmap();
        editzone();
        editzonepalette();
        break;

    case EM_ACTORS:
        movemap();
        drawmap();
        editactors();
        break;
    }

    gfx_drawsprite(mousex, mousey, 0x00000021);
    gfx_updatepage();

    ++colordelay;
    colordelay %= COLOR_DELAY;
    if (!mouseb)
        colordelay = 0;

    return true;
}

bool initstuff()
{
    if (!kbd_init())
    {
        win_messagebox("Keyboard init error!");
        return false;
    }

    if (!gfx_init(screensizex,screensizey,70,GFX_DOUBLESIZE))
    {
        win_messagebox("Graphics init error!");
        return false;
    }

    win_setmousemode(MOUSE_ALWAYS_HIDDEN);

    if ((!gfx_loadsprites(SPR_C, "editor.spr")) ||
        (!gfx_loadsprites(SPR_FONTS, "editfont.spr")))
    {
        win_messagebox("Error loading sprites!");
        return false;
    }
    if (!gfx_loadpalette("editor.pal"))
    {
        win_messagebox("Error loading palette!");
        return false;
    }

    FILE* names;
    for (int c = 0; c < 128; c++) actorname[c] = " ";
    for (int c = 0; c < 128; c++) itemname[c] = " ";
    names = fopen("names.txt", "rt");
    if (names)
    {
        for (int c = 1; c < 128; c++)
        {
            actorname[c] = (char*)malloc(80);
            actorname[c][0] = 0;
            AGAIN1:
            if (!fgets(actorname[c], 80, names)) break;
            if (actorname[c][0] == ' ') goto AGAIN1;
            if (actorname[c][0] == ';') goto AGAIN1;
            if (strlen(actorname[c]) > 1) actorname[c][strlen(actorname[c])-1] = 0; /* Delete newline */
            if (!strcmp(actorname[c], "end")) break;
        }
        for (int c = 0; c < 128; c++)
        {
            itemname[c] = (char*)malloc(80);
            itemname[c][0] = 0;
            AGAIN2:
            if (!fgets(itemname[c], 80, names)) break;
            if (itemname[c][0] == ' ') goto AGAIN2;
            if (itemname[c][0] == ';') goto AGAIN2;
            if (strlen(itemname[c]) > 1) itemname[c][strlen(itemname[c])-1] = 0; /* Delete newline */
            if (!strcmp(itemname[c], "end")) break;
        }
        fclose(names);
    }

    for (int z = 0; z < NUMZONES; ++z)
        resetzone(zones[z]);

    for (int c = 0; c < NUMCHARSETS; ++c)
        resetcharset(charsets[c]);

    return true;
}

bool confirmquit()
{
    for (;;)
    {
        win_getspeed(70);
        gfx_fillscreen(254);
        printtext_center_color("PRESS Y TO CONFIRM QUIT",screensizey/2 - 10,SPR_FONTS,COL_WHITE);
        printtext_center_color("UNSAVED DATA WILL BE LOST",screensizey/2 + 10,SPR_FONTS,COL_WHITE);
        gfx_updatepage();
        int key = kbd_getascii();
        if (key)
            return (key == 'y');
    }
}

unsigned getcharsprite(char ch)
{
    unsigned num = ch-31;
    if (num >= 64)
        num -= 32;
    if (num > 59)
        num = 32;
    return num;
}

void printtext_color(const char *string, int x, int y, unsigned spritefile, int color)
{
    unsigned char *xlat = colxlattable[color];

    spritefile <<= 16;
    while (*string)
    {
        unsigned num = getcharsprite(*string);
        gfx_drawspritex(x, y, spritefile + num, xlat);
        x += spr_xsize;
        string++;
    }
}

void printtext_center_color(const char *string, int y, unsigned spritefile, int color)
{
    int x = 0;
    const char *stuff = string;
    unsigned char *xlat = colxlattable[color];
    spritefile <<= 16;

    while (*stuff)
    {
        unsigned num = getcharsprite(*stuff);
        gfx_getspriteinfo(spritefile + num);
        x += spr_xsize;
        stuff++;
    }
    x = (screensizex - x) / 2;

    while (*string)
    {
        unsigned num = getcharsprite(*string);
        gfx_drawspritex(x, y, spritefile + num, xlat);
        x += spr_xsize;
        string++;
    }
}

void mouseupdate()
{
    mou_getpos((unsigned*)&mousex, (unsigned*)&mousey);
    prevmouseb = mouseb;
    mouseb = mou_getbuttons();
}

void drawandeditpalette()
{
    unsigned char v;
    int palx = ZOOMSHAPEVIEW*5*8 + 10 + MAXSHAPESIZE*8;
    int paly = 50;
    int ofs = 64;

    Charset& charset = charsets[charsetnum];
    Shape& shape = charset.shapes[shapenum];
    Zone& zone = zones[zonenum];

    unsigned char& chcol = shape.charcolors[esy*MAXSHAPESIZE+esx];
    // Select/edit current color
    if (mouseb & 3)
    {
        unsigned char delta = (mouseb == 2) ? 0x0f : 0x01;

        for (int c = 0; c < 4; ++c)
        {
            if (ismouseinside(palx, paly+c*15, ofs+15, 10))
                ccolor = c;

            if (ismouseinside(palx+ofs, paly+c*15, 15, 10) && !colordelay)
            {
                unsigned char col;

                switch (c)
                {
                case 0:
                    col = zone.bg1 & 0xf;
                    zone.bg1 = ((col+delta) & 0xf) | (zone.bg1 & 0xf0);
                    break;
                case 1:
                    col = zone.bg2 & 0xf;
                    zone.bg2 = ((col+delta) & 0xf) | (zone.bg2 & 0xf0);
                    break;
                case 2:
                    col = zone.bg3 & 0xf;
                    zone.bg3 = ((col+delta) & 0xf) | (zone.bg3 & 0xf0);
                    break;
                case 3:
                    col = chcol;
                    chcol = ((col+delta) & 0xf) | (chcol & 0xf0);
                    charsets[charsetnum].dirty = true;
                    updatelockedmode();
                    break;
                }
            }
        }
    }

    if (key == KEY_M)
    {
        chcol ^= 8;
        if (shiftdown)
            memset(shape.charcolors, chcol, sizeof shape.charcolors);
        charsets[charsetnum].dirty = true;
        updatelockedmode();
    }

    // Swap colors globally
    if (key == KEY_P && shiftdown)
    {
        for (int c = 0; c < 4; ++c)
        {
            if (ismouseinside(palx, paly+c*15, ofs+15, 10) && ccolor != c && ccolor != 3)
                swapcolors(ccolor, c);
        }
    }

    // Select current color by keys
    if (shiftdown && !ctrldown)
    {
        if (key == KEY_1)
            ccolor = 0;
        if (key == KEY_2)
            ccolor = 1;
        if (key == KEY_3)
            ccolor = 2;
        if (key == KEY_4)
            ccolor = 3;
    }

    // Char color direct edit
    if (ctrldown)
    {
        if (key == KEY_0 || key == KEY_8)
        {
            chcol = chcol & 0xf8;
            ccolor = 3;
            if (shiftdown)
                memset(shape.charcolors, chcol, sizeof shape.charcolors);
            charset.dirty = true;
            updatelockedmode();
        }
        if (key == KEY_1)
        {
            chcol = (chcol & 0xf8) + 1;
            ccolor = 3;
            if (shiftdown)
                memset(shape.charcolors, chcol, sizeof shape.charcolors);
            charset.dirty = true;
            updatelockedmode();
        }
        if (key == KEY_2)
        {
            chcol = (chcol & 0xf8) + 2;
            ccolor = 3;
            if (shiftdown)
                memset(shape.charcolors, chcol, sizeof shape.charcolors);
            charset.dirty = true;
            updatelockedmode();
        }
        if (key == KEY_3)
        {
            chcol = (chcol & 0xf8) + 3;
            ccolor = 3;
            if (shiftdown)
                memset(shape.charcolors, chcol, sizeof shape.charcolors);
            charset.dirty = true;
            updatelockedmode();
        }
        if (key == KEY_4)
        {
            chcol = (chcol & 0xf8) + 4;
            ccolor = 3;
            if (shiftdown)
                memset(shape.charcolors, chcol, sizeof shape.charcolors);
            charset.dirty = true;
            updatelockedmode();
        }
        if (key == KEY_5)
        {
            chcol = (chcol & 0xf8) + 5;
            ccolor = 3;
            if (shiftdown)
                memset(shape.charcolors, chcol, sizeof shape.charcolors);
            charset.dirty = true;
            updatelockedmode();
        }
        if (key == KEY_6)
        {
            chcol = (chcol & 0xf8) + 6;
            ccolor = 3;
            if (shiftdown)
                memset(shape.charcolors, chcol, sizeof shape.charcolors);
            charset.dirty = true;
            updatelockedmode();
        }
        if (key == KEY_7)
        {
            chcol = (chcol & 0xf8) + 7;
            ccolor = 3;
            if (shiftdown)
                memset(shape.charcolors, chcol, sizeof shape.charcolors);
            charset.dirty = true;
            updatelockedmode();
        }
    }

    v = (ccolor == 0) ? COL_HIGHLIGHT : COL_WHITE;
    printtext_color("BACK", palx, paly,SPR_FONTS, v);
    v = (ccolor == 1) ? COL_HIGHLIGHT : COL_WHITE;
    printtext_color("MC 1", palx, paly+15,SPR_FONTS, v);
    v = (ccolor == 2) ? COL_HIGHLIGHT : COL_WHITE;
    printtext_color("MC 2", palx, paly+30,SPR_FONTS, v);
    v = (ccolor == 3) ? COL_HIGHLIGHT : COL_WHITE;
    printtext_color("CHAR", palx, paly+45,SPR_FONTS, v);
    printtext_color(chcol < 8 ? "S" : "M", palx+ofs+24, paly+45, SPR_FONTS, COL_WHITE);

    drawcbar(palx+ofs, paly, zone.bg1 & 15);
    drawcbar(palx+ofs, paly+15, zone.bg2 & 15);
    drawcbar(palx+ofs, paly+30, zone.bg3 & 15);
    drawcbar(palx+ofs, paly+45, chcol & 7);
    drawbox(palx+ofs, paly+15*ccolor, 16, 10, 1);
}

void swapcolors(int c1, int c2)
{
    if (c1 == c2)
        return;

    char andtable[4] = {0xfc, 0xf3, 0xcf, 0x3f};

    for (int s = 0; s < NUMSHAPES; ++s)
    {
        Shape& shape = charsets[charsetnum].shapes[s];
        for (int c = 0; c < sizeof shape.chardata; ++c)
        {
            if (shape.charcolors[c/8] < 8)
                continue; // No-op for singlecolor chars

            for (int x = 0; x < 4; x++)
            {
                char bit = (shape.chardata[c] >> (x*2)) & 3;
                if (bit == c1) bit = c2;
                else if (bit == c2) bit = c1;

                shape.chardata[c] &= andtable[x];
                shape.chardata[c] |= (bit << (x*2));
            }

            if (c1 == 3 || c2 == 3)
                shape.charcolors[c/8] = 8;
        }
    }
    charsets[charsetnum].dirty = true;

    for (int z = 0; z < NUMZONES; ++z)
    {
        Zone& zone = zones[z];
        if (zone.charset == charsetnum)
        {
            if ((c1 == 0 && c2 == 1) || (c2 == 0 && c1 == 1))
            {
                unsigned char temp = zone.bg1;
                zone.bg1 = zone.bg2;
                zone.bg2 = temp;
            }
            if ((c1 == 0 && c2 == 2) || (c2 == 0 && c1 == 2))
            {
                unsigned char temp = zone.bg1;
                zone.bg1 = zone.bg3;
                zone.bg3 = temp;
            }
            if ((c1 == 1 && c2 == 2) || (c2 == 1 && c1 == 2))
            {
                unsigned char temp = zone.bg2;
                zone.bg2 = zone.bg3;
                zone.bg3 = temp;
            }
        }
    }
}

void editzonepalette()
{
    int palx = 384;
    int paly = 17*16+8;
    int ofs = 64;
    int rowofs = (editmode == EM_ZONE) ? 15 : 10;

    Zone& zone = zones[zonenum];

    // Select/edit current color
    if (mouseb & 3)
    {
        unsigned char delta = (mouseb == 2) ? 0x0f : 0x01;

        for (int c = 0; c < 3; ++c)
        {
            if (ismouseinside(palx, paly+c*rowofs, ofs+15, 10))
                ccolor = c;

            if (ismouseinside(palx+ofs, paly+c*rowofs, 15, 10) && !colordelay)
            {
                unsigned char col;

                switch (c)
                {
                case 0:
                    col = zone.bg1 & 0xf;
                    zone.bg1 = ((col+delta) & 0xf) | (zone.bg1 & 0xf0);
                    break;
                case 1:
                    col = zone.bg2 & 0xf;
                    zone.bg2 = ((col+delta) & 0xf) | (zone.bg2 & 0xf0);
                    break;
                case 2:
                    col = zone.bg3 & 0xf;
                    zone.bg3 = ((col+delta) & 0xf) | (zone.bg3 & 0xf0);
                    break;
                }
            }
        }
    }

    printtext_color("BACK", palx, paly,SPR_FONTS, COL_WHITE);
    printtext_color("MC 1", palx, paly+rowofs,SPR_FONTS, COL_WHITE);
    printtext_color("MC 2", palx, paly+rowofs*2,SPR_FONTS, COL_WHITE);

    drawcbar(palx+ofs, paly, zone.bg1 & 15);
    drawcbar(palx+ofs, paly+rowofs, zone.bg2 & 15);
    drawcbar(palx+ofs, paly+rowofs*2, zone.bg3 & 15);

    sprintf(textbuffer, "WEAPONSET %X", zone.bg1 >> 4);
    printtext_color(textbuffer, palx, paly+rowofs*3,SPR_FONTS, COL_WHITE);
}


void drawshapeselector()
{
    int selectory = screensizey-64;

    // Shape select
    if (key == KEY_COMMA || (key == KEY_Z && !shiftdown))
        selectshape(shapenum - 1);
    if (key == KEY_COLON || (key == KEY_X && !shiftdown))
        selectshape(shapenum + 1);

    if (shiftdown && key == KEY_Z)
        selectshape(shapenum - 16);
    if (shiftdown && key == KEY_X)
        selectshape(shapenum + 16);

    if (wholescreenshapeselect)
    {
        selectory = 0;
        for (int y = 0; y < 12; ++y)
        {
            for (int x = 0; x < screensizex / 32; ++x)
            {
                int sx = x*32;
                int sy = selectory + y*32;
                unsigned num = (oss + x + y * 16) & (NUMSHAPES-1);
                drawshapelimit(sx, sy, 4, 4, charsets[charsetnum].shapes[num], zones[zonenum]);
                if (win_keystate[KEY_I] && editmode != EM_ACTORS)
                    drawshapeblockinfolimit(sx, sy, 4, 4, charsets[charsetnum].shapes[num]);
                sprintf(textbuffer, "%d", num);
                printtext_color(textbuffer, sx, sy+24, SPR_FONTS, COL_WHITE);

                if (ismouseinside(sx, sy, 32, 32))
                {
                    if (mouseb || key == KEY_G || key == KEY_SPACE)
                        selectshape(num);
                }
            }
        }

        for (int y = 0; y < 12; ++y)
        {
            for (int x = 0; x < screensizex / 32; ++x)
            {
                int sx = x*32;
                int sy = selectory + y*32;
                unsigned num = (oss + x + y * 16) & (NUMSHAPES-1);
                if (num == shapenum)
                    drawbox(sx-1, sy-1, 34, 34, 1);
            }
        }

        return;
    }

    for (int y = 0; y < 2; ++y)
    {
        for (int x = 0; x < screensizex / 32; ++x)
        {
            int sx = x*32;
            int sy = selectory + y*32;
            unsigned num = (oss + x + y * 16) & (NUMSHAPES-1);
            drawshapelimit(sx, sy, 4, 4, charsets[charsetnum].shapes[num], zones[zonenum]);
            if (win_keystate[KEY_I] && editmode != EM_ACTORS)
                drawshapeblockinfolimit(sx, sy, 4, 4, charsets[charsetnum].shapes[num]);
            sprintf(textbuffer, "%d", num);
            printtext_color(textbuffer, sx, sy+24, SPR_FONTS, COL_WHITE);

            if (ismouseinside(sx, sy, 32, 32))
            {
                if (mouseb || key == KEY_G || key == KEY_SPACE)
                    selectshape(num);
                // Char copy/paste directly in the shape selector
                if (!shiftdown && editmode == EM_SHAPE)
                {
                    if (key == KEY_P)
                    {
                        int cx = (mousex&31)/8;
                        int cy = ((mousey-selectory)%31)/8;
                        memcpy(charcopybuffer, &charsets[charsetnum].shapes[num].chardata[(cy*MAXSHAPESIZE+cx)*8], 8);
                        charcopycolor = charsets[charsetnum].shapes[num].charcolors[cy*MAXSHAPESIZE+cx];
                        grabmode = 0;
                    }
                    if (key == KEY_T && grabmode != 3)
                    {
                        int cx = (mousex&31)/8;
                        int cy = ((mousey-selectory)%31)/8;
                        memcpy(&charsets[charsetnum].shapes[num].chardata[(cy*MAXSHAPESIZE+cx)*8], charcopybuffer,  8);
                        charsets[charsetnum].shapes[num].charcolors[cy*MAXSHAPESIZE+cx] = charcopycolor;
                        charsets[charsetnum].dirty = true;
                    }
                }
            }
        }
    }

    for (int y = 0; y < 2; ++y)
    {
        for (int x = 0; x < screensizex / 32; ++x)
        {
            int sx = x*32;
            int sy = selectory + y*32;
            unsigned num = (oss + x + y * 16) & (NUMSHAPES-1);
            if (num == shapenum)
                drawbox(sx-1, sy-1, 34, 34, 1);
        }
    }
}

void drawc64charset()
{
    const Charset& charset = charsets[charsetnum];
    int charsety = screensizey-64-8-64;
    for (int c = 0; c < 256; ++c)
    {
        drawchar((c&31)*8, charsety + (c/32)*8, &charset.chardata[c*8], charset.charcolors[c], zones[zonenum]);
    }

    sprintf(textbuffer, "USED CHARS %d", charset.usedchars);
    printtext_color(textbuffer, 32*8+10, charsety, SPR_FONTS, COL_WHITE);
    sprintf(textbuffer, "USED BLOCKS %d", charset.usedblocks);
    printtext_color(textbuffer, 32*8+10, charsety + 15, SPR_FONTS, COL_WHITE);
    if (charset.errored)
        printtext_color("ERROR! TOO MANY CHARS/BLOCKS!", 32*8+10, charsety + 45, SPR_FONTS, COL_WHITE);

}

void drawandeditshape()
{
    int shapex = ZOOMSHAPEVIEW*40 + 10;
    int textx = shapex + MAXSHAPESIZE*8;

    if (shapeusedirty)
        updateshapeuse();

    // Zone select
    if (key == KEY_Q)
    {
        zonenum--;
        zonenum &= NUMZONES-1;
    }
    if (key == KEY_W)
    {
        zonenum++;
        zonenum &= NUMZONES-1;
    }
    // Charset select
    if (key == KEY_TAB)
    {
        if (charsets[charsetnum].dirty && !lockedmode)
            packcharset(charsets[charsetnum]);

        if (!shiftdown)
            ++charsetnum;
        else
            --charsetnum;
        charsetnum &= NUMCHARSETS-1;
    }

    Charset& charset = charsets[charsetnum];
    Shape& shape = charset.shapes[shapenum];

    if (key == KEY_L)
    {
        lockedmode = !lockedmode;
        if (lockedmode && charset.dirty)
            packcharset(charset);
    }

    // Shape size
    if (ctrldown && !shiftdown)
    {
        if (key == KEY_UP && shape.sy > 2)
        {
            shape.sy -= 2;
            charset.dirty = true;
        }
        if (key == KEY_DOWN && shape.sy < MAXSHAPESIZE)
        {
            shape.sy += 2;
            charset.dirty = true;
        }
        if (key == KEY_LEFT && shape.sx > 2)
        {
            shape.sx -= 2;
            charset.dirty = true;
        }
        if (key == KEY_RIGHT && shape.sx < MAXSHAPESIZE)
        {
            shape.sx += 2;
            charset.dirty = true;
        }
    }

    // Move the zoomed window
    if (!ctrldown && !shiftdown)
    {
        if (key == KEY_UP && osy > 0)
            --osy;
        if (key == KEY_DOWN && osy < MAXSHAPESIZE - ZOOMSHAPEVIEW)
            ++osy;
        if (key == KEY_LEFT && osx > 0)
            --osx;
        if (key == KEY_RIGHT && osx < MAXSHAPESIZE - ZOOMSHAPEVIEW)
            ++osx;
    }

    // Validate zoomed window pos against current shape
    if (osx + ZOOMSHAPEVIEW > shape.sx)
        osx = shape.sx - ZOOMSHAPEVIEW;
    if (osy + ZOOMSHAPEVIEW > shape.sy)
        osy = shape.sy - ZOOMSHAPEVIEW;
    if (osx < 0)
        osx = 0;
    if (osy < 0)
        osy = 0;

    // Validate edit char position
    if (esx >= shape.sx)
        esx = shape.sx - 1;
    if (esy >= shape.sy)
        esy = shape.sy - 1;

    // Pixel setting
    if (((mouseb) || key == KEY_BACKSPACE) && mousex < ZOOMSHAPEVIEW*40 && mousey < ZOOMSHAPEVIEW*40)
    {
        int ecx = mousex/40 + osx;
        int ecy = mousey/40 + osy;
        if (ecx < shape.sx && ecy < shape.sy)
        {
            esx = ecx;
            esy = ecy;
            int y = (mousey%40)/5;
            int x = (mousex%40)/5;
            unsigned char& chcol = shape.charcolors[esy*MAXSHAPESIZE+esx];
            unsigned char* chardata = &shape.chardata[(esy*MAXSHAPESIZE+esx)*8];
            unsigned char& charbyte = shape.chardata[(esy*MAXSHAPESIZE+esx)*8+y];

            // Draw / erase
            if (!shiftdown)
            {
                if (mouseb == 1)
                {
                    if ((chcol & 15) < 8)
                        setsinglecol(charbyte, x, 1);
                    else
                        setmulticol(charbyte, x, ccolor);
                    charset.dirty = true;
                    updatelockedmode();
                }

                if ((mouseb == 2) || key == KEY_BACKSPACE)
                {
                    if ((chcol & 15) < 8)
                        setsinglecol(charbyte, x, 0);
                    else
                        setmulticol(charbyte, x, 0);
                    charset.dirty = true;
                    updatelockedmode();
                }
            }
        }
    }

    // Char edit by key
    {
        int ecx = mousex/40 + osx;
        int ecy = mousey/40 + osy;
        int x = (mousex%40)/5;
        int y = (mousey%40)/5;
        
        // Allow editing/pasting also over the unzoomed shape
        if (mousex >= shapex)
        {
            ecx = (mousex-shapex)/8;
            ecy = mousey/8;
            x = (mousex-shapex)%8;
            y = mousey%8;
        }

        if (ecx < shape.sx && ecy < shape.sy)
        {
            unsigned char* chardata = &shape.chardata[(ecy*MAXSHAPESIZE+ecx)*8];
            unsigned char& chcol = shape.charcolors[ecy*MAXSHAPESIZE+ecx];
            unsigned char& charbyte = shape.chardata[(ecy*MAXSHAPESIZE+ecx)*8+y];

            // Move char selection (redundant, but needed in case is over unzoomed shape)
            if (mouseb == 4)
            {
                esx = ecx;
                esy = ecy;
            }

            // Color pick by key
            if (key == KEY_G)
            {
                esx = ecx;
                esy = ecy;
                if ((chcol & 15) < 8)
                    ccolor = ((charbyte << x) & 0x80) ? 3 : 0;
                else
                    ccolor = ((charbyte << (x & 6)) & 0xc0) >> 6;
            }

            // Copy/paste
            if (key == KEY_P)
            {
                if (grabmode != 2)
                {
                    esx = ecx;
                    esy = ecy;
                    grabmode = 0;
                    memcpy(charcopybuffer, chardata, 8);
                    charcopycolor = chcol;
                }
                else
                {
                    shapecopybuffer.sx = grabx2-grabx1+1;
                    shapecopybuffer.sy = graby2-graby1+1;
                    for (int cy = graby1; cy <= graby2; ++cy)
                    {
                        for (int cx = grabx1; cx <= grabx2; ++cx)
                        {
                            for (int ccy = 0; ccy < 8; ++ccy)
                            {
                                shapecopybuffer.chardata[((cy-graby1)*MAXSHAPESIZE+(cx-grabx1))*8+ccy] =
                                    shape.chardata[(cy*MAXSHAPESIZE+cx)*8+ccy];
                            }
                            shapecopybuffer.charcolors[(cy-graby1)*MAXSHAPESIZE+(cx-grabx1)] =
                                shape.charcolors[cy*MAXSHAPESIZE+cx];
                        }
                    }

                    // Copy blockinfos if applicable
                    if (!(grabx1 & 1) && !(graby1 & 1))
                    {
                        scbblockinfos = true;
                        for (int cy = graby1; cy <= graby2; cy += 2)
                        {
                            for (int cx = grabx1; cx <= grabx2; cx += 2)
                            {
                                shapecopybuffer.blockinfos[(cy-graby1)/2*MAXSHAPEBLOCKSIZE+(cx-grabx1)/2] =
                                    shape.blockinfos[cy/2*MAXSHAPEBLOCKSIZE+cx/2];
                            }
                        }
                    }
                    else
                        scbblockinfos = false;

                    grabmode = 3;
                }
            }
            if (key == KEY_T)
            {
                if (grabmode != 3)
                {
                    esx = ecx;
                    esy = ecy;
                    grabmode = 0;
                    memcpy(chardata, charcopybuffer, 8);
                    chcol = charcopycolor;
                }
                else
                {
                    for (int cy = 0; cy < shapecopybuffer.sy; ++cy)
                    {
                        for (int cx = 0; cx < shapecopybuffer.sx; ++cx)
                        {
                            if (cx+ecx < shape.sx && cy+ecy < shape.sy)
                            {
                                for (int ccy = 0; ccy < 8; ++ccy)
                                {
                                    shape.chardata[((cy+ecy)*MAXSHAPESIZE+(cx+ecx))*8+ccy] =
                                        shapecopybuffer.chardata[(cy*MAXSHAPESIZE+cx)*8+ccy];
                                }
                            }
                            shape.charcolors[(cy+ecy)*MAXSHAPESIZE+(cx+ecx)] =
                                shapecopybuffer.charcolors[cy*MAXSHAPESIZE+cx];
                        }
                    }
                    if (scbblockinfos && !(ecx & 1) && !(ecy & 1))
                    {
                        for (int cy = 0; cy < shapecopybuffer.sy; cy += 2)
                        {
                            for (int cx = 0; cx < shapecopybuffer.sx; cx += 2)
                            {
                                if (cx+ecx < shape.sx && cy+ecy < shape.sy)
                                {
                                    shape.blockinfos[(cy+ecy)/2*MAXSHAPEBLOCKSIZE+(cx+ecx)/2] =
                                        shapecopybuffer.blockinfos[cy/2*MAXSHAPEBLOCKSIZE+cx/2];
                                }
                            }
                        }
                    }
                }

                charset.dirty = true;
            }

            // Rectangle select (grab)
            if ((shiftdown && (mouseb & 3) && !prevmouseb) || key == KEY_SPACE)
            {
                if (grabmode >= 2)
                    grabmode = 0;
                if (grabmode == 0)
                {
                    grabmode = 1;
                    grabx1 = ecx;
                    graby1 = ecy;
                }
                else if (grabmode == 1)
                {
                    if (ecx >= grabx1 && ecy >= graby1)
                    {
                        grabx2 = ecx;
                        graby2 = ecy;
                        grabmode = 2;
                    }
                    else
                    {
                        grabx1 = ecx;
                        graby1 = ecy;
                    }
                }
            }
        }
        else
        {
            int charsety = screensizey-64-8-64;
            if (mousey >= charsety && mousey < charsety+8*8 && mousex < 32*8)
            {
                int c = ((mousey - charsety)/8)*32 + mousex/8;

                int charsety = screensizey-64-8-64;
                sprintf(textbuffer, "CHAR %d", c);
                printtext_color(textbuffer, 32*8+10, charsety+30, SPR_FONTS, COL_WHITE);

                // Char copy from the C64 charset
                if (key == KEY_P)
                {
                    memcpy(charcopybuffer, &charset.chardata[c*8], 8);
                    charcopycolor = charset.charcolors[c];
                    grabmode = 0;
                }
                // Seek to first shape using the char
                if (key == KEY_G)
                {
                    bool found = false;
                    for (int s = 0; !found && s < NUMSHAPES; ++s)
                    {
                        for (int cy = 0; !found && cy < charset.shapes[s].sy; ++cy)
                        {
                            for (int cx = 0; !found && cx < charset.shapes[s].sx; ++cx)
                            {
                                if (charset.shapechars[s][cy*MAXSHAPESIZE+cx] == c)
                                {
                                    selectshape(s);
                                    found = true;
                                }
                            }
                        }
                    }
                }
            }
        }

        // Manipulations operating on the last selected char
        if (esx < shape.sx && esy < shape.sy)
        {
            unsigned char* chardata = &shape.chardata[(esy*MAXSHAPESIZE+esx)*8];
            unsigned char& chcol = shape.charcolors[esy*MAXSHAPESIZE+esx];

            // Reverse
            if (key == KEY_R)
            {
                for (int cy = 0; cy < 8; ++cy)
                    chardata[cy] ^= 0xff;

                charset.dirty = true;
                updatelockedmode();
            }
            // Clear
            if (key == KEY_C && !shiftdown)
            {
                for (int cy = 0; cy < 8; ++cy)
                    chardata[cy] = 0;

                charset.dirty = true;
                updatelockedmode();
            }
            // Fill with bitcombo
            if (key == KEY_F && !shiftdown)
            {
                if (ccolor == 1 || ccolor == 2)
                    chcol |= 8;
                unsigned char fillbyte = ccolor | (ccolor << 2) | (ccolor << 4) | (ccolor << 6);
                for (int cy = 0; cy < 8; ++cy)
                    chardata[cy] = fillbyte;

                charset.dirty = true;
                updatelockedmode();
            }
            // Bit manipulations
            if (key == KEY_V)
            {
                int c,y,x;
                char andtable[4] = {0xfc, 0xf3, 0xcf, 0x3f};
                for (y = 0; y < 8; y++)
                {
                    for (x = 0; x < 4; x++)
                    {
                        char bit = (chardata[y] >> (x*2)) & 3;
                        if (!shiftdown)
                        {
                            if (bit == 1) bit = 2;
                            else if (bit == 2) bit = 1;
                        }
                        else
                        {
                            if (bit == 1) bit = 3;
                            else if (bit == 3) bit = 1;
                        }
                        chardata[y] &= andtable[x];
                        chardata[y] |= (bit << (x*2));
                    }
                }

                charset.dirty = true;
                updatelockedmode();
            }
            if (key == KEY_B)
            {
                int c,y,x;
                char andtable[4] = {0xfc, 0xf3, 0xcf, 0x3f};
                for (y = 0; y < 8; y++)
                {
                    for (x = 0; x < 4; x++)
                    {
                        char bit = (chardata[y] >> (x*2)) & 3;
                        if (!shiftdown)
                        {
                            if (bit == 2) bit = 3;
                            else if (bit == 3) bit = 2;
                        }
                        else
                        {
                            if (bit == 2) bit = 0;
                            else if (bit == 0) bit = 2;
                        }
                        chardata[y] &= andtable[x];
                        chardata[y] |= (bit << (x*2));
                    }
                }

                charset.dirty = true;
                updatelockedmode();
            }
            if (key == KEY_N)
            {
                int c,y,x;
                char andtable[4] = {0xfc, 0xf3, 0xcf, 0x3f};
                for (y = 0; y < 8; y++)
                {
                    for (x = 0; x < 4; x++)
                    {
                        char bit = (chardata[y] >> (x*2)) & 3;
                        if (!shiftdown)
                        {
                            if (bit == 0) bit = 3;
                            else if (bit == 3) bit = 0;
                        }
                        else
                        {
                            if (bit == 0) bit = 1;
                            else if (bit == 1) bit = 0;
                        }
                        chardata[y] &= andtable[x];
                        chardata[y] |= (bit << (x*2));
                    }
                }

                charset.dirty = true;
                updatelockedmode();
            }

            // Char scrolling
            if (shiftdown && !ctrldown)
            {
                if (key == KEY_LEFT)
                {
                    scrollcharleft(chardata, chcol);
                    charset.dirty = true;
                    updatelockedmode();
                }
                if (key == KEY_RIGHT)
                {
                    scrollcharright(chardata, chcol);
                    charset.dirty = true;
                    updatelockedmode();
                }
                if (key == KEY_UP)
                {
                    scrollcharup(chardata, chcol);
                    charset.dirty = true;
                    updatelockedmode();
                }
                if (key == KEY_DOWN)
                {
                    scrollchardown(chardata, chcol);
                    charset.dirty = true;
                    updatelockedmode();
                }
            }
        }
    }

    // Blockinfo edit
    {
        unsigned char& blockinfo = shape.blockinfos[esy/2*MAXSHAPEBLOCKSIZE+esx/2];
        unsigned char oldblockinfo = blockinfo;
        if (!shiftdown && !ctrldown)
        {
            if (key == KEY_1) blockinfo ^= 1;
            if (key == KEY_2) blockinfo ^= 2;
            if (key == KEY_3) blockinfo ^= 4;
            if (key == KEY_4) blockinfo ^= 8;
            if (key == KEY_5) blockinfo ^= 16;
            if (key == KEY_6) blockinfo ^= 32;
            if (key == KEY_7) blockinfo ^= 64;
            if (key == KEY_8) blockinfo ^= 128;
        }
        if (!shiftdown && !ctrldown && key == KEY_S)
            blockinfo += 32; // Slopebits
        if (shiftdown && !ctrldown && key == KEY_S)
            blockinfo -= 32; // Slopebits
        if (blockinfo != oldblockinfo)
            charset.dirty = true;

        printtext_color("BLKINFO", textx, 110, SPR_FONTS, COL_WHITE);

        int blockinfox = textx+64;
        int blockinfoy = 110;

        drawfilledbox(blockinfox, blockinfoy, 16, 16, 6);

        for (int x = 0; x < 8; x++)
        {
            if ((blockinfo >> (7-x)) & 1)
                gfx_drawsprite(blockinfox+24+x*4, blockinfoy, 0x00000023);
            else
                gfx_drawsprite(blockinfox+24+x*4, blockinfoy, 0x00000024);
        }

        drawblockinfo(blockinfox, blockinfoy, blockinfo);
    }

    // Shape copy/paste
    if (key == KEY_P && shiftdown)
    {
        grabmode = 3;
        shapecopybuffer = shape;
        scbblockinfos = true;
    }
    if (key == KEY_T && shiftdown && !(shapecopybuffer.sx & 1) && !(shapecopybuffer.sy & 1))
    {
        if (grabmode != 3)
            grabmode = 0;
        shape = shapecopybuffer;
        charset.dirty = true;
    }
    // Whole shape clear
    if (key == KEY_C && shiftdown)
    {
        memset(shape.chardata, 0, sizeof shape.chardata);
        charset.dirty = true;
    }
    // Shape reset
    if ((key == KEY_BACKSPACE) && shiftdown)
    {
        resetshape(shape);
        charset.dirty = true;
    }
    
    // Shape insert/delete
    if (key == KEY_DEL && shiftdown)
        deleteshape(shapenum);
    if (key == KEY_INS && shiftdown)
        insertshape();

    // Charset insert
    if (key == KEY_I && shiftdown && ctrldown)
        insertcharset();

    // Whole shape fill
    if (key == KEY_F && shiftdown)
    {
        unsigned char fillbyte = ccolor | (ccolor << 2) | (ccolor << 4) | (ccolor << 6);
        for (int cy = 0; cy < shape.sy; ++cy)
        {
            for (int cx = 0; cx < shape.sx; ++cx)
                memset(&shape.chardata[(cy*MAXSHAPESIZE+cx)*8], fillbyte, 8);
        }
        for (int cc = 0; cc < MAXSHAPESIZE*MAXSHAPESIZE; ++cc)
            shape.charcolors[cc] |= 8;

        charset.dirty = true;
    }

    drawzoomedshape(0, 0, osx, osy, ZOOMSHAPEVIEW, ZOOMSHAPEVIEW, shape, zones[zonenum]);

    // Char / block selection boxes in the zoomed view
    int eosx = esx - osx;
    int eosy = esy - osy;
    int eobx = (esx&0xfe) - osx;
    int eoby = (esy&0xfe) - osy;
    if (eobx < ZOOMSHAPEVIEW && eoby < ZOOMSHAPEVIEW)
        drawbox(eobx*40-1, eoby*40-1, 81, 81, 7);
    if (eosx >= 0 && eosy >= 0 && eosx < ZOOMSHAPEVIEW && eosy < ZOOMSHAPEVIEW)
        drawbox(eosx*40-1, eosy*40-1, 41, 41, 1);

    // Grab markers
    if (grabmode == 1 || grabmode == 2)
    {
        int mx = grabx1-osx;
        int my = graby1-osy;
        if (mx >= 0 && mx < ZOOMSHAPEVIEW && my >= 0 && my < ZOOMSHAPEVIEW)
        {
            gfx_line(mx*40,my*40,mx*40+39,my*40,1);
            gfx_line(mx*40,my*40+1,mx*40+39,my*40+1,1);
            gfx_line(mx*40,my*40,mx*40,my*40+39,1);
            gfx_line(mx*40+1,my*40,mx*40+1,my*40+39,1);
        }
    }
    if (grabmode == 2)
    {
        int mx = grabx2-osx;
        int my = graby2-osy;
        if (mx >= 0 && mx < ZOOMSHAPEVIEW && my >= 0 && my < ZOOMSHAPEVIEW)
        {
            gfx_line(mx*40+38,my*40,mx*40+38,my*40+39,1);
            gfx_line(mx*40+39,my*40,mx*40+39,my*40+39,1);
            gfx_line(mx*40,my*40+38,mx*40+39,my*40+38,1);
            gfx_line(mx*40,my*40+39,mx*40+39,my*40+39,1);
        }
    }

    drawshape(shapex, 0, shape, zones[zonenum]);

    // Whole shape blockinfo debug
    if (win_keystate[KEY_I])
        drawshapeblockinfo(shapex, 0, shape);

    // Visualize zoomed view edges
    drawbox(shapex+osx*8-1, osy*8-1, ZOOMSHAPEVIEW*8+2, ZOOMSHAPEVIEW*8+2, 1);

    sprintf(textbuffer, "SHAPE   %d (%dx%d)", shapenum, shape.sx/2, shape.sy/2);
    printtext_color(textbuffer, textx, 0, SPR_FONTS, COL_WHITE);
    sprintf(textbuffer, "CHARSET %d", charsetnum);
    printtext_color(textbuffer, textx, 15, SPR_FONTS, COL_WHITE);
    sprintf(textbuffer, "ZONE    %d", zonenum);
    printtext_color(textbuffer, textx, 30, SPR_FONTS, COL_WHITE);

    sprintf(textbuffer, "USES    %d", shape.usecount);
    printtext_color(textbuffer, textx, 130, SPR_FONTS, COL_WHITE);

    if (lockedmode)
        printtext_color("LOCKED EDIT", shapex, 130, SPR_FONTS, COL_WHITE);

    // Tiling test
    if (shape.sx <= 4 && shape.sy <= 4)
    {
        drawshape(textx, 145, shape, zones[zonenum]);
        drawshape(textx+shape.sx*8, 145, shape, zones[zonenum]);
        drawshape(textx, 145+shape.sy*8, shape, zones[zonenum]);
        drawshape(textx+shape.sx*8, 145+shape.sy*8, shape, zones[zonenum]);
    }

    // Pack charset when timer expired
    if (chardirtytimer >= 10)
    {
        chardirtytimer = 0;
        if (charset.dirty && !lockedmode)
            packcharset(charset);
    }
}

void drawcbar(int x, int y, unsigned char col)
{
    drawfilledbox(x, y, 16, 10, col);
}

void drawbox(int x, int y, int sx, int sy, unsigned char col)
{
    gfx_line(x, y, x+sx-1, y, col);
    gfx_line(x, y+sy-1, x+sx-1, y+sy-1, col);
    gfx_line(x, y, x, y+sy-1, col);
    gfx_line(x+sx-1, y, x+sx-1, y+sy-1, col);
}

void drawfilledbox(int x, int y, int sx, int sy, unsigned char col)
{
    for (int cy = y; cy < y+sy; ++cy)
        gfx_line(x, cy, x+sx-1, cy, col);
}

bool ismouseinside(int x, int y, int sx, int sy)
{
    return mousex >= x && mousey >= y && mousex < x+sx & mousey < y+sy;
}

int inputtext(char *buffer, int maxlength)
{
    int len = strlen(buffer);
    int k;

    ascii = kbd_getascii();
    k = ascii;

    if (!k)
        return 0;
    if (k == 27)
        return -1;
    if (k == 13)
        return 1;

    if (k >= 32)
    {
        if (len < maxlength-1)
        {
            buffer[len] = k;
            buffer[len+1] = 0;
        }
    }

    if ((k == 8) && (len > 0))
        buffer[len-1] = 0;

    return 0;
}

void drawchar(int x, int y, const unsigned char* data, unsigned char color, const Zone& zone)
{
    if (x < 0 || x >= screensizex || y < 0 || y >= screensizey)
        return;

    unsigned char *destptr = &gfx_vscreen[y*screensizex + x];
    drawchardest(destptr, screensizex, data, color, zone);
}

void drawchardest(unsigned char* dest, int modulo, const unsigned char* data, unsigned char color, const Zone& zone)
{
    for (int cy = 0; cy < 8; ++cy)
    {
        if (color >= 8)
        {
            for (int cx = 0; cx < 8; cx += 2)
            {
                unsigned char bits = (*data >> (6-cx)) & 3;
                switch (bits)
                {
                case 0:
                    dest[cx] = zone.bg1 & 15;
                    dest[cx+1] = zone.bg1 & 15;
                    break;
                case 1:
                    dest[cx] = zone.bg2 & 15;
                    dest[cx+1] = zone.bg2 & 15;
                    break;
                case 2:
                    dest[cx] = zone.bg3 & 15;
                    dest[cx+1] = zone.bg3 & 15;
                    break;
                case 3:
                    dest[cx] = color & 7;
                    dest[cx+1] = color & 7;
                    break;
                }
            }
        }
        else
        {
            for (int cx = 0; cx < 8; ++cx)
            {
                if ((*data >> (7-cx)) & 1)
                    dest[cx] = color;
                else
                    dest[cx] = zone.bg1 & 15;
            }
        }

        dest += modulo;
        ++data;
    }
}

void drawcharsmall(int x, int y, const unsigned char* data, unsigned char color, const Zone& zone)
{
    for (int cy = 0; cy < 8; cy += 4)
    {
        if (color >= 8)
        {
            for (int cx = 0; cx < 8; cx += 4)
            {
                unsigned char bits = (*data >> (6-cx)) & 3;
                switch (bits)
                {
                case 0:
                    gfx_plot(x+cx/4, y, zone.bg1 & 15);
                    break;
                case 1:
                    gfx_plot(x+cx/4, y, zone.bg2 & 15);
                    break;
                case 2:
                    gfx_plot(x+cx/4, y, zone.bg3 & 15);
                    break;
                case 3:
                    gfx_plot(x+cx/4, y, color & 7);
                    break;
                }
            }
        }
        else
        {
            for (int cx = 0; cx < 8; cx += 4)
            {
                if ((*data >> (7-cx)) & 1)
                    gfx_plot(x+cx/4, y, color);
                else
                    gfx_plot(x+cx/4, y, zone.bg1 & 15);
            }
        }

        ++y;
        data += 4;
    }
}


void drawzoomedchar(int x, int y, const unsigned char* data, unsigned char color, const Zone& zone)
{
    for (int cy = 0; cy < 8; ++cy)
    {
        if (color >= 8)
        {
            for (int cx = 0; cx < 8; cx += 2)
            {
                unsigned char bits = (*data >> (6-cx)) & 3;
                unsigned char c;
                switch (bits)
                {
                case 0:
                    c = zone.bg1 & 15;
                    break;
                case 1:
                    c = zone.bg2 & 15;
                    break;
                case 2:
                    c = zone.bg3 & 15;
                    break;
                case 3:
                    c = color & 7;
                    break;
                }

                gfx_drawsprite(x+cx*5,y+cy*5,0x00000011+c);
            }
        }
        else
        {
            for (int cx = 0; cx < 8; ++cx)
            {
                unsigned char c;
                if ((*data >> (7-cx)) & 1)
                    c = color & 7;
                else
                    c = zone.bg1 & 15;

                gfx_drawsprite(x+cx*5,y+cy*5,0x00000001+c);
            }
        }
        ++data;
    }
}

void drawshape(int x, int y, const Shape& shape, const Zone& zone)
{
    for (int cy = 0; cy < shape.sy; ++cy)
    {
        for (int cx = 0; cx < shape.sx; ++cx)
            drawchar(x+cx*8, y+cy*8, &shape.chardata[(cy*MAXSHAPESIZE+cx)*8], shape.charcolors[cy*MAXSHAPESIZE+cx], zone);
    }
}

void drawshapeblockinfo(int x, int y, const Shape& shape)
{
    for (int cy = 0; cy < shape.sy/2; ++cy)
    {
        for (int cx = 0; cx < shape.sx/2; ++cx)
            drawblockinfo(x+cx*16, y+cy*16, shape.blockinfos[cy*MAXSHAPEBLOCKSIZE+cx]);
    }
}

void drawshapeblockinfolimit(int x, int y, int lx, int ly, const Shape& shape)
{
    for (int cy = 0; cy < shape.sy/2 && cy < ly/2; ++cy)
    {
        for (int cx = 0; cx < shape.sx/2 && cx < lx/2; ++cx)
            drawblockinfo(x+cx*16, y+cy*16, shape.blockinfos[cy*MAXSHAPEBLOCKSIZE+cx]);
    }
}

void drawshapelimit(int x, int y, int lx, int ly, const Shape& shape, const Zone& zone)
{
    for (int cy = 0; cy < shape.sy && cy < ly; ++cy)
    {
        for (int cx = 0; cx < shape.sx && cx < lx; ++cx)
            drawchar(x+cx*8, y+cy*8, &shape.chardata[(cy*MAXSHAPESIZE+cx)*8], shape.charcolors[cy*MAXSHAPESIZE+cx], zone);
    }
}

void drawzoomedshape(int x, int y, int ox, int oy, int sx, int sy, const Shape& shape, const Zone& zone)
{
    for (int cy = 0; cy < sy; ++cy)
    {
        for (int cx = 0; cx < sx; ++cx)
        {
            if (cx+ox >= shape.sx || cy+oy >= shape.sy)
                continue;

            drawzoomedchar(x+cx*8*5, y+cy*8*5, &shape.chardata[((cy+oy)*MAXSHAPESIZE+(cx+ox))*8], shape.charcolors[(cy+oy)*MAXSHAPESIZE+(cx+ox)], zone);
        }
    }
}

void drawblockinfo(int x, int y, unsigned char blockinfo)
{
    if (blockinfo & 3)
    {
        int slopeindex = (blockinfo >> 5) << 4;
        for (int cx = 0; cx < 16; ++cx)
        {
            int slopey = slopetbl[slopeindex+cx]/8;
            if (blockinfo & 2)
                gfx_line(x+cx,y+slopey,x+cx,y+15, 2);
            if (blockinfo & 1)
                gfx_plot(x+cx,y+slopey,1);
        }
    }
    if (blockinfo & 4)
    {
        gfx_line(x+2,y,x+2,y+15,1);
        gfx_line(x+13,y,x+13,y+15,1);
        gfx_line(x+2,y+4,x+13,y+4,1);
        gfx_line(x+2,y+12,x+13,y+12,1);
    }
    if (blockinfo & 8)
    {
        gfx_line(x,y,x+15,y+15,14);
        gfx_line(x+15,y,x,y+15,14);
    }
    if (blockinfo & 16)
    {
        gfx_line(x+1,y+1,x+1,y+14,1);
        gfx_line(x+1,y+14,x+6,y+14,1);
        if (blockinfo & 128)
        {
            gfx_line(x+9,y+1,x+14,y+1,1);
            gfx_line(x+9,y+14,x+14,y+14,1);
            gfx_line(x+9,y+1,x+14,y+14,1);
        }
    }
}

void drawmap()
{
    for (int z = 0; z < visiblezones.size(); ++z)
    {
        const Zone& zone = zones[visiblezones[z]];
        const Charset& charset = charsets[zone.charset];
        const Shape& fillshape = charset.shapes[zone.fill];

        // Draw fillshape as background
        if (fillshape.sx && fillshape.sy)
        {
            // Fillshape size in blocks
            int fsx = fillshape.sx/2;
            int fsy = fillshape.sy/2;
            for (int cy = 0; cy < zone.sy; cy += fsy)
            {
                for (int cx = 0; cx < zone.sx; cx += fsx)
                    drawzoneshape(cx, cy, zone.fill, false, false, zone);
            }
        }

        // Draw zone tiles (shapes)
        for (int t = 0; t < zone.tiles.size(); ++t)
            drawzoneshape(zone.tiles[t].x, zone.tiles[t].y, zone.tiles[t].s, win_keystate[KEY_S], win_keystate[KEY_I] && editmode != EM_ACTORS, zone);
    }

    if (!win_keystate[KEY_I] || editmode == EM_ACTORS)
    {
        for (int y = 0; y < vsy; ++y)
        {
            for (int x = 0; x < vsx; ++x)
            {
                // Draw screen edge indicators
                if (((x+mapx) % SCREENSIZEX) == 0)
                    gfx_line(x*divisor, y*divisor, x*divisor, y*divisor+divminusone, 12);
                if (((y+mapy) % SCREENSIZEY) == 0)
                    gfx_line(x*divisor, y*divisor, x*divisor+divminusone, y*divisor, 12);
            }
        }
    }

    if (editmode == EM_ZONE)
    {
        // In zoomed out zone edit mode, draw bounds for all zones + level numbers
        if (zoomout)
        {
            for (int c = 0; c < NUMZONES; c++)
            {
                if (zones[c].sx && zones[c].sy)
                {
                    int l,r,u,d;
                    l = zones[c].x - mapx;
                    r = l + zones[c].sx-1;
                    u = zones[c].y - mapy;
                    d = u + zones[c].sy-1;
                    l *= divisor;
                    r *= divisor;
                    r += divisor;
                    u *= divisor;
                    d *= divisor;
                    d += divisor;
                    drawbox(l,u,r-l+1,d-u+1,2);

                    sprintf(textbuffer, "L%d W%X", zones[c].level, zones[c].bg1 >> 4);
                    printtext_color(textbuffer, l+1,u+1, SPR_FONTS, COL_WHITE);
                }
            }
        }
    }

    // Draw current zone edge indicators. In map mode dislocate the left & up edges to make sure no block data is obscured
    if (zones[zonenum].sx && zones[zonenum].sy)
    {
        int l,r,u,d;

        l = zones[zonenum].x - mapx;
        r = l + zones[zonenum].sx-1;
        u = zones[zonenum].y - mapy;
        d = u + zones[zonenum].sy-1;
        l *= divisor;
        r *= divisor;
        r += divisor;
        u *= divisor;
        d *= divisor;
        d += divisor;
        if (editmode == EM_MAP && !zoomout)
        {
            l--;
            u--;
        }
        drawbox(l,u,r-l+1,d-u+1,7);
    }

    // Draw actors & objects (actor mode only)
    if (editmode == EM_ACTORS)
    {
        for (int z = 0; z < visiblezones.size(); ++z)
        {
            const Zone& zone = zones[visiblezones[z]];
            for (int c = 0; c < zone.actors.size(); ++c)
            {
                const Actor& actor = zone.actors[c];
                if (actor.x < zone.sx && actor.y < zone.sy)
                {
                    int ax = (actor.x + zone.x)-mapx;
                    int ay = (actor.y + zone.y)-mapy;
                    if (ax >= 0 && ax < vsx && ay >= 0 && ay < vsy)
                    {
                        gfx_line(ax*divisor,ay*divisor,ax*divisor+divisor-1,ay*divisor+(divisor/2-1),1);
                        gfx_line(ax*divisor+divisor-1,ay*divisor,ax*divisor,ay*divisor+(divisor/2-1),1);
                        if (actor.flags & 0x60)
                        {
                            gfx_line(ax*divisor,ay*divisor,ax*divisor+divisor-1,ay*divisor,1);
                            gfx_line(ax*divisor,ay*divisor+(divisor/2-1),ax*divisor+divisor-1,ay*divisor+(divisor/2-1),1);
                            gfx_line(ax*divisor,ay*divisor,ax*divisor,ay*divisor+(divisor/2-1),1);
                            gfx_line(ax*divisor+divisor-1,ay*divisor,ax*divisor+divisor-1,ay*divisor+(divisor/2-1),1);
                        }

                        if (!zoomout)
                        {
                            sprintf(textbuffer, "%02X", actor.t);
                            printtext_color(textbuffer, ax*divisor,ay*divisor+8,SPR_FONTS,COL_NUMBER);
                        }
                    }
                }
            }
            for (int c = 0; c < zone.objects.size(); ++c)
            {
                const Object& object = zone.objects[c];
                if (object.x < zone.sx && object.y < zone.sy)
                {
                    int ox = (object.x + zone.x)-mapx;
                    int oy = (object.y + zone.y)-mapy;
                    if (ox >= 0 && ox < vsx && oy >= 0 && oy < vsy)
                    {
                        gfx_line(ox*divisor,oy*divisor,(ox+object.sx)*divisor-1,oy*divisor,1);
                        gfx_line(ox*divisor,(oy+object.sy)*divisor-1,(ox+object.sx)*divisor-1,(oy+object.sy)*divisor-1,1);
                        gfx_line(ox*divisor,oy*divisor, ox*divisor,(oy+object.sy)*divisor-1,1);
                        gfx_line((ox+object.sx)*divisor-1,oy*divisor, (ox+object.sx)*divisor-1,(oy+object.sy)*divisor-1,1);
                    }
                }
            }
        }
    }

    // Clean up lines that spill to the status area
    drawfilledbox(0, vsy*divisor, screensizex, screensizey-vsy*divisor, 254);

    // Grab markers
    if (mapgrabmode == 1 || mapgrabmode == 2)
    {
        int mx = mapgrabx1-mapx;
        int my = mapgraby1-mapy;
        if (mx >= 0 && mx < vsx && my >= 0 && my < vsy)
        {
            mx *= divisor;
            my *= divisor;
            gfx_line(mx,my,mx+divminusone,my,1);
            gfx_line(mx,my+1,mx+divminusone,my+1,1);
            gfx_line(mx,my,mx,my+divminusone,1);
            gfx_line(mx+1,my,mx+1,my+divminusone,1);
        }
    }
    if (mapgrabmode == 2)
    {
        int mx = mapgrabx2-mapx;
        int my = mapgraby2-mapy;
        if (mx >= 0 && mx < vsx && my >= 0 && my < vsy)
        {
            mx *= divisor;
            my *= divisor;
            gfx_line(mx,my+divminusone-1,mx+divminusone,my+divminusone-1,1);
            gfx_line(mx,my+divminusone,mx+divminusone,my+divminusone,1);
            gfx_line(mx+divminusone-1,my,mx+divminusone-1,my+divminusone,1);
            gfx_line(mx+divminusone,my,mx+divminusone,my+divminusone,1);
        }
    }

    // Find out zone number within level
    int levelzonenum = -1;
    if (zones[zonenum].sx && zones[zonenum].sy)
    {
        levelzonenum = 0;
        for (int z = 0; z < NUMZONES; ++z)
        {
            if (z == zonenum)
                break;
            if (zones[z].sx && zones[z].sy)
            {
                if (zones[z].level == zones[zonenum].level)
                    ++levelzonenum;
            }
        }
    }

    int texty = 17*16+8;
    int mbx = mousex/divisor+mapx;
    int mby = mousey/divisor+mapy;

    sprintf(textbuffer, "POS  %d,%d", mbx, mby);
    printtext_color(textbuffer, 0, texty, SPR_FONTS, COL_WHITE);
    if (levelzonenum >= 0)
        sprintf(textbuffer, "ZONE %d ID%02X", zonenum, levelzonenum);
    else
        sprintf(textbuffer, "ZONE %d", zonenum);
    printtext_color(textbuffer, 0, texty+15, SPR_FONTS, COL_WHITE);

    if (editmode != EM_ACTORS)
    {
        sprintf(textbuffer, "CHARSET %d", charsetnum);
        printtext_color(textbuffer, 128, texty, SPR_FONTS, COL_WHITE);
        sprintf(textbuffer, "SHAPE   %d", shapenum);
        printtext_color(textbuffer, 128, texty+15, SPR_FONTS, COL_WHITE);

        sprintf(textbuffer, "PLACED %d", zones[zonenum].tiles.size());
        printtext_color(textbuffer, 256, texty, SPR_FONTS, COL_WHITE);
        sprintf(textbuffer, "FILL   %d", zones[zonenum].fill);
        printtext_color(textbuffer, 256, texty+15, SPR_FONTS, COL_WHITE);
    }
}

void movemap()
{
    if (key == KEY_V)
        zoomout = !zoomout;

    divisor = zoomout ? 4 : 16;
    divminusone = divisor-1;
    vsx = screensizex / divisor;
    vsy = 17*16 / divisor;

    if (key == KEY_LEFT)
        mapx -= shiftdown ? SCREENSIZEX : 1;
    if (key == KEY_RIGHT)
        mapx += shiftdown ? SCREENSIZEX : 1;
    if (key == KEY_UP)
        mapy -= shiftdown ? SCREENSIZEY : 1;
    if (key == KEY_DOWN)
        mapy += shiftdown ? SCREENSIZEY : 1;
    if (mapx < 0)
        mapx = 0;
    if (mapy < 0)
        mapy = 0;
    if (mapx + vsx > MAPSIZEX)
        mapx = MAPSIZEX - vsx;
    if (mapy + vsy > MAPSIZEY)
        mapy = MAPSIZEY - vsy;

    int mbx = mousex/divisor+mapx;
    int mby = mousey/divisor+mapy;

    visiblezones.clear();
    for (int z = 0; z < NUMZONES; ++z)
    {
        const Zone& zone = zones[z];
        if (zone.sx && zone.sy)
        {
            if (zone.x < mapx+vsx && zone.y < mapy+vsy && zone.x+zone.sx > mapx && zone.y+zone.sy > mapy)
                visiblezones.push_back(z);
            // Select zone by mouseover (map edit) or by mouseclick (zone edit)
            if ((editmode == EM_MAP || editmode == EM_ACTORS || mouseb) && mousey < 17*16)
            {
                if (isinsidezone(mbx, mby, zone))
                {
                    zonenum = z;
                    charsetnum = zone.charset;
                }
            }
        }
    }
}

void editmap()
{
    int mbx = mousex/divisor+mapx;
    int mby = mousey/divisor+mapy;
    Zone& zone = zones[zonenum];

    if (isinsidezone(mbx, mby, zone))
    {
        // Paint
        if ((mouseb & 1) && !shiftdown)
        {
            if (shapenum != zone.fill)
                addtile(mbx, mby, shapenum, zone);
            // Drawing with fill shape removes
            else
                removetile(mbx, mby, zone);
        }

        // Erase
        if (key == KEY_BACKSPACE || key == KEY_DEL || (mouseb && shiftdown && !prevmouseb))
            removetile(mbx, mby, zone);

        // Pick shape
        if (key == KEY_G)
        {
            int t = findtile(mbx, mby, zone);
            if (t >= 0)
                selectshape(zone.tiles[t].s);
            else
                selectshape(zone.fill);
        }
        
        // Erase all instances of shape
        if (key == KEY_D && shiftdown)
        {
            for (int t = 0; t < zone.tiles.size();)
            {
                if (zone.tiles[t].s == shapenum)
                    zone.tiles.erase(zone.tiles.begin() + t);
                else
                    ++t;
            }
        }

        // Rectangle select (grab)
        if (((mouseb & 2) && !prevmouseb) || key == KEY_SPACE)
        {
            if (mapgrabmode >= 2)
                mapgrabmode = 0;
            else if (mapgrabmode == 0)
            {
                mapgrabmode = 1;
                mapgrabx1 = mbx;
                mapgraby1 = mby;
            }
            else if (mapgrabmode == 1)
            {
                if (mbx >= mapgrabx1 && mby >= mapgraby1)
                {
                    mapgrabx2 = mbx;
                    mapgraby2 = mby;
                    mapgrabmode = 2;
                }
                else
                {
                    mapgrabx1 = mbx;
                    mapgraby1 = mby;
                }
            }
        }
        
        if (mapgrabmode == 2 && key == KEY_P)
        {
            mapgrabmode = 0;
            mapcopybuffer.clear();
            mapcopysx = mapgrabx2-mapgrabx1+1;
            mapcopysy = mapgraby2-mapgraby1+1;
            for (int t = 0; t < zone.tiles.size(); ++t)
            {
                const Tile& tile = zone.tiles[t];
                if (tile.x + zone.x >= mapgrabx1 && tile.x + zone.x <= mapgrabx2 && tile.y + zone.y >= mapgraby1 && tile.y + zone.y <= mapgraby2)
                {
                    Tile copytile;
                    copytile.x = tile.x + zone.x - mapgrabx1;
                    copytile.y = tile.y + zone.y - mapgraby1;
                    copytile.s = tile.s;
                    mapcopybuffer.push_back(copytile);
                }
            }
        }

        if (key == KEY_T)
        {
            // Remove all blocks first, in case there is emptiness
            for (int y = 0; y < mapcopysy; ++y)
            {
                for (int x = 0; x < mapcopysx; ++x)
                    removetile(mbx + x, mby + y, zone);
            }

            for (int t = 0; t < mapcopybuffer.size(); ++t)
            {
                const Tile& tile = mapcopybuffer[t];
                addtile(mbx + tile.x, mby + tile.y, tile.s, zone);
            }
        }

        if (key == KEY_C && shiftdown)
        {
            zone.tiles.clear();
            shapeusedirty = true;
        }

        if (key == KEY_TAB && shiftdown)
        {
            zone.charset--;
            zone.charset &= NUMCHARSETS-1;
            charsetnum = zone.charset;
        }
        if (key == KEY_TAB && !shiftdown)
        {
            zone.charset++;
            zone.charset &= NUMCHARSETS-1;
            charsetnum = zone.charset;
        }
        
        if (key == KEY_F)
        {
            if (!shiftdown)
                zone.fill++;
            else
                zone.fill--;
        }
    }
}

void addtile(int x, int y, unsigned char num, Zone& zone)
{
    x -= zone.x;
    y -= zone.y;
    if (x >= zone.sx || y >= zone.sy)
        return;

    std::map<CoordKey, std::vector<int> > tilecoverage;

    const Charset& charset = charsets[zone.charset];
    const Shape& shape = charset.shapes[num];

    // Build tile coverage map for checking total obscurance as a result of the new add
    for (int t = 0; t < zone.tiles.size(); ++t)
    {
        const Tile& tile = zone.tiles[t];
        const Shape& tileshape = charset.shapes[tile.s];

        for (int cy = 0; cy < tileshape.sy/2; ++cy)
        {
            for (int cx = 0; cx < tileshape.sx/2; ++cx)
                tilecoverage[CoordKey(tile.x+cx, tile.y+cy)].push_back(t);
        }
    }

    Tile newtile;
    newtile.x = x;
    newtile.y = y;
    newtile.s = num;
    int newtileindex = zone.tiles.size();
    zone.tiles.push_back(newtile);
    for (int cy = 0; cy < shape.sy/2; ++cy)
    {
        for (int cx = 0; cx < shape.sx/2; ++cx)
            tilecoverage[CoordKey(x+cx, y+cy)].push_back(newtileindex);
    }

    // Now erase any completely obscured tiles
    for (int t = zone.tiles.size() - 1; t >= 0; --t)
    {
        const Tile& tile = zone.tiles[t];
        const Shape& tileshape = charset.shapes[tile.s];

        bool visible = false;
        for (int cy = 0; cy < tileshape.sy/2 && !visible; ++cy)
        {
            for (int cx = 0; cx < tileshape.sx/2 && !visible; ++cx)
            {
                std::vector<int>& coverage = tilecoverage[CoordKey(tile.x+cx, tile.y+cy)];
                if (coverage.size() && coverage.back() == t)
                    visible = true;
            }
        }
        
        if (!visible)
            zone.tiles.erase(zone.tiles.begin() + t);
    }

    shapeusedirty = true;
}

void removetile(int x, int y, Zone& zone)
{
    int t = findtile(x, y, zone);
    if (t >= 0)
    {
        zone.tiles.erase(zone.tiles.begin() + t);
        shapeusedirty = true;
    }
}

int findtile(int x, int y, const Zone& zone, bool topmost)
{
    x -= zone.x;
    y -= zone.y;
    const Charset& charset = charsets[zone.charset];

    if (!topmost)
    {
        for (int t = 0; t < zone.tiles.size(); ++t)
        {
            const Tile& tile = zone.tiles[t];
            const Shape& tileshape = charset.shapes[tile.s];
            if (x >= tile.x && y >= tile.y && x <= (tile.x + tileshape.sx/2 - 1) && y <= (tile.y + tileshape.sy/2 - 1))
                return t;
        }
    }
    else
    {
        for (int t = zone.tiles.size() - 1; t >= 0; --t)
        {
            const Tile& tile = zone.tiles[t];
            const Shape& tileshape = charset.shapes[tile.s];
            if (x >= tile.x && y >= tile.y && x <= (tile.x + tileshape.sx/2 - 1) && y <= (tile.y + tileshape.sy/2 - 1))
                return t;
        }
    }

    return -1;
}

int findobjectshape(int x, int y, const Zone& zone)
{
    x += zone.x;
    y += zone.y;
    int t = findtile(x, y, zone);
    if (t >= 0)
        return zone.tiles[t].s;
    else
        return 0;
}

void editzone()
{
    if (key == KEY_COMMA || key == KEY_Z)
    {
        if (!shiftdown)
        {
            zonenum--;
            zonenum &= NUMZONES-1;
            charsetnum = zones[zonenum].charset;
        }
        else
        {
            if (zonenum > 0)
            {
                Zone tempzone = zones[zonenum-1];
                zones[zonenum-1] = zones[zonenum];
                zones[zonenum] = tempzone;
                --zonenum;
            }
        }
    }
    if (key == KEY_COLON || key == KEY_X)
    {
        if (!shiftdown)
        {
            zonenum++;
            zonenum &= NUMZONES-1;
            charsetnum = zones[zonenum].charset;
        }
        else
        {
            if (zonenum < NUMZONES-1)
            {
                Zone tempzone = zones[zonenum+1];
                zones[zonenum+1] = zones[zonenum];
                zones[zonenum] = tempzone;
                ++zonenum;
            }
        }
    }
    if (key == KEY_U)
    {
        int c;
        for (c = 0; c < NUMZONES; ++c)
        {
            if (!zones[c].sx && !zones[c].sy)
            {
                zonenum = c;
                charsetnum = zones[c].charset;
                break;
            }
        }
    }

    Zone& zone = zones[zonenum];

    if (key == KEY_TAB && shiftdown)
    {
        zone.charset--;
        zone.charset &= NUMCHARSETS-1;
        charsetnum = zone.charset;
    }
    if (key == KEY_TAB && !shiftdown)
    {
        zone.charset++;
        zone.charset &= NUMCHARSETS-1;
        charsetnum = zone.charset;
    }

    if (key == KEY_L)
    {
        if (!ctrldown)
        {
            if (!shiftdown)
                zone.level++;
            else
                zone.level--;
        }
        else
        {
            int levelnow = zone.level;
            for (int c = 0; c < NUMZONES; ++c)
            {
                if (!shiftdown)
                {
                    if (zones[c].level == levelnow && zones[c].charset == zone.charset)
                        zones[c].level++;
                }
                else
                {
                    if (zones[c].level == levelnow && zones[c].charset == zone.charset)
                        zones[c].level--;
                }
            }
        }
        zone.level &= NUMLEVELS-1;
    }
    if (key == KEY_F)
    {
        if (!shiftdown)
            zone.fill++;
        else
            zone.fill--;
    }
    if (key == KEY_W)
    {
        if (!shiftdown)
            zone.bg1 += 16;
        else
            zone.bg1 -= 16;
    }
    if (key == KEY_Q)
        zone.bg1 -= 16;

    if (shiftdown && !ctrldown && (key == KEY_DEL || key == KEY_BACKSPACE))
    {
        zone.sx = 0;
        zone.sy = 0;
        zone.tiles.clear();
        zone.actors.clear();
        zone.objects.clear();
        shapeusedirty = true;
    }
    if (key == KEY_INS && ctrldown)
    {
        int level = zone.level;
        for (int c = 0; c < NUMZONES; ++c)
        {
            if (zones[c].sx && zones[c].sy && zones[c].level >= level)
                ++zones[c].level;
        }
    }
    if (key == KEY_DEL && ctrldown)
    {
        int level = zone.level;
        for (int c = 0; c < NUMZONES; ++c)
        {
            if (zones[c].sx && zones[c].sy && zones[c].level >= level)
                --zones[c].level;
        }
    }

    if (key == KEY_R && shiftdown)
    {
        if ((mousex >= 0) && (mousex < vsx*divisor) && (mousey >= 0) && (mousey < vsy*divisor))
        {
            int x = mapx+mousex/divisor;
            int y = mapy+mousey/divisor;
            x = x/SCREENSIZEX*SCREENSIZEX;
            y = y/SCREENSIZEY*SCREENSIZEY;

            if (!ctrldown)
            {
                if (checkzonelegal(zonenum, x, y, zone.sx, zone.sy))
                {
                    zone.x = x;
                    zone.y = y;
                }
            }
            else
            {
                // Whole world relocate
                int ofsx = x - zone.x;
                int ofsy = y - zone.y;
                bool legal = true;
                for (int z = 0; z < NUMZONES; ++z)
                {
                    if (zones[z].x + ofsx < 0 || zones[z].y + ofsy < 0)
                    {
                        legal = false;
                        break;
                    }
                }
                if (legal)
                {
                    for (int z = 0; z < NUMZONES; ++z)
                    {
                        zones[z].x += ofsx;
                        zones[z].y += ofsy;
                    }
                }
            }
        }
    }
    if (key == KEY_G && zone.sx && zone.sy)
    {
        mapx = zone.x;
        mapy = zone.y;
    }

    if ((mousex >= 0) && (mousex < vsx*divisor) && (mousey >= 0) && (mousey < vsy*divisor))
    {
        int x = mapx+mousex/divisor;
        int y = mapy+mousey/divisor;

        if (mouseb == 1)
        {
            int newzonenum = findzone(x,y);
            if (newzonenum >= 0)
            {
                zonenum = newzonenum;
                charsetnum = zone.charset;
            }
        }
        if (mouseb == 2)
        {
            if (!zone.sx && !zone.sy)
            {
                int nx = x/SCREENSIZEX*SCREENSIZEX;
                int ny = y/SCREENSIZEY*SCREENSIZEY;
                int nsx = SCREENSIZEX;
                int nsy = SCREENSIZEY;
                if (checkzonelegal(zonenum, nx, ny, nsx, nsy))
                {
                    // Copy properties from nearest zone to speed up
                    int nearest = findnearestzone(x, y);

                    zone.x = nx;
                    zone.y = ny;
                    zone.sx = nsx;
                    zone.sy = nsy;

                    if (nearest >= 0)
                    {
                        zone.bg1 = zones[nearest].bg1;
                        zone.bg2 = zones[nearest].bg2;
                        zone.bg3 = zones[nearest].bg3;
                        zone.charset = zones[nearest].charset;
                        zone.fill = zones[nearest].fill;
                        zone.level = zones[nearest].level;
                    }
                }
            }
            else
            {
                if (!shiftdown)
                {
                    int px = x/SCREENSIZEX*SCREENSIZEX;
                    int py = y/SCREENSIZEY*SCREENSIZEY;
                    int nx = zone.x;
                    int ny = zone.y;
                    int nsx = zone.sx;
                    int nsy = zone.sy;
                    if (px < nx)
                    {
                        nx = px;
                        nsx = zone.x+zone.sx-nx;
                    }
                    else if (px+SCREENSIZEX-zone.x > zone.sx)
                        nsx = px+SCREENSIZEX-zone.x;
                    if (py < ny)
                    {
                        ny = py;
                        nsy = zone.y+zone.sy-ny;
                    }
                    else if (py+SCREENSIZEY-zone.y > zone.sy)
                        nsy = py+SCREENSIZEY-zone.y;
                    if (checkzonelegal(zonenum, nx, ny, nsx, nsy))
                    {
                        int oldx = zone.x;
                        int oldy = zone.y;

                        zone.x = nx;
                        zone.y = ny;
                        zone.sx = nsx;
                        zone.sy = nsy;

                        movezonetiles(zone, oldx-nx, oldy-ny);
                    }
                }
                else
                {
                    if (x == zone.x && zone.sx > SCREENSIZEX)
                    {
                        zone.x += SCREENSIZEX;
                        zone.sx -= SCREENSIZEX;

                        movezonetiles(zone, -SCREENSIZEX, 0);
                    }
                    else if (x == zone.x + zone.sx - 1 && zone.sx > SCREENSIZEX)
                        zone.sx -= SCREENSIZEX;
                    else if (y == zone.y && zone.sy > SCREENSIZEY)
                    {
                        zone.y += SCREENSIZEY;
                        zone.sy -= SCREENSIZEY;

                        movezonetiles(zone, 0, -SCREENSIZEY);
                    }
                    else if (y == zone.y + zone.sy - 1 && zone.sy > SCREENSIZEY)
                        zone.sy -= SCREENSIZEY;
                }
            }
        }
    }

    int texty = 17*16+8;
    if (zone.sx && zone.sy)
    {
        sprintf(textbuffer, "WPOS %d,%d", zone.x/SCREENSIZEX, zone.y/SCREENSIZEY);
        printtext_color(textbuffer, 0, texty+30, SPR_FONTS, COL_WHITE);
        int zssy = (zone.y+zone.sy-1-(zone.y/SCREENSIZEY*SCREENSIZEY))/SCREENSIZEY+1;
        sprintf(textbuffer, "SIZE %d,%d", zone.sx/SCREENSIZEX, zssy);
        printtext_color(textbuffer, 0, texty+45, SPR_FONTS, COL_WHITE);
    }
    else
        printtext_color("(UNUSED)", 0, texty+30, SPR_FONTS, COL_WHITE);

    sprintf(textbuffer, "LEVEL   %d", zone.level);
    printtext_color(textbuffer, 128, texty+30, SPR_FONTS, COL_WHITE);

    int mapdatasize = 0;
    for (int z = 0; z < NUMZONES; ++z)
    {
        const Zone& otherzone = zones[z];
        if (otherzone.sx && otherzone.sy && otherzone.level == zone.level)
            mapdatasize += otherzone.sx*otherzone.sy;
    }
    sprintf(textbuffer, "MAPSIZE %d", mapdatasize);
    printtext_color(textbuffer, 128, texty+45, SPR_FONTS, COL_WHITE);
}

void editactors()
{
    Zone& zone = zones[zonenum];

    // Actortype select
    if (key == KEY_COMMA || (key == KEY_Z && !shiftdown))
    {
        acttype--;
    }
    if (key == KEY_COLON || (key == KEY_X && !shiftdown))
    {
        acttype++;
    }
    if (shiftdown && key == KEY_Z)
    {
        acttype -= 16;
    }
    if (shiftdown && key == KEY_X)
    {
        acttype += 16;
    }
    if (key == KEY_I)
    {
        acttype ^= 128;
    }

    int oidx = -1;
    int aidx = -1;

    if (dataeditoidx >= zone.objects.size())
        dataeditmode = 0;

    if (dataeditmode)
    {
        oidx = dataeditoidx;
        int hex = -1;

        if ((key == KEY_DEL) || (key == KEY_BACKSPACE))
        {
            dataeditcursor--;
            if (dataeditcursor < 0) dataeditcursor = 0;
                hex = 0;
        }

        if (key == KEY_0) hex = 0;
        if (key == KEY_1) hex = 1;
        if (key == KEY_2) hex = 2;
        if (key == KEY_3) hex = 3;
        if (key == KEY_4) hex = 4;
        if (key == KEY_5) hex = 5;
        if (key == KEY_6) hex = 6;
        if (key == KEY_7) hex = 7;
        if (key == KEY_8) hex = 8;
        if (key == KEY_9) hex = 9;
        if (key == KEY_A) hex = 10;
        if (key == KEY_B) hex = 11;
        if (key == KEY_C) hex = 12;
        if (key == KEY_D) hex = 13;
        if (key == KEY_E) hex = 14;
        if (key == KEY_F) hex = 15;

        if (hex >= 0)
        {
            switch(dataeditcursor)
            {
            case 0:
                zone.objects[oidx].data &= 0x0fff;
                zone.objects[oidx].data |= hex << 12;
                break;

            case 1:
                zone.objects[oidx].data &= 0xf0ff;
                zone.objects[oidx].data |= hex << 8;
                break;

            case 2:
                zone.objects[oidx].data &= 0xff0f;
                zone.objects[oidx].data |= hex << 4;
                break;

            case 3:
                zone.objects[oidx].data &= 0xfff0;
                zone.objects[oidx].data |= hex;
                break;
            }
        }

        if (hex >= 0 && (key != KEY_DEL && key != KEY_BACKSPACE))
        {
            dataeditcursor++;
            if (dataeditcursor > 4) dataeditcursor = 4;
        }
        if (key == KEY_RIGHT)
        {
            dataeditcursor++;
            if (dataeditcursor > 4) dataeditcursor = 4;
        }
        if (key == KEY_LEFT)
        {
            dataeditcursor--;
            if (dataeditcursor < 0) dataeditcursor = 0;
        }
        if (key == KEY_ENTER || key == KEY_SPACE)
            dataeditmode = 0;
    }
    else
    {
        if ((mousex >= 0) && (mousex < vsx*divisor) && (mousey >= 0) && (mousey < vsy*divisor))
        {
            int x = mapx+mousex/divisor;
            int y = mapy+mousey/divisor;
            int zx = x - zone.x;
            int zy = y - zone.y;
    
            for (int c = 0; c < zone.actors.size(); ++c)
            {
                if (zx == zone.actors[c].x && zy == zone.actors[c].y)
                {
                    aidx = c;
                    break;
                }
            }
    
            for (int c = 0; c < zone.objects.size(); ++c)
            {
                if (zx >= zone.objects[c].x && zy >= zone.objects[c].y && zx < (zone.objects[c].x + zone.objects[c].sx) && zy < (zone.objects[c].y + zone.objects[c].sy))
                {
                    oidx = c;
                    break;
                }
            }
    
            if (mouseb == 1 && !prevmouseb && oidx < 0)
            {
                Object newobject;
                newobject.x = zx;
                newobject.y = zy;
                newobject.sx = 1;
                newobject.sy = 1;
                newobject.frames = 1;
                newobject.flags = 0;
                newobject.data = 0;
                zone.objects.push_back(newobject);
            }

            if (mouseb == 2 && !prevmouseb && acttype != 0)
            {
                Actor newactor;
                newactor.x = zx;
                newactor.y = zy;
                newactor.t = acttype;
                newactor.flags = 0;
                zone.actors.push_back(newactor);
            }
            if (aidx >= 0)
            {
                // Dir
                if (key == KEY_D && zone.actors[aidx].t < 0x80)
                    zone.actors[aidx].flags ^= 0x80;
                // Respawn
                if (key == KEY_R && zone.actors[aidx].t < 0x80)
                    zone.actors[aidx].flags ^= 0x40;
                // Global
                if (key == KEY_G)
                    zone.actors[aidx].flags ^= 0x20;
                if (key == KEY_1 || key == KEY_Q)
                    --zone.actors[aidx].t;
                if (key == KEY_2 || key == KEY_W)
                    ++zone.actors[aidx].t;
                if (key == KEY_DEL)
                {
                    zone.actors.erase(zone.actors.begin() + aidx);
                    aidx = -1;
                }
            }
            if (oidx >= 0)
            {
                if (key == KEY_M)
                {
                    unsigned char modebits = zone.objects[oidx].flags & 3;
                    if (!shiftdown)
                        modebits++;
                    else
                        modebits--;
                    modebits &= 3;
                    zone.objects[oidx].flags &= 0xfc;
                    zone.objects[oidx].flags |= modebits;
                }
                if (key == KEY_T)
                {
                    unsigned char typebits = zone.objects[oidx].flags & 0xc;
                    if (!shiftdown)
                        typebits += 4;
                    else
                        typebits -= 4;
                    typebits &= 0xc;
                    zone.objects[oidx].flags &= 0xf3;
                    zone.objects[oidx].flags |= typebits;
                }
                if (key == KEY_D)
                    zone.objects[oidx].flags ^= 0x10;
                if (key == KEY_F)
                {
                    if (!shiftdown && zone.objects[oidx].frames < 4)
                        zone.objects[oidx].frames++;
                    if (shiftdown && zone.objects[oidx].frames > 1)
                        zone.objects[oidx].frames--;
                }
                if (key == KEY_X)
                {
                    if (!shiftdown)
                    {
                        zone.objects[oidx].sx++;
                        if (zone.objects[oidx].sx > 4)
                            zone.objects[oidx].sx = 1;
                    }
                    else
                    {
                        zone.objects[oidx].sx--;
                        if (zone.objects[oidx].sx == 0)
                            zone.objects[oidx].sx = 4;
                    }
                }
                if (key == KEY_Y)
                {
                    if (!shiftdown)
                    {
                        zone.objects[oidx].sy++;
                        if (zone.objects[oidx].sy > 4)
                            zone.objects[oidx].sy = 1;
                    }
                    else
                    {
                        zone.objects[oidx].sy--;
                        if (zone.objects[oidx].sy == 0)
                            zone.objects[oidx].sy = 4;
                    }
                }
                if (key == KEY_ENTER)
                {
                    dataeditmode = 1;
                    dataeditcursor = 0;
                    dataeditoidx = oidx;
                }
                if (key == KEY_DEL)
                {
                    zone.objects.erase(zone.objects.begin() + oidx);
                    oidx = -1;
                }
            }
        }
    }

    int texty = 17*16+8;
    if (zone.sx && zone.sy)
    {
        sprintf(textbuffer, "WPOS %d,%d", zone.x/SCREENSIZEX, zone.y/SCREENSIZEY);
        printtext_color(textbuffer, 0, texty+30, SPR_FONTS, COL_WHITE);
        int zssy = (zone.y+zone.sy-1-(zone.y/SCREENSIZEY*SCREENSIZEY))/SCREENSIZEY+1;
        sprintf(textbuffer, "SIZE %d,%d", zone.sx/SCREENSIZEX, zssy);
        printtext_color(textbuffer, 0, texty+45, SPR_FONTS, COL_WHITE);
    }
    else
        printtext_color("(UNUSED)", 0, texty+30, SPR_FONTS, COL_WHITE);

    int levelactors = 0;
    int allactors = 0;
    int levelobjects = 0;
    int allobjects = 0;
    int globalactors = 0;
    for (int z = 0; z < NUMZONES; ++z)
    {
        const Zone& otherzone = zones[z];
        if (otherzone.sx && otherzone.sy)
        {
            allactors += otherzone.actors.size();
            allobjects += otherzone.objects.size();
            if (otherzone.level == zone.level)
            {
                levelactors += otherzone.actors.size();
                levelobjects += otherzone.objects.size();
            }
        }
        for (int c = 0; c < otherzone.actors.size(); ++c)
        {
            if (otherzone.actors[c].flags & 0x20)
                ++globalactors;
        }
    }

    sprintf(textbuffer, "LEVEL   %d", zone.level);
    printtext_color(textbuffer, 128, texty, SPR_FONTS, COL_WHITE);
    if (oidx < 0)
        sprintf(textbuffer, "ACTORS  %d/%d/%d G%d", zone.actors.size(), levelactors, allactors, globalactors);
    else
        sprintf(textbuffer, "ACTORS  %d/%d/%d", zone.actors.size(), levelactors, allactors);
    printtext_color(textbuffer, 128, texty+15, SPR_FONTS, COL_WHITE);
    sprintf(textbuffer, "OBJECTS %d/%d/%d", zone.objects.size(), levelobjects, allobjects);
    printtext_color(textbuffer, 128, texty+30, SPR_FONTS, COL_WHITE);

    if (acttype < 128)
        sprintf(textbuffer, "ACTTYPE %02x (%s)", acttype, actorname[acttype]);
    else
        sprintf(textbuffer, "ITEM    %02x (%s)", acttype-128, itemname[acttype-128]);
    printtext_color(textbuffer, 128, texty+45, SPR_FONTS, COL_WHITE);

    if (aidx >= 0)
    {
        const Actor& actor = zone.actors[aidx];

        // Find out global ID within level, disregard global actors
        int gaidx = 0;
        if (zone.actors[aidx].flags & 0x20)
            gaidx = 0xff; // Global, cannot be determined here
        else
        {
            for (int z = 0; z < zonenum; ++z)
            {
                const Zone& otherzone = zones[z];
                if (otherzone.sx && otherzone.sy && otherzone.level == zone.level)
                {
                    for (int za = 0; za < otherzone.actors.size(); ++za)
                        if ((otherzone.actors[za].flags & 0x20) == 0)
                            ++gaidx;
                }
            }
            for (int za = 0; za < aidx; ++za)
            {
                if ((zone.actors[za].flags & 0x20) == 0)
                    ++gaidx;
            }
        }

        if (actor.t <= 128)
            sprintf(textbuffer, "ID%02x X%02x Y%02x T%02x %s%s%s (%s)", gaidx, actor.x, actor.y, actor.t, (actor.flags & 0x80) ? "L" : "R", (actor.flags & 0x40) ? " RSP" : "", (actor.flags & 0x20) ? " GL" : "", actorname[actor.t]);
        else
            sprintf(textbuffer, "ID%02x X%02x Y%02x T%02x (%s)", gaidx, actor.x, actor.y, actor.t, itemname[actor.t-128]);
        printtext_color(textbuffer, 256-24, texty, SPR_FONTS, COL_WHITE);
    }

    if (oidx >= 0)
    {
        const Object& object = zone.objects[oidx];

        // Find out global ID within level
        int goidx = 0;
        for (int z = 0; z < zonenum; ++z)
        {
            const Zone& otherzone = zones[z];
            if (otherzone.sx && otherzone.sy && otherzone.level == zone.level)
                goidx += otherzone.objects.size();
        }
        goidx += oidx;

        sprintf(textbuffer, "ID%02x X%02x Y%02x SX%d SY%d F%d", goidx, object.x, object.y, object.sx, object.sy, object.frames);
        printtext_color(textbuffer, 256+16, texty, SPR_FONTS, COL_WHITE);

        if (!dataeditmode)
        {
            sprintf(textbuffer, "M:%s T:%s %s%04x",objmodetxts[object.flags & 0x3], objtypetxts[(object.flags & 0xc) >> 2],
                objautodeacttxts[(object.flags & 0x10) >> 4], object.data);
        }
        else
        {
            sprintf(textbuffer, "M:%s T:%s %s(%04x)",objmodetxts[object.flags & 0x3], objtypetxts[(object.flags & 0xc) >> 2],
                objautodeacttxts[(object.flags & 0x10) >> 4], object.data);
        }
        printtext_color(textbuffer, 256+16, texty+15, SPR_FONTS, COL_WHITE);
    }
}


int findzone(int x, int y)
{
    for (int c = 0; c < NUMZONES; c++)
    {
        const Zone& zone = zones[c];
        if (zone.sx && zone.sy)
        {
            if (x >= zone.x && x < zone.x+zone.sx && y >= zone.y && y < zone.y + zone.sy)
                return c;
        }
    }
    return -1;
}

int findnearestzone(int x, int y)
{
    int nearest = -1;
    int nearestdist = 0x7fffffff;
    for (int c = 0; c < NUMZONES; c++)
    {
        const Zone& zone = zones[c];
        if (zone.sx && zone.sy)
        {
            int dist = abs(x - (zone.x+zone.x+zone.sx)/2) + abs(y - (zone.y+zone.y+zone.sy)/2);
            if (dist < nearestdist)
            {
                nearest = c;
                nearestdist = dist;
            }
        }
    }
    return nearest;
}

bool checkzonelegal(int num, int newx, int newy, int newsx, int newsy)
{
    // Can't be over 255 in either direction (practically not even that to allow reliable bounds checking)
    if (newsx > MAXZONESIZE || newsy > MAXZONESIZE)
        return false;

    // Check for no overlap
    for (int c = 0; c < NUMZONES; c++)
    {
        const Zone& zone = zones[c];
        if (c != num && zone.sx && zone.sy)
        {
            int xoverlap = 0, yoverlap = 0;
            if (newx < zone.x && newx+newsx > zone.x)
                xoverlap = 1;
            if (newx >= zone.x && newx < zone.x+zone.sx)
                xoverlap = 1;
            if (newy < zone.y && newy+newsy > zone.y)
                yoverlap = 1;
            if (newy >= zone.y && newy < zone.y+zone.sy)
                yoverlap = 1;
            if (xoverlap && yoverlap)
                return false;
        }
    }
    return true;
}

void movezonetiles(Zone& zone, int xadd, int yadd)
{
    for (int t = 0; t < zone.tiles.size(); ++t)
    {
        zone.tiles[t].x += xadd;
        zone.tiles[t].y += yadd;
    }
    for (int i = 0; i < zone.objects.size(); ++i)
    {
        zone.objects[i].x += xadd;
        zone.objects[i].y += yadd;
    }
    for (int i = 0; i < zone.actors.size(); ++i)
    {
        zone.actors[i].x += xadd;
        zone.actors[i].y += yadd;
    }
}

void drawzoneshape(int x, int y, unsigned char num, bool drawnumber, bool drawinfo, const Zone& zone)
{
    const Shape& shape = charsets[zone.charset].shapes[num];

    for (int cy = 0; cy < shape.sy; ++cy)
    {
        for (int cx = 0; cx < shape.sx; ++cx)
        {
            if (cx/2+x >= zone.sx || cy/2+y >= zone.sy)
                continue;

            int px = (x+zone.x-mapx+cx/2);
            int py = (y+zone.y-mapy+cy/2);

            if (px < 0 || py < 0 || px >= vsx || py >= vsy)
                continue;

            px *= divisor;
            px += (cx&1)*divisor/2;
            py *= divisor;
            py += (cy&1)*divisor/2;

            if (!zoomout)
                drawchar(px, py, &shape.chardata[(cy*MAXSHAPESIZE+cx)*8], shape.charcolors[cy*MAXSHAPESIZE+cx], zone);
            else
                drawcharsmall(px, py, &shape.chardata[(cy*MAXSHAPESIZE+cx)*8], shape.charcolors[cy*MAXSHAPESIZE+cx], zone);
        }
    }

    if ((drawnumber || drawinfo) && !zoomout)
    {
        for (int cy = 0; cy < shape.sy; cy += 2)
        {
            for (int cx = 0; cx < shape.sx; cx += 2)
            {
                if (cx/2+x >= zone.sx || cy/2+y >= zone.sy)
                    continue;

                int px = (x+zone.x-mapx+cx/2);
                int py = (y+zone.y-mapy+cy/2);

                if (px < 0 || py < 0 || px >= vsx || py >= vsy)
                    continue;

                px *= divisor;
                px += (cx&1)*divisor/2;
                py *= divisor;
                py += (cy&1)*divisor/2;

                if (drawinfo)
                    drawblockinfo(px, py, shape.blockinfos[(cy/2)*MAXSHAPEBLOCKSIZE+cx/2]);
                if (drawnumber && cy == 0 && cx == 0)
                {
                    sprintf(textbuffer, "%d", num);
                    printtext_color(textbuffer, px, py, SPR_FONTS, COL_WHITE);
                }
            }
        }
    }
}

void drawzoneshapepng(int x, int y, unsigned char num, const Zone& zone, unsigned char* dest, int sizex, int sizey, int minx, int miny)
{
    const Shape& shape = charsets[zone.charset].shapes[num];
    for (int cy = 0; cy < shape.sy; ++cy)
    {
        for (int cx = 0; cx < shape.sx; ++cx)
            drawchar(cx*8, cy*8, &shape.chardata[(cy*MAXSHAPESIZE+cx)*8], shape.charcolors[cy*MAXSHAPESIZE+cx], zone);
    }

    for (int py = 0; py < shape.sy*8; ++py)
    {
        for (int px = 0; px < shape.sx*8; ++px)
        {
            int fx = (x+zone.x-minx)*16+px;
            int fy = (y+zone.y-miny)*16+py;
            if (fx < 0 || fy < 0 || fx >= (zone.x+zone.sx-minx)*16 || fy >= (zone.y+zone.sy-miny)*16)
                continue;
            if (fx >= sizex || fy >= sizey)
                continue;
            int r,g,b;
            r = gfx_palette[gfx_vscreen[py*screensizex+px]*3] * 4;
            g = gfx_palette[gfx_vscreen[py*screensizex+px]*3+1] * 4;
            b = gfx_palette[gfx_vscreen[py*screensizex+px]*3+2] * 4;
            if (r > 255) r = 255;
            if (g > 255) g = 255;
            if (b > 255) b = 255;
            dest[(fy*sizex+fx)*3] = r;
            dest[(fy*sizex+fx)*3+1] = g;
            dest[(fy*sizex+fx)*3+2] = b;
        }
    }
}

void setmulticol(unsigned char& data, int x, unsigned char bits)
{
    unsigned char andtable[4] = {0x3f, 0xcf, 0xf3, 0xfc};
    x >>= 1;
    data &= andtable[x];
    bits <<= ((3-x)*2);
    data |= bits;
}

void setsinglecol(unsigned char& data, int x, unsigned char bits)
{
    unsigned char andtable[8] = {0x7f, 0xbf, 0xdf, 0xef, 0xf7, 0xfb, 0xfd, 0xfe};
    data &= andtable[x];
    bits <<= (7-x);
    data |= bits;
}

void scrollcharleft(unsigned char* chardata, unsigned char color)
{
    unsigned char c;

    if ((color & 15) < 8)
        c = 1;
    else
        c = 2;

    while (c)
    {
        for (int y = 0; y < 8; ++y)
        {
            unsigned data = chardata[y];
            unsigned char bit = chardata[y] >> 7;
            data <<= 1;
            chardata[y] = data | bit;
        }
        --c;
    }
}

void scrollcharright(unsigned char* chardata, unsigned char color)
{
    unsigned char c;

    if ((color & 15) < 8)
        c = 1;
    else
        c = 2;

    while (c)
    {
        for (int y = 0; y < 8; ++y)
        {
            unsigned data = chardata[y];
            unsigned char bit = (chardata[y] & 1) << 7;
            data >>= 1;
            chardata[y] = data | bit;
        }
        --c;
    }
}

void scrollcharup(unsigned char* chardata, unsigned char color)
{
    unsigned char store = chardata[0];
    for (int y = 0; y < 7; y++)
        chardata[y] = chardata[y+1];
    chardata[7] = store;
}

void scrollchardown(unsigned char* chardata, unsigned char color)
{
    unsigned char store = chardata[7];
    for (int y = 6; y >= 0; y--)
        chardata[y+1] = chardata[y];
    chardata[0] = store;
}

void selectshape(unsigned char newshape)
{
    shapenum = newshape & (NUMSHAPES-1);
    if (grabmode < 3)
        grabmode = 0;
    if (!wholescreenshapeselect)
    {
        while (shapenum < oss)
            oss -= 16;
        while (shapenum - oss >= 32)
            oss += 16;
        if (oss == NUMSHAPES-16)
            oss = NUMSHAPES-32;
    }
}

bool isinsidezone(int x, int y, const Zone& zone)
{
    if (!zone.sx || !zone.sy)
        return false;

    return (x >= zone.x && y >= zone.y && x < zone.x + zone.sx && y < zone.y + zone.sy);
}

void resetshape(Shape& shape)
{
    shape.sx = 2;
    shape.sy = 2;
    memset(shape.chardata, 0, sizeof shape.chardata);
    memset(shape.charcolors, 9, sizeof shape.charcolors);
    memset(shape.blockinfos, 0, sizeof shape.blockinfos);
}

void deleteshape(int dsnum)
{
    for (int z = 0; z < NUMZONES; ++z)
    {
        Zone& zone = zones[z];
        if (zone.sx && zone.sy && zone.charset == charsetnum)
        {
            if (zone.fill > dsnum)
                --zone.fill;
            for (int t = 0; t < zone.tiles.size();)
            {
                if (zone.tiles[t].s == dsnum)
                    zone.tiles.erase(zone.tiles.begin() + t);
                else if (zone.tiles[t].s >= dsnum)
                {
                    --zone.tiles[t].s;
                    ++t;
                }
                else
                    ++t;
            }
        }
    }

    for (int s = dsnum; s < NUMSHAPES; ++s)
    {
        if (s < NUMSHAPES-1)
            charsets[charsetnum].shapes[s] = charsets[charsetnum].shapes[s+1];
    }

    resetshape(charsets[charsetnum].shapes[NUMSHAPES-1]);
    charsets[charsetnum].dirty = true;
    shapeusedirty = true;
}

void insertcharset()
{
    for (int c = NUMCHARSETS-2; c >= charsetnum; --c)
        charsets[c+1] = charsets[c];
    resetcharset(charsets[charsetnum]);
    for (int z = 0; z < NUMZONES; ++z)
    {
        Zone& zone = zones[z];
        if (zone.sx && zone.sy && zone.charset >= charsetnum)
            ++zone.charset;
    }
}

void insertshape()
{
    for (int z = 0; z < NUMZONES; ++z)
    {
        Zone& zone = zones[z];
        if (zone.sx && zone.sy && zone.charset == charsetnum)
        {
            if (zone.fill >= shapenum)
                ++zone.fill;

            for (int t = 0; t < zone.tiles.size();)
            {
                if (zone.tiles[t].s == NUMSHAPES-1)
                    zone.tiles.erase(zone.tiles.begin() + t);
                else if (zone.tiles[t].s >= shapenum)
                {
                    ++zone.tiles[t].s;
                    ++t;
                }
                else
                    ++t;
            }
        }
    }

    for (int s = NUMSHAPES-2; s >= shapenum; --s)
        charsets[charsetnum].shapes[s+1] = charsets[charsetnum].shapes[s];

    resetshape(charsets[charsetnum].shapes[shapenum]);
    charsets[charsetnum].dirty = true;
    shapeusedirty = true;
}

void updateshapeuse()
{
    for (int c = 0; c < NUMCHARSETS; ++c)
    {
        for (int s = 0; s < NUMSHAPES; ++s)
            charsets[c].shapes[s].usecount = (s == 0) ? 999 : 0;
    }

    for (int z = 0; z < NUMZONES; ++z)
    {
        Zone& zone = zones[z];
        if (zone.sx && zone.sy)
        {
            Shape& fillshape = charsets[zone.charset].shapes[zone.fill];
            fillshape.usecount += (zone.sx*2 / fillshape.sx) * (zone.sy*2 / fillshape.sy);

            for (int t = 0; t < zone.tiles.size(); ++t)
                ++charsets[zone.charset].shapes[zone.tiles[t].s].usecount;
        }
    }

    shapeusedirty = false;
}

void updatelockedmode()
{
    if (!lockedmode)
        return;
    Charset& charset = charsets[charsetnum];
    Shape& orgshape = charset.shapes[shapenum];
    int orgofs = esy*MAXSHAPESIZE+esx;
    int c = charset.shapechars[shapenum][orgofs];

    for (int s = 0; s < NUMSHAPES; ++s)
    {
        Shape& shape = charset.shapes[s];
        if (shape.sx && shape.sy)
        {
            for (int cy = 0; cy < shape.sy; ++cy)
            {
                for (int cx = 0; cx < shape.sx; ++cx)
                {
                    int ofs = cy*MAXSHAPESIZE+cx;
                    if ((s == shapenum && ofs == orgofs) || charset.shapechars[s][ofs] != c)
                        continue;
                    memcpy(&shape.chardata[ofs*8], &orgshape.chardata[orgofs*8], 8);
                    shape.charcolors[ofs] = orgshape.charcolors[orgofs];
                }
            }
        }
    }
}

void resetzone(Zone& zone)
{
    zone.x = 0;
    zone.y = 0;
    zone.sx = 0;
    zone.sy = 0;
    zone.bg1 = 6;
    zone.bg2 = 11;
    zone.bg3 = 12;
    zone.charset = 0;
    zone.fill = 1;
    zone.level = 0;
    zone.tiles.clear();
    zone.actors.clear();
    zone.objects.clear();
    shapeusedirty = true;
}

void resetcharset(Charset& charset)
{
    for (int s = 0; s < NUMSHAPES; ++s)
    {
        resetshape(charset.shapes[s]);
    }

    // Tradition: tile 0 is an obstacle, used if zone is less than screen
    charset.shapes[0].blockinfos[0] = 2;
    for (int cy = 0; cy < 2; ++cy)
    {
        for (int cx = 0; cx < 2; ++cx)
        {
            memset(&charset.shapes[0].chardata[(cy*MAXSHAPESIZE+cx)*8], 0xff, 8);
            charset.shapes[0].charcolors[cy*MAXSHAPESIZE+cx] = 8;
        }
    }
    
    charset.dirty = true;
}

void loadshapes()
{
  char ib1[80];
  char ib2[5];
  int phase = 1;
  ib1[0] = 0;
  ib2[0] = 0;

  for (;;)
  {
    win_getspeed(70);
    gfx_fillscreen(254);
    printtext_center_color("LOAD SHAPEFILE:",screensizey/2-30,SPR_FONTS,COL_WHITE);
    printtext_center_color(ib1,screensizey/2-20,SPR_FONTS,COL_HIGHLIGHT);
    if (phase > 1)
    {
      printtext_center_color("LOAD AT SHAPENUM:",screensizey/2-5,SPR_FONTS,COL_WHITE);
      printtext_center_color(ib2,screensizey/2+5,SPR_FONTS,COL_HIGHLIGHT);
    }
    gfx_updatepage();
    if (phase == 1)
    {
      int r = inputtext(ib1, 80);
      if (r == -1) return;
      if (r == 1) phase = 2;
    }
    if (phase == 2)
    {
      int r = inputtext(ib2, 5);
      if (r == -1) return;
      if (r == 1)
      {
        int frame;
        int handle;
        sscanf(ib2, "%d", &frame);
        if (frame < 0) frame = 0;
        if (frame > NUMSHAPES-1) frame = NUMSHAPES-1;
        handle = open(ib1, O_RDONLY | O_BINARY);
        if (handle == -1) return;
        int numshapes = readle16(handle);
        for (int s = frame; s < NUMSHAPES && s < frame+numshapes; ++s)
        {
            Shape& shape = charsets[charsetnum].shapes[s];
            loadshape(handle, shape);
        }
        close(handle);
        charsets[charsetnum].dirty = true;
        return;
      }
    }
  }
}

void loadshape(int handle, Shape& shape)
{
    resetshape(shape);
    shape.sx = read8(handle);
    shape.sy = read8(handle);
    for (int cy = 0; cy < shape.sy; ++cy)
        read(handle, &shape.chardata[cy*MAXSHAPESIZE*8], 8*shape.sx);
    for (int cy = 0; cy < shape.sy; ++cy)
        read(handle, &shape.charcolors[cy*MAXSHAPESIZE], shape.sx);
    for (int cy = 0; cy < shape.sy/2; ++cy)
        read(handle, &shape.blockinfos[cy*MAXSHAPEBLOCKSIZE], shape.sx/2);
}

void importblocks()
{
  char ib1[80];
  char ib2[5];
  int phase = 1;
  ib1[0] = 0;
  ib2[0] = 0;

  for (;;)
  {
    win_getspeed(70);
    gfx_fillscreen(254);
    printtext_center_color("LOAD BLOCKFILE:",screensizey/2-30,SPR_FONTS,COL_WHITE);
    printtext_center_color(ib1,screensizey/2-20,SPR_FONTS,COL_HIGHLIGHT);
    if (phase > 1)
    {
      printtext_center_color("LOAD AT SHAPENUM:",screensizey/2-5,SPR_FONTS,COL_WHITE);
      printtext_center_color(ib2,screensizey/2+5,SPR_FONTS,COL_HIGHLIGHT);
    }
    gfx_updatepage();
    if (phase == 1)
    {
      int r = inputtext(ib1, 80);
      if (r == -1) return;
      if (r == 1) phase = 2;
    }
    if (phase == 2)
    {
      int r = inputtext(ib2, 5);
      if (r == -1) return;
      if (r == 1)
      {
        int frame;
        int handle;
        int numblocks;
        int datalen;
        int offset;

        sscanf(ib2, "%d", &frame);
        if (frame < 0) frame = 0;
        if (frame > NUMSHAPES-1) frame = NUMSHAPES-1;

        handle = open(ib1, O_RDONLY | O_BINARY);
        if (handle == -1) return;
        int length = lseek(handle, 0, SEEK_END);
        lseek(handle, 0, SEEK_SET);
        numblocks = readle32(handle);
        datalen = readle32(handle);

        unsigned char tempchardata[256*8];
        unsigned char tempcharcol[256];
        unsigned char tempblockdata[4096];

        int b = 0;
        for (int c = frame; c < frame+numblocks; ++c)
        {
          read(handle, &tempblockdata[b*16], 16);
          ++b;
        }
        read(handle, tempchardata, datalen);
        read(handle, tempcharcol, datalen/8);

        b = 0;
        for (int c = frame; c < frame+numblocks && c < NUMSHAPES; ++c)
        {
            Shape& shape = charsets[charsetnum].shapes[c];
            shape.sx = 4;
            shape.sy = 4;
            for (int by = 0; by < 4; ++by)
            {
                for (int bx = 0; bx < 4; ++bx)
                {
                    int charnum = tempblockdata[b*16+by*4+bx];
                    memcpy(&shape.chardata[(by*MAXSHAPESIZE+bx)*8], &tempchardata[charnum*8], 8);
                    shape.charcolors[by*MAXSHAPESIZE+bx] = tempcharcol[charnum];
                }
            }
            ++b;
        }
        close(handle);
        charsets[charsetnum].dirty = true;
        return;
      }
    }
  }
}


void saveshapes()
{
  char ib1[80];
  char ib2[5];
  char ib3[5];
  int phase = 1;
  ib1[0] = 0;
  ib2[0] = 0;
  ib3[0] = 0;

  for (;;)
  {
    win_getspeed(70);
    gfx_fillscreen(254);
    printtext_center_color("SAVE SHAPEFILE:",screensizey/2-40,SPR_FONTS,COL_WHITE);
    printtext_center_color(ib1,screensizey/2-30,SPR_FONTS,COL_HIGHLIGHT);
    if (phase > 1)
    {
      printtext_center_color("SAVE FROM SHAPENUM:",screensizey/2-15,SPR_FONTS,COL_WHITE);
      printtext_center_color(ib2,screensizey/2-5,SPR_FONTS,COL_HIGHLIGHT);
    }
    if (phase > 2)
    {
      printtext_center_color("SAVE HOW MANY:",screensizey/2+10,SPR_FONTS,COL_WHITE);
      printtext_center_color(ib3,screensizey/2+20,SPR_FONTS,COL_HIGHLIGHT);
    }
    gfx_updatepage();
    if (phase == 1)
    {
      int r = inputtext(ib1, 80);
      if (r == -1) return;
      if (r == 1) phase = 2;
    }
    if (phase == 2)
    {
      int r = inputtext(ib2, 5);
      if (r == -1) return;
      if (r == 1) phase = 3;
    }
    if (phase == 3)
    {
      int r = inputtext(ib3, 5);
      if (r == -1) return;
      if (r == 1)
      {
        int frame, frames;
        int handle;
        sscanf(ib2, "%d", &frame);
        sscanf(ib3, "%d", &frames);
        if (frame < 0) frame = 0;
        if (frame > NUMSHAPES-1) frame = NUMSHAPES-1;
        if (frames < 1) frames = 1;
        if (frame+frames > NUMSHAPES) frames = NUMSHAPES-frame;

        handle = open(ib1, O_RDWR|O_BINARY|O_TRUNC|O_CREAT, S_IREAD|S_IWRITE);
        if (handle == -1) return;
        writele16(handle, frames);
        for (int s = frame; s < frame+frames; ++s)
        {
            Shape& shape = charsets[charsetnum].shapes[s];
            saveshape(handle, shape);
        }
        close(handle);
        return;
      }
    }
  }
}

void saveshape(int handle, const Shape& shape)
{
    write8(handle, shape.sx);
    write8(handle, shape.sy);
    for (int cy = 0; cy < shape.sy; ++cy)
        write(handle, &shape.chardata[cy*MAXSHAPESIZE*8], 8*shape.sx);
    for (int cy = 0; cy < shape.sy; ++cy)
        write(handle, &shape.charcolors[cy*MAXSHAPESIZE], shape.sx);
    for (int cy = 0; cy < shape.sy/2; ++cy)
        write(handle, &shape.blockinfos[cy*MAXSHAPEBLOCKSIZE], shape.sx/2);
}

void savealldata()
{
    char ib1[80];
    strcpy(ib1, levelname);

    int maxusedcharset = 0;

    for (;;)
    {
        int r;

        win_getspeed(70);
        gfx_fillscreen(254);

        printtext_center_color("SAVE ALL LEVELDATA:",screensizey/2-10,SPR_FONTS,COL_WHITE);
        printtext_center_color(ib1,screensizey/2,SPR_FONTS,COL_HIGHLIGHT);
        gfx_updatepage();

        r = inputtext(ib1, 80);
        if (r == -1) return;
        if (r == 1)
        {
            int handle;
            char ib2[80];
            char ib3[80];

            if (!strlen(ib1))
                return;

            // Check first that we have some data (prevent mistaken save of empty data over existing)
            bool hasdata = false;
            for (int z = 0; z < NUMZONES; ++z)
            {
                if (zones[z].sx && zones[z].sy)
                {
                    hasdata = true;
                    break;
                }
            }

            if (!hasdata)
                return;

            // Fix object references in switches if easily possible
            unsigned char objectids[NUMLEVELS];
            for (int c = 0; c < NUMLEVELS; ++c)
            {
                objectids[c] = 0;
            }
            for (int z = 0; z < NUMZONES; ++z)
            {
                if (zones[z].sx && zones[z].sy)
                {
                    Zone& zone = zones[z];
                    for (int c = 0; c < zone.objects.size(); ++c)
                    {
                        Object& object = zone.objects[c];
                        if (object.x >= 0 && object.y >= 0 && object.x < zone.sx && object.y < zone.sy)
                            object.id = objectids[zone.level]++;
                        else
                            object.id = 0xff;
                    }
                }
            }
            for (int z = 0; z < NUMZONES; ++z)
            {
                if (zones[z].sx && zones[z].sy)
                {
                    Zone& zone = zones[z];
                    for (int c = 0; c < zone.objects.size(); ++c)
                    {
                        Object& object = zone.objects[c];
                        // Is a switch?
                        if ((object.flags & 0xc) == 0x8)
                        {
                            // Switch object
                            if ((object.data & 0xff) < 0x80)
                            {
                                for (int d = 0; d < zone.objects.size(); ++d)
                                {
                                    if (d != c)
                                    {
                                        Object& otherObject = zone.objects[d];
                                        // Switched object can never be below the switch
                                        if (abs(otherObject.x - object.x) < 4 && abs(otherObject.y - object.y) < 4 && otherObject.y <= object.y)
                                        {
                                            object.data &= 0xff00;
                                            object.data |= otherObject.id;
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            for (int c = 0; c < NUMCHARSETS; ++c)
            {
                Charset& charset = charsets[c];
                packcharset(charset);
                if (charset.usedchars > 2 || charset.usedblocks > 2)
                    maxusedcharset = c;
            }

            strcpy(levelname, ib1);

            // All charsets (also unused)
            sprintf(ib2, "%s.chr", ib1);
            handle = open(ib2, O_RDWR|O_BINARY|O_TRUNC|O_CREAT, S_IREAD|S_IWRITE);
            if (handle != -1)
            {
                writele16(handle, NUMCHARSETS);
                for (int c = 0; c < NUMCHARSETS; ++c)
                {
                    writele16(handle, NUMSHAPES);
                    for (int s = 0; s < NUMSHAPES; ++s)
                        saveshape(handle, charsets[c].shapes[s]);
                }
                close(handle);
            }
            // All zones
            sprintf(ib2, "%s.map", ib1);
            handle = open(ib2, O_RDWR|O_BINARY|O_TRUNC|O_CREAT, S_IREAD|S_IWRITE);
            if (handle != -1)
            {
                writele16(handle, NUMZONES);
                for (int z = 0; z < NUMZONES; ++z)
                {
                    const Zone& zone = zones[z];
                    writele16(handle, zone.sx);
                    writele16(handle, zone.sy);
                    if (zone.sx && zone.sy)
                    {
                        writele16(handle, zone.x);
                        writele16(handle, zone.y);
                        write8(handle, zone.bg1);
                        write8(handle, zone.bg2);
                        write8(handle, zone.bg3);
                        write8(handle, zone.charset);
                        write8(handle, zone.fill);
                        write8(handle, 0); // Music, deprecated
                        write8(handle, zone.level);

                        // Find out amount of valid tiles (inside zone's current size)
                        std::vector<Tile> validtiles;
                        for (int t = 0; t < zone.tiles.size(); ++t)
                        {
                            const Tile& tile = zone.tiles[t];
                            if (tile.x >= 0 && tile.y >= 0 && tile.x < zone.sx && tile.y < zone.sy)
                                validtiles.push_back(tile);
                        }

                        writele32(handle, validtiles.size());
                        for (int t = 0; t < validtiles.size(); ++t)
                        {
                            const Tile& tile = validtiles[t];
                            write8(handle, tile.x);
                            write8(handle, tile.y);
                            write8(handle, tile.s);
                        }

                        // Find out amount of valid actors (inside zone's current size)
                        std::vector<Actor> validactors;
                        for (int t = 0; t < zone.actors.size(); ++t)
                        {
                            const Actor& actor = zone.actors[t];
                            if (actor.x >= 0 && actor.y >= 0 && actor.x < zone.sx && actor.y < zone.sy)
                                validactors.push_back(actor);
                        }

                        writele32(handle, validactors.size());
                        for (int t = 0; t < validactors.size(); ++t)
                        {
                            const Actor& actor = validactors[t];
                            write8(handle, actor.x);
                            write8(handle, actor.y);
                            write8(handle, actor.t);
                            write8(handle, actor.flags);
                        }

                        // Find out amount of valid objects (inside zone's current size)
                        std::vector<Object> validobjects;
                        for (int t = 0; t < zone.objects.size(); ++t)
                        {
                            const Object& object = zone.objects[t];
                            if (object.x >= 0 && object.y >= 0 && object.x < zone.sx && object.y < zone.sy)
                                validobjects.push_back(object);
                        }

                        writele32(handle, validobjects.size());
                        for (int t = 0; t < validobjects.size(); ++t)
                        {
                            const Object& object = validobjects[t];
                            write8(handle, object.x);
                            write8(handle, object.y);
                            write8(handle, object.sx);
                            write8(handle, object.sy);
                            write8(handle, object.flags);
                            write8(handle, object.frames);
                            writele16(handle, object.data);
                            if ((object.flags & 0xc) == 0x8 && (object.flags & 0x10) == 0x00)
                                printf("Object at %d,%d in zone %d is a switch without auto-deactivation\n", object.x, object.y, z);
                            if ((object.flags & 0x3) == 0x2 && (object.flags & 0xc) == 0xc && (object.flags & 0x10) == 0x10)
                                printf("Object at %d,%d in zone %d is a script with MAN mode auto-deactivation, consider using MAN.AD instead\n", object.x, object.y, z);
                        }
                    }
                }
                writele32(handle, mapx);
                writele32(handle, mapy);
                close(handle);
            }

            // C64 per-charset files
            for (int s = 0; s <= maxusedcharset; ++s)
            {
                Charset& charset = charsets[s];
                sprintf(ib2, "%s%02d.chr", ib1, s);
                handle = open(ib2, O_RDWR|O_BINARY|O_TRUNC|O_CREAT, S_IREAD|S_IWRITE);
                if (handle != -1)
                {
                    write(handle, charset.chardata, charset.usedchars*8);
                    close(handle);
                }
                sprintf(ib2, "%s%02d.bli", ib1, s);
                handle = open(ib2, O_RDWR|O_BINARY|O_TRUNC|O_CREAT, S_IREAD|S_IWRITE);
                if (handle != -1)
                {
                    write(handle, charset.blockinfos, NUMBLOCKS);
                    close(handle);
                }
                sprintf(ib2, "%s%02d.blk", ib1, s);
                handle = open(ib2, O_RDWR|O_BINARY|O_TRUNC|O_CREAT, S_IREAD|S_IWRITE);
                if (handle != -1)
                {
                    write(handle, charsets[s].blockdata, NUMBLOCKS*BLOCKDATASIZE);
                    close(handle);
                }
                sprintf(ib2, "%s%02d.chc", ib1, s);
                handle = open(ib2, O_RDWR|O_BINARY|O_TRUNC|O_CREAT, S_IREAD|S_IWRITE);
                if (handle != -1)
                {
                    write(handle, charsets[s].charcolors, 256);
                    close(handle);
                }

                charset.objectanim.clear();
                charset.objectanimmap.clear();

                // Build object animation data
                for (int z = 0; z < NUMZONES; ++z)
                {
                    const Zone& zone = zones[z];
                    if (zone.charset == s)
                    {
                        for (int o = 0; o < zone.objects.size(); ++o)
                        {
                            const Object& obj = zone.objects[o];
                            if (obj.frames > 1)
                            {
                                // Find corresponding shapenum at object
                                int t = findobjectshape(obj.x, obj.y, zone);
                                //printf("Object %d using shape %d for animation with %d frames\n", o, t, obj.frames);
                                if (t >= 0)
                                {
                                    if (charset.objectanimmap.find(t) == charset.objectanimmap.end())
                                    {
                                        charset.objectanimmap[t] = charset.objectanim.size();
                                        // Object must animate using adjacent shapes
                                        for (int f = t; f < t + obj.frames; ++f)
                                        {
                                            const Shape& shape = charset.shapes[f];
                                            //printf("Saving shape %d for animation sx %d sy %d\n", f, shape.sx, shape.sy);
                                            for (int cy = 0; cy < shape.sy; cy += 2)
                                            {
                                                for (int cx = 0; cx < shape.sx; cx += 2)
                                                    charset.objectanim.push_back(charset.shapeblocks[f][cy/2*MAXSHAPEBLOCKSIZE+cx/2]);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                sprintf(ib2, "%s%02d.oba", ib1, s);
                handle = open(ib2, O_RDWR|O_BINARY|O_TRUNC|O_CREAT, S_IREAD|S_IWRITE);
                if (handle != -1)
                {
                    if (charsets[s].objectanim.size())
                        write(handle, &charsets[s].objectanim[0], charsets[s].objectanim.size());
                    close(handle);
                }
            }
            // C64 packed levels
            LevelInfo infos[NUMLEVELS];
            for (int l = 0; l < NUMLEVELS; ++l)
            {
                infos[l].used = false;
                infos[l].zones.clear();
                infos[l].zonex.clear();
                infos[l].zoney.clear();
                infos[l].zonesize.clear();
                infos[l].actors = 0;
                infos[l].nonrespawnactors = 0;
                infos[l].actorbitstart = 0;
                infos[l].objects = 0;
                infos[l].objectbitstart = 0;
                infos[l].zonestart = 0;
            }
            int maxusedlevel = 0;

            unsigned char globalactx[NUMGLOBALACT];
            unsigned char globalacty[NUMGLOBALACT];
            unsigned char globalactt[NUMGLOBALACT];
            unsigned char globalactl[NUMGLOBALACT];
            unsigned char globalactz[NUMGLOBALACT];
            for (int c = 0; c < NUMGLOBALACT; ++c)
            {
                globalactx[c] = 0;
                globalacty[c] = 0;
                globalactt[c] = 0;
                globalactl[c] = 0;
                globalactz[c] = 0;
            }
            int gidx = 0;

            for (int z = 0; z < NUMZONES; ++z)
            {
                Zone& zone = zones[z];
                if (zone.sx && zone.sy)
                {
                    LevelInfo& level = infos[zone.level];
                    if (!level.used)
                    {
                        level.used = true;
                        if (zone.level > maxusedlevel)
                            maxusedlevel = zone.level;
                    }
                    zone.id = level.zones.size();

                    int validactors = 0;
                    int validnonrespawnactors = 0;
                    int validobjects = 0;
                    for (int c = 0; c < zone.actors.size(); ++c)
                    {
                        if (zone.actors[c].x < zone.sx && zone.actors[c].y < zone.sy)
                        {
                            if ((zone.actors[c].flags & 0x20) == 0)
                            {
                                ++validactors;
                                if ((zone.actors[c].flags & 0x40) == 0)
                                    ++validnonrespawnactors;
                            }
                            else
                            {
                                if (gidx < NUMGLOBALACT)
                                {
                                    globalactx[gidx] = zone.actors[c].x;
                                    globalacty[gidx] = zone.actors[c].y;
                                    globalactt[gidx] = zone.actors[c].t;
                                    globalactz[gidx] = zone.id | (zone.actors[c].flags & 0x80);
                                    globalactl[gidx] = zone.level;
                                    ++gidx;
                                }
                            }
                       }
                    }
                    for (int c = 0; c < zone.objects.size(); ++c)
                    {
                        if (zone.objects[c].x < zone.sx && zone.objects[c].y < zone.sy)
                            ++validobjects;
                    }

                    level.actors += validactors;
                    level.nonrespawnactors += validnonrespawnactors;
                    level.objects += validobjects;
                    level.zones.push_back(z);
                    level.zonex.push_back(zone.x / SCREENSIZEX);
                    level.zoney.push_back(zone.y / SCREENSIZEY);
                    int zssx = zone.sx / SCREENSIZEX;
                    int zssy = (zone.y+zone.sy-1-(zone.y/SCREENSIZEY*SCREENSIZEY))/SCREENSIZEY+1;
                    level.zonesize.push_back(zssx | (zssy<<4));
                }
            }

            int totalmapdatasize = 0;
            int screensize = 0;
            int totalactorbitsize = 0;
            int totalobjectbitsize = 0;
            int totalzones = 0;

            // Calculate actor / object bit startindex for each level
            for (int s = 0; s <= maxusedlevel; ++s)
            {
                infos[s].actorbitstart = totalactorbitsize;
                int bitsize = (infos[s].nonrespawnactors+7)/8;
                totalactorbitsize += bitsize;
            }
            for (int s = 0; s <= maxusedlevel; ++s)
            {
                infos[s].objectbitstart = totalobjectbitsize;
                int bitsize = (infos[s].objects+7)/8;
                totalobjectbitsize += bitsize;
            }
            for (int s = 0; s <= maxusedlevel; ++s)
            {
                infos[s].zonestart = totalzones;
                totalzones += infos[s].zones.size();
            }

            for (int s = 0; s <= maxusedlevel; ++s)
            {
                LevelInfo& level = infos[s];
                if (!level.used)
                    continue;
                int activezones = level.zones.size();
                int datasize = 0;
                std::vector<std::vector<unsigned char> > zonepackdata;
                std::vector<unsigned short> objectoffsets;

                for (int z = 0; z < level.zones.size(); ++z)
                {
                    const Zone& zone = zones[level.zones[z]];
                    const Charset& charset = charsets[zone.charset];
                    int zonemapdatasize = zone.sx * zone.sy;
                    int num = level.zones[z];
                    totalmapdatasize += zonemapdatasize;
                    screensize += (zone.sx / SCREENSIZEX) * (zone.sy / SCREENSIZEY);

                    // Now build the actual zone data
                    unsigned char* zonemapdata = new unsigned char[zonemapdatasize];
                    const Shape& fillshape = charset.shapes[zone.fill];
                    memset(zonemapdata, 0, zonemapdatasize);
                    if (fillshape.sx == 1 && fillshape.sy == 1)
                    {
                        for (int y = 0; y < zone.sy; y += fillshape.sy/2)
                        {
                            for (int x = 0; x < zone.sx; x += fillshape.sx/2)
                                drawc64shape(x, y, zone.fill, zone, charset, zonemapdata);
                        }
                    }
                    else
                        memset(zonemapdata, 254, zonemapdatasize);

                    for (int t = 0; t < zone.tiles.size(); ++t)
                        drawc64shape(zone.tiles[t].x, zone.tiles[t].y, zone.tiles[t].s, zone, charset, zonemapdata);

                    std::vector<unsigned char> rledata = rlepack(&zonemapdata[0], zonemapdatasize);
                    // Add fill shape information after RLE data if necessary
                    // Todo: could store only once, if shape is the same
                    if (fillshape.sx > 1 || fillshape.sy > 1)
                    {
                        rledata.push_back((fillshape.sx/2) | ((fillshape.sy/2) << 4));
                        for (int by = 0; by < fillshape.sy/2; ++by)
                        {
                            for (int bx = 0; bx < fillshape.sx/2; ++bx)
                                rledata.push_back(charset.shapeblocks[zone.fill][by*MAXSHAPEBLOCKSIZE+bx]);
                        }
                    }
                    else
                        rledata.push_back(0);

                    zonepackdata.push_back(rledata);
                    delete[] zonemapdata;
                }

                // 1 object for all other exomized data + zone packs
                datasize = (1+zonepackdata.size())*2;
                objectoffsets.push_back(datasize);

                unsigned char zoneandobjectdata[4*NUMLVLZONES+8*NUMLVLOBJ+4*NUMLVLACT];

                unsigned char* zonedata = &zoneandobjectdata[0];
                memset(zonedata, 0, 4*NUMLVLZONES);
                for (int z = 0; z < level.zones.size(); ++z)
                {
                    const Zone& zone = zones[level.zones[z]];
                    zonedata[z+0*NUMLVLZONES] = zone.charset;
                    zonedata[z+1*NUMLVLZONES] = zone.bg1;
                    zonedata[z+2*NUMLVLZONES] = zone.bg2;
                    zonedata[z+3*NUMLVLZONES] = zone.bg3;
                }

                unsigned char* objectdata = &zoneandobjectdata[4*NUMLVLZONES];
                memset(objectdata, 0, 8*NUMLVLOBJ);
                unsigned usedobj = 0;

                for (int z = 0; z < level.zones.size(); ++z)
                {
                    const Zone& zone = zones[level.zones[z]];

                    for (int c = 0; c < zone.objects.size() && usedobj < NUMLVLOBJ; ++c)
                    {
                        const Object& object = zone.objects[c];
                        if (object.x < zone.sx && object.y < zone.sy)
                        {
                            int t = findobjectshape(object.x, object.y, zone);
                            objectdata[usedobj+0*NUMLVLOBJ] = object.x;
                            objectdata[usedobj+1*NUMLVLOBJ] = object.y;
                            objectdata[usedobj+2*NUMLVLOBJ] = zone.id;
                            objectdata[usedobj+3*NUMLVLOBJ] = object.flags;
                            objectdata[usedobj+4*NUMLVLOBJ] = (object.sx-1) | ((object.sy-1) << 2) | ((object.frames-1) << 4);
                            objectdata[usedobj+5*NUMLVLOBJ] = object.frames > 1 ? charsets[zone.charset].objectanimmap[t] : 0;
                            objectdata[usedobj+6*NUMLVLOBJ] = object.data & 0xff;
                            objectdata[usedobj+7*NUMLVLOBJ] = object.data >> 8;
                            ++usedobj;
                        }
                    }
                }

                unsigned char* actordata = &zoneandobjectdata[4*NUMLVLZONES+8*NUMLVLOBJ];
                memset(actordata, 0, 4*NUMLVLACT);
                unsigned usedact = 0;

                for (int z = 0; z < level.zones.size(); ++z)
                {
                    const Zone& zone = zones[level.zones[z]];

                    for (int c = 0; c < zone.actors.size() && usedact < NUMLVLACT; ++c)
                    {
                        const Actor& actor = zone.actors[c];
                        // Globalactors stored separately
                        if (actor.x < zone.sx && actor.y < zone.sy && (actor.flags & 0x20) == 0)
                        {
                            actordata[usedact+0*NUMLVLACT] = actor.x;
                            actordata[usedact+1*NUMLVLACT] = actor.y;
                            actordata[usedact+2*NUMLVLACT] = actor.t;
                            actordata[usedact+3*NUMLVLACT] = zone.id | actor.flags;
                            ++usedact;
                        }
                    }
                }

                std::vector<unsigned char> packedzoneobjectdata = exomize(zoneandobjectdata, 4*NUMLVLZONES+8*NUMLVLOBJ+4*NUMLVLACT);

                datasize += packedzoneobjectdata.size();

                for (int z = 0; z < zonepackdata.size(); ++z)
                {
                    objectoffsets.push_back(datasize);
                    datasize += zonepackdata[z].size();
                }

                sprintf(ib2, "%s%02d.map", ib1, s);
                handle = open(ib2, O_RDWR|O_BINARY|O_TRUNC|O_CREAT, S_IREAD|S_IWRITE);
                if (handle != -1)
                {
                    write8(handle, datasize&0xff);
                    write8(handle, datasize>>8);
                    write8(handle, zonepackdata.size()+1);
                    for (int z = 0; z < objectoffsets.size(); ++z)
                        writele16(handle, objectoffsets[z]);
                    write(handle, &packedzoneobjectdata[0], packedzoneobjectdata.size());
                    for (int z = 0; z < zonepackdata.size(); ++z)
                        write(handle, &zonepackdata[z][0], zonepackdata[z].size());
                    close(handle);
                }
            }

            sprintf(ib2, "%sinfo.s", ib1);
            FILE* out = fopen(ib2, "wt");
            if (out)
            {
                fprintf(out, "NUMLEVELS = %d\n\n", maxusedlevel+1);
                fprintf(out, "NUMZONES = %d\n\n", totalzones);
                fprintf(out, "WORLDSIZEBLOCKS = %d\n\n", totalmapdatasize);
                fprintf(out, "WORLDSIZESCREENS = %d\n\n", screensize);
                fprintf(out, "LEVELACTBITSIZE = %d\n\n", totalactorbitsize);
                fprintf(out, "LEVELOBJBITSIZE = %d\n\n", totalobjectbitsize);
                fprintf(out, "ZONEBITSIZE = %d\n\n", (totalzones+7)/8);
                fclose(out);
            }
            sprintf(ib2, "%slevel.s", ib1);
            out = fopen(ib2, "wt");
            if (out)
            {
                fprintf(out, "lvlActBitStart:\n");
                for (int c = 0; c < maxusedlevel+1; c++)
                {
                    fprintf(out, "                dc.b %d\n", infos[c].actorbitstart);
                }
                fprintf(out, "                dc.b %d\n", totalactorbitsize);

                fprintf(out, "lvlObjBitStart:\n");
                for (int c = 0; c < maxusedlevel+1; c++)
                {
                    fprintf(out, "                dc.b %d\n", infos[c].objectbitstart);
                }
                fprintf(out, "                dc.b %d\n", totalobjectbitsize);

                fprintf(out, "lvlZoneStart:\n");
                for (int c = 0; c < maxusedlevel+1; c++)
                {
                    fprintf(out, "                dc.b %d\n", infos[c].zonestart);
                }
                fprintf(out, "                dc.b %d\n", totalzones);
                
                
                fprintf(out, "lvlNumActors:\n");
                for (int c = 0; c < maxusedlevel+1; c++)
                {
                    fprintf(out, "                dc.b %d\n", infos[c].actors);
                }

                fclose(out);
            }
            sprintf(ib2, "%szone.s", ib1);
            out = fopen(ib2, "wt");
            if (out)
            {
                fprintf(out, "zoneX:\n");

                for (int c = 0; c < maxusedlevel+1; c++)
                {

                    for (int z = 0; z < infos[c].zonex.size(); ++z)
                    {
                        fprintf(out, "                dc.b %d\n", infos[c].zonex[z]);
                    }
                }
                fprintf(out, "\n");

                fprintf(out, "zoneY:\n");
                for (int c = 0; c < maxusedlevel+1; c++)
                {
                    for (int z = 0; z < infos[c].zoney.size(); ++z)
                    {
                        fprintf(out, "                dc.b %d\n", infos[c].zoney[z]);
                    }
                }
                fprintf(out, "\n");

                fprintf(out, "zoneSize:\n");
                for (int c = 0; c < maxusedlevel+1; c++)
                {
                    for (int z = 0; z < infos[c].zonesize.size(); ++z)
                    {
                        fprintf(out, "                dc.b %d\n", infos[c].zonesize[z]);
                    }
                }
                fprintf(out, "\n");
                fclose(out);
            }

            sprintf(ib2, "%sglobalact.s", ib1);
            out = fopen(ib2, "wt");
            if (out)
            {
                fprintf(out, "NUMGLOBALACT = %d\n\n", gidx);
                fprintf(out, "startGlobalActX:\n");
                for (int c = 0; c < NUMGLOBALACT; c++)
                {
                    fprintf(out, "                dc.b %d\n", globalactx[c]);
                }
                fprintf(out, "\nstartGlobalActY:\n");
                for (int c = 0; c < NUMGLOBALACT; c++)
                {
                    fprintf(out, "                dc.b %d\n", globalacty[c]);
                }
                fprintf(out, "\nstartGlobalActT:\n");
                for (int c = 0; c < NUMGLOBALACT; c++)
                {
                    fprintf(out, "                dc.b %d\n", globalactt[c]);
                }
                fprintf(out, "\nstartGlobalActZ:\n");
                for (int c = 0; c < NUMGLOBALACT; c++)
                {
                    fprintf(out, "                dc.b %d\n", globalactz[c]);
                }
                fprintf(out, "\nstartGlobalActL:\n");
                for (int c = 0; c < NUMGLOBALACT; c++)
                {
                    fprintf(out, "                dc.b %d\n", globalactl[c]);
                }
                fprintf(out, "\n");
                fclose(out);
            }

            return;
        }
    }
}

void loadalldata()
{
    char ib1[80];
    strcpy(ib1, levelname);

    int maxusedcharset = 0;

    for (;;)
    {
        int r;

        win_getspeed(70);
        gfx_fillscreen(254);

        printtext_center_color("LOAD ALL LEVELDATA:",screensizey/2-10,SPR_FONTS,COL_WHITE);
        printtext_center_color(ib1,screensizey/2,SPR_FONTS,COL_HIGHLIGHT);
        gfx_updatepage();

        r = inputtext(ib1, 80);
        if (r == -1) return;
        if (r == 1)
        {
            int c;
            int handle;
            char ib2[80];
            char ib3[80];

            if (!strlen(ib1))
                return;

            // All charsets
            sprintf(ib2, "%s.chr", ib1);
            handle = open(ib2, O_RDONLY|O_BINARY, S_IREAD);
            if (handle != -1)
            {
                strcpy(levelname, ib1);
                int numcharsets = readle16(handle);
                for (int c = 0; c < numcharsets; ++c)
                {
                    int numshapes = readle16(handle);
                    for (int s = 0; s < numshapes; ++s)
                        loadshape(handle, charsets[c].shapes[s]);
                    packcharset(charsets[c]);
                }
                close(handle);
            }

            // All zones
            sprintf(ib2, "%s.map", ib1);
            handle = open(ib2, O_RDONLY|O_BINARY, S_IREAD);
            if (handle != -1)
            {
                int numzones = readle16(handle);
                for (int z = 0; z < numzones; ++z)
                {
                    Zone& zone = zones[z];
                    resetzone(zone);

                    zone.sx = readle16(handle);
                    zone.sy = readle16(handle);
                    if (zone.sx && zone.sy)
                    {
                        zone.x = readle16(handle);
                        zone.y = readle16(handle);
                        zone.bg1 = read8(handle);
                        zone.bg2 = read8(handle);
                        zone.bg3 = read8(handle);
                        zone.charset = read8(handle);
                        zone.fill = read8(handle);
                        read8(handle); // Music, deprecated
                        zone.level = read8(handle);
                        zone.tiles.resize(readle32(handle));
                        for (int t = 0; t < zone.tiles.size(); ++t)
                        {
                            Tile& tile = zone.tiles[t];
                            tile.x = read8(handle);
                            tile.y = read8(handle);
                            tile.s = read8(handle);
                        }
                        
                        zone.actors.resize(readle32(handle));
                        for (int a = 0; a < zone.actors.size(); ++a)
                        {
                            Actor& actor = zone.actors[a];
                            actor.x = read8(handle);
                            actor.y = read8(handle);
                            actor.t = read8(handle);
                            actor.flags = read8(handle);
                            // Convert actor type if xlat tables set
                            if (actor.t < 0x80 && strlen(actorxlatdest[0]))
                            {
                                const char* srcname = actorxlatsrc[actor.t];
                                for (int t = 0; t < 128; ++t)
                                {
                                    if (!strlen(actorxlatdest[t]))
                                        break;
                                    if (!strcmp(srcname, actorxlatdest[t]))
                                    {
                                        actor.t = t;
                                        break;
                                    }
                                }
                            }
                        }
                        
                        zone.objects.resize(readle32(handle));
                        for (int o = 0; o < zone.objects.size(); ++o)
                        {
                            Object& object = zone.objects[o];
                            object.x = read8(handle);
                            object.y = read8(handle);
                            object.sx = read8(handle);
                            object.sy = read8(handle);
                            object.flags = read8(handle);
                            object.frames = read8(handle);
                            object.data = readle16(handle);
                        }
                    }
                }
                if (!eof(handle))
                {
                    mapx = readle32(handle);
                    mapy = readle32(handle);
                }

                close(handle);
            }

            shapeusedirty = true;
            return;
        }
    }
}

std::vector<unsigned char> exomize(unsigned char* data, int datasize)
{
    int exosrchandle, exodesthandle;

    exosrchandle = open("temp.bin", O_RDWR|O_BINARY|O_TRUNC|O_CREAT, S_IREAD|S_IWRITE);
    write(exosrchandle, data, datasize);
    close(exosrchandle);

    system("exomizer208 level -M255 -c -f -otemp.pak temp.bin@0");
    exodesthandle = open("temp.pak", O_RDONLY|O_BINARY, S_IREAD);
    
    std::vector<unsigned char> ret;

    if (exodesthandle != -1)
    {
        // Skip first 2 bytes of packed output (dest.address)
        int packedsize = lseek(exodesthandle, 0, SEEK_END) - 2;
        lseek(exodesthandle, 2, SEEK_SET);
        ret.resize(packedsize);
        if (packedsize > 0)
            read(exodesthandle, &ret[0], packedsize);
        close(exodesthandle);
    }
    unlink("temp.bin");
    unlink("temp.pak");
    return ret;
}

std::vector<unsigned char> rlepack(unsigned char* data, int datasize)
{
    int emittedpos = 0;
    int pos = 0;
    std::vector<unsigned char> ret;

    while (pos < datasize)
    {
        int seqlength = 1;
        for (int seqpos = pos + 1; seqpos < datasize && seqpos - pos < 255; ++seqpos)
        {
            if (data[seqpos] == data[pos])
                ++seqlength;
            else
                break;
        }
        if (seqlength >= 4)
        {
            while (emittedpos < pos)
                ret.push_back(data[emittedpos++]);
            ret.push_back(0xff);
            ret.push_back(seqlength);
            ret.push_back(data[pos]);
            pos += seqlength;
            emittedpos = pos;
        }
        else
        {
            ++pos;
        }
    }
    while (emittedpos < pos)
        ret.push_back(data[emittedpos++]);
    ret.push_back(0xff); // Endmark
    ret.push_back(0);

    return ret;
}

void exportpng()
{
    char ib1[80];
    strcpy(ib1, levelname);

    for (;;)
    {
        int r;
        win_getspeed(70);
        gfx_fillscreen(254);

        printtext_center_color("EXPORT WHOLE MAP TO:",screensizey/2-10,SPR_FONTS,COL_WHITE);
        printtext_center_color(ib1,screensizey/2,SPR_FONTS,COL_HIGHLIGHT);
        gfx_updatepage();

        r = inputtext(ib1, 80);
        if (r == -1) return;
        if (r == 1)
        {
            char filename[256];
            int minx = 0xffff, miny = 0xffff;
            int maxx = 0, maxy = 0;
            for (int z = 0; z < NUMZONES; z++)
            {
                const Zone& zone = zones[z];
                if (zone.sx && zone.sy)
                {
                    if (zone.x < minx)
                        minx = zone.x;
                    if (zone.y < miny)
                        miny = zone.y;
                    if (maxx < zone.x + zone.sx)
                        maxx = zone.x + zone.sx;
                    if (maxy < zone.y + zone.sy)
                        maxy = zone.y + zone.sy;
                }
            }

            int sizex = (maxx-minx)*16;
            int sizey = (maxy-miny)*16;
            unsigned char* image = new unsigned char[sizey*sizex*3];
            if (image)
            {
                memset(image, 0, sizey*sizex*3);
                sprintf(filename, "%s.png", ib1);

                for (int z = 0; z < NUMZONES; ++z)
                {
                    const Zone& zone = zones[z];
                    if (zone.sx && zone.sy)
                    {
                        const Charset& charset = charsets[zone.charset];
                        const Shape& fillshape = charset.shapes[zone.fill];
                        // Draw fillshape as background
                        if (fillshape.sx && fillshape.sy)
                        {
                            // Fillshape size in blocks
                            int fsx = fillshape.sx/2;
                            int fsy = fillshape.sy/2;
                            for (int cy = 0; cy < zone.sy; cy += fsy)
                            {
                                for (int cx = 0; cx < zone.sx; cx += fsx)
                                    drawzoneshapepng(cx, cy, zone.fill, zone, image, sizex, sizey, minx, miny);
                            }
                        }
                        // Draw zone tiles (shapes)
                        for (int t = 0; t < zone.tiles.size(); ++t)
                            drawzoneshapepng(zone.tiles[t].x, zone.tiles[t].y, zone.tiles[t].s, zone, image, sizex, sizey, minx, miny);
                    }
                }

                stbi_write_png(filename, sizex, sizey, 3, image, 0);
                delete[] image;
            }
            return;
        }
    }
}

void nukecharset()
{
    bool nuke = false;
    for (;;)
    {
        win_getspeed(70);
        gfx_fillscreen(254);
        printtext_center_color("NUKE ENTIRE CHARSET?",screensizey/2 - 10,SPR_FONTS,COL_WHITE);
        printtext_center_color("PRESS Y TO CONFIRM",screensizey/2 + 10,SPR_FONTS,COL_WHITE);
        gfx_updatepage();
        int key = kbd_getascii();
        if (key)
        {
            nuke = (key == 'y');
            break;
        }
    }

    if (nuke)
    {
        for (int i = charsetnum; i < NUMCHARSETS-1; ++i)
            charsets[i] = charsets[i+1];
        for (int i = 0; i < NUMZONES; ++i)
        {
            Zone& zone = zones[i];
            if (zone.sx && zone.sy && zone.charset > charsetnum)
                --zone.charset;
        }
    }
}

void packcharset(Charset& charset)
{
    int usedchars = 0;
    int usedblocks = 0;

    std::map<CharKey, unsigned char> charmapping;
    std::map<BlockKey, unsigned char> blockmapping;
    memset(charset.chardata, 0, sizeof charset.chardata);
    memset(charset.blockdata, 0, sizeof charset.blockdata);
    memset(charset.blockinfos, 0, sizeof charset.blockinfos);
    charset.errored = false;

    for (unsigned s = 0; s < NUMSHAPES; ++s)
    {
        const Shape& shape = charset.shapes[s];
        unsigned char* shapechardata = charset.shapechars[s];

        if (shape.sx && shape.sy)
        {
            for (int cy = 0; cy < shape.sy; ++cy)
            {
                for (int cx = 0; cx < shape.sx; ++cx)
                {
                    CharKey ckey;
                    const unsigned char* chardata = &shape.chardata[(cy*MAXSHAPESIZE+cx)*8];
                    ckey.first = chardata[0]
                            | (((unsigned long long)chardata[1]) << 8)
                            | (((unsigned long long)chardata[2]) << 16)
                            | (((unsigned long long)chardata[3]) << 24)
                            | (((unsigned long long)chardata[4]) << 32)
                            | (((unsigned long long)chardata[5]) << 40)
                            | (((unsigned long long)chardata[6]) << 48)
                            | (((unsigned long long)chardata[7]) << 56);

                    unsigned char chcol = shape.charcolors[cy*MAXSHAPESIZE+cx] & 0xf;
                    ckey.second = chcol;
                    // If empty, use color of first char as search key
                    if (!ckey.first)
                        ckey.second = usedchars > 0 ? charset.charcolors[0] : 8;

                    // If multicolor, check if actually uses char color, convert search key color to first char's color if not
                    // Do not actually modify char color to not mess up potential animations
                    if (ckey.first && ckey.second >= 8)
                    {
                        bool usecharcolor = false;
                        unsigned long long keycopy = ckey.first;
                        while (keycopy)
                        {
                            if ((keycopy & 3) == 3)
                            {
                                usecharcolor = true;
                                break;
                            }
                            keycopy >>= 2;
                        }
                        if (!usecharcolor && usedchars > 0 && charset.charcolors[0] >= 8)
                            ckey.second = charset.charcolors[0];
                        else if (!usecharcolor && usedchars > 0)
                            ckey.second = 8;
                    }

                    std::map<CharKey, unsigned char>::const_iterator i = charmapping.find(ckey);
                    if (i == charmapping.end())
                    {
                        // All chars already used?
                        if (usedchars == 255)
                            charset.errored = true;
                        else
                        {
                            charmapping[ckey] = usedchars;
                            memcpy(&charset.chardata[usedchars*8], chardata, 8);
                            charset.charcolors[usedchars] = chcol;
                            shapechardata[cy*MAXSHAPESIZE+cx] = usedchars;
                            ++usedchars;
                        }
                    }
                    else
                        shapechardata[cy*MAXSHAPESIZE+cx] = i->second;
                }
            }

            for (int cy = 0; cy < shape.sy; cy += 2)
            {
                for (int cx = 0; cx < shape.sx; cx += 2)
                {
                    BlockKey bkey;
                    bkey.first = shapechardata[cy*MAXSHAPESIZE+cx]
                        | (((unsigned)shapechardata[cy*MAXSHAPESIZE+cx+1]) << 8)
                        | (((unsigned)shapechardata[(cy+1)*MAXSHAPESIZE+cx]) << 16)
                        | (((unsigned)shapechardata[(cy+1)*MAXSHAPESIZE+cx+1]) << 24);
                    bkey.second = shape.blockinfos[cy/2*MAXSHAPEBLOCKSIZE+cx/2];

                    std::map<BlockKey, unsigned char>::const_iterator i = blockmapping.find(bkey);
                    if (i == blockmapping.end())
                    {
                        // All blocks already used?
                        if (usedblocks == 254)
                            charset.errored = true;
                        else
                        {
                            blockmapping[bkey] = usedblocks;
                            charset.blockdata[usedblocks] = shapechardata[cy*MAXSHAPESIZE+cx];
                            charset.blockdata[usedblocks+256] = shapechardata[cy*MAXSHAPESIZE+cx+1];
                            charset.blockdata[usedblocks+512] = shapechardata[(cy+1)*MAXSHAPESIZE+cx];
                            charset.blockdata[usedblocks+768] = shapechardata[(cy+1)*MAXSHAPESIZE+cx+1];
                            charset.blockinfos[usedblocks] = shape.blockinfos[cy/2*MAXSHAPEBLOCKSIZE+cx/2];
                            charset.shapeblocks[s][cy/2*MAXSHAPEBLOCKSIZE+cx/2] = usedblocks;
                            ++usedblocks;
                        }
                    }
                    else
                        charset.shapeblocks[s][cy/2*MAXSHAPEBLOCKSIZE+cx/2] = i->second;
                }
            }
        }
    }

    charset.usedchars = usedchars;
    charset.usedblocks = usedblocks;
    charset.dirty = false;
}

void drawc64shape(int x, int y, unsigned char num, const Zone& zone, const Charset& charset, unsigned char* dest)
{
    const Shape& shape = charset.shapes[num];
    for (int cy = 0; cy < shape.sy/2; ++cy)
    {
        for (int cx = 0; cx < shape.sx/2; ++cx)
        {
            int bx = x+cx;
            int by = y+cy;

            if (bx < 0 || by < 0 || bx >= zone.sx || by >= zone.sy)
                continue;

            dest[by * zone.sx + bx] = charset.shapeblocks[num][cy*MAXSHAPEBLOCKSIZE+cx];
        }
    }
}
