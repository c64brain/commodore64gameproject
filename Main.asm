;===============================================================================
; SCROLLING MAP EXAMPLE 1 - C64 YouTube Game Project
; 2016/17 - Peter 'Sig' Hewett aka RetroRomIcon (contributions)
; Additional coding by Steve Morrow

;===============================================================================
Operator Calc        ; IMPORTANT - calculations are made BEFORE hi/lo bytes
                     ;             in precidence (for expressions and tables)
;===============================================================================
;                                                                   DEFINITIONS
;===============================================================================
IncAsm "VIC_Registers.asm"             ; VICII register includes
IncAsm "Game_Macros.asm"                    ; macro includes
;===============================================================================
;===============================================================================
;                                                                     CONSTANTS
;===============================================================================

#region "Constants"
SCREEN_MEM   = $4000
SCREEN1_MEM  = $4000                 ; Bank 1 - Screen 0 ; $4000
SCREEN2_MEM  = $4400                 ; Bank 1 - Screen 1 ; $4400
SCORE_SCREEN = $5800                 ; Bank 1 - Screen 6 ; $5800

COLOR_MEM  = $D800                   ; Color mem never changes
CHAR_MEM   = $4800                   ; Base of character set memory (set 1)

LEVEL_1_MAP   = $E000                ;Address of level 1 tiles/charsets
LEVEL_1_CHARS = $E800
#endregion

;===============================================================================
; ZERO PAGE LABELS
;===============================================================================
#region "ZeroPage"
PARAM1 = $03                 ; These will be used to pass parameters to routines
PARAM2 = $04                 ; when you can't use registers or other reasons
PARAM3 = $05                            
PARAM4 = $06                 ; essentially, think of these as extra data registers
PARAM5 = $07

;---------------------------- $11 - $16 available

ZEROPAGE_POINTER_1 = $17     ; Similar only for pointers that hold a word long address
ZEROPAGE_POINTER_2 = $19
ZEROPAGE_POINTER_3 = $21
ZEROPAGE_POINTER_4 = $23

CURRENT_SCREEN   = $25       ; Pointer to current front screen
CURRENT_BUFFER   = $27       ; Pointer to current back buffer

                            ; All data is for the top left corner of the visible map area
MAP_POS_ADDRESS = $2E       ; (2 bytes) pointer to current address in the level map
MAP_X_POS       = $30       ; Current map x position (in tiles)
MAP_Y_POS       = $31       ; Current map y position (in tiles)
MAP_X_DELTA     = $32       ; Map sub tile delta (in characters)
MAP_Y_DELTA     = $33       ; Map sub tile delta (in characters)

#endregion

;===============================================================================
; BASIC KICKSTART
;===============================================================================
KICKSTART
; Sys call to start the program - 10 SYS (2064)

*=$0801

        BYTE $0E,$08,$0A,$00,$9E,$20,$28,$32,$30,$36,$34,$29,$00,$00,$00

;===============================================================================
; START OF GAME PROJECT
;===============================================================================
*=$0810

PRG_START

        lda VIC_SCREEN_CONTROL          ; turn screen off with bit 4
        and #%11100000                  ; mask out bit 4 - Screen on/off
        sta VIC_SCREEN_CONTROL          ; save back - setting bit 4 to off

;===============================================================================
; SETUP VIC BANK MEMORY
;===============================================================================
#region "VIC Setup"
        ; To set the VIC bank we have to change the first 2 bits in the
        ; CIA 2 register. So we want to be careful and only change the
        ; bits we need to.

        lda VIC_BANK            ; Fetch the status of CIA 2 ($DD00)
        and #%11111100          ; mask for bits 2-8
        ora #%00000010          ; the first 2 bits are your desired VIC bank value
                                ; In this case bank 1 ($4000 - $7FFF)
        sta VIC_BANK
;===============================================================================
; CHARACTER SET ENABLE: SCREEN MEMORY
;===============================================================================
        ; Within the VIC Bank we can set where we want our screen and character
        ; set memory to be using the VIC_MEMORY_CONTROL at $D018
        ; It is important to note that the values given are RELATIVE to the start
        ; address of the VIC bank you are using.
       
        lda #%00000010   ; bits 1-3 (001) = character memory 2 : $0800 - $0FFF
                         ; bits 4-7 (000) = screen memory 0 : $0000 - $03FF

        sta VIC_MEMORY_CONTROL

        ; Because these are RELATIVE to the VIC banks base address (Bank 1 = $4000)
        ; this gives us a base screen memory address of $4000 and a base
        ; character set memory of $4800
        ; 
        ; Sprite pointers are the last 8 bytes of screen memory (25 * 40 = 1000 and
        ; yet each screen reserves 1024 bytes). So Sprite pointers start at
        ; $4000 + $3f8.

        ; After alloction of VIC Memory for Screen, backbuffer, scoreboard, and
        ; 2 character sets , arranged to one solid block of mem,
        ; Sprite data starts at $5C00 - giving the initial image a pointer value of $70
        ; and allowing for up to 144 sprite images

#endregion        
;===============================================================================
; SYSTEM INITIALIZATION
;===============================================================================
#region "System Setup"
System_Setup

        ; Here is where we copy level 1 data from the start setup to under
        ; $E000 so we can use it later when the game resets.
        ; A little bank switching is involved here.
        sei           

        ; Here you load and store the Processor Port ($0001), then use 
        ; it to turn off LORAM (BASIC), HIRAM (KERNAL), CHAREN (CHARACTER ROM)
        ; then use a routine to copy your sprite and character mem under there
        ; before restoring the original value of $0001 and turning interrupts
        ; back on.

        lda PROC_PORT                   ; store ram setup
        sta PARAM1

        lda #%00110000                  ; Switch out BASIC, KERNAL, CHAREN, IO
        sta PROC_PORT

        ; When the game starts, Level 1 tiles and characters are stored in place to run,
        ; However, when the game resets we will need to restore these levels intact.
        ; So we're saving them away to load later under the KERNAL at $E000-$EFFF (4k)
        ; To do this we need to do some bank switching, copy data, then restore as
        ; we may use the KERNAL later for some things.

        loadPointer ZEROPAGE_POINTER_1, MAP_MEM         ; source
        loadPointer ZEROPAGE_POINTER_2, LEVEL_1_MAP     ; destination

        jsr CopyChars                   ; CopyChars for charsets copys 2048 bytes of character
                                        ; data, the same size as our tile maps, so we use that
                                        ; routine

        loadPointer ZEROPAGE_POINTER_1, CHAR_MEM
        loadPointer ZEROPAGE_POINTER_2, LEVEL_1_CHARS

        jsr  CopyChars

        lda PARAM1                      ; restore ram setup
        sta PROC_PORT
        cli
#endregion
;===============================================================================
; SCREEN SETUP
;===============================================================================
#region "Screen Setup"
Screen_Setup
        lda #COLOR_BLACK
        sta VIC_BACKGROUND_COLOR 
        lda #COLOR_ORANGE
        sta VIC_CHARSET_MULTICOLOR_1
        lda #COLOR_BROWN
        sta VIC_CHARSET_MULTICOLOR_2

        loadPointer CURRENT_SCREEN,SCREEN1_MEM
        loadPointer CURRENT_BUFFER,SCREEN2_MEM

        lda #$40                        ; Use #$40 as the fill character on GameScreen
        jsr ClearScreen1                ; Clear both screens (double buffer)
        jsr ClearScreen2 

;**************************** Map Position ************************************

        ;-------------------------------------------------- CHARPAD LEVEL SETUP
        lda #1                          ; Start Level = 1
        sta CURRENT_LEVEL
        jsr LoadLevel                   ; load level 1 data

        ldx #27                        ; Y start pos (in tile coords) (129,26=default)
        ldy #0                          ; X start pos (in tile coords)

        jsr DrawMap                     ; Draw the level map (Screen1)
                                        ; And initialize it

        jsr CopyToBuffer                ; Copy to the backbuffer(Screen2)

        ;-------------------------------------------------  DEBUG CONSOLE

                                        ; Display the Debug Console Text
       
        ;-------------------------------------------------  RASTER SETUP
        jsr InitRasterIRQ               ; Setup raster interrupts
        
        lda #%00011011                  ; Default (Y scroll = 3 by default)                                     ; 
        sta VIC_SCREEN_CONTROL
        lda #COLOR_BLACK
        sta VIC_BORDER_COLOR


MapDisplay
        jmp MapDisplay

#endregion

;===============================================================================
; FILES IN GAME PROJECT
;===============================================================================
        incAsm "Game_Routines.asm"                  ; core framework routines
        incAsm "Game_Interrupts.asm"
        incAsm "Start_Level.asm
        incAsm "Screen_Memory.asm"

*=$4800
MAP_CHAR_MEM                            ; Character set for map screen
;incbin"Turrican Map/Turrican_Chset1a.bin"
incbin"Parkour_Maps/Parkour Redo Chset6.bin"

;===================================================================================================
;                                                                                     LEVEL DATA
;===================================================================================================
; Each Level has a character set (2k) an attribute/color list (256 bytes) 64 4x4 tiles (1k)
; and a 64 x 32 (or 32 x 64) map (2k).

; The current level map will be put at $8000 with Attribute lists (256 bytes) and Tiles (1k)
; Starting after it at 8800

; With additional levels to be stored at $9000 and $C000 and if new attributes and Tiles are needed
; I'll find a place to put them
;
; In order for the world to reset, the first map and chars will be backed up at $D000
; under the VIC registers IO with bank switching at startup, and restored at game restart
;
; New levels are loaded into these spaces.
;---------------------------------------------------------------------------------------------------
*=$8000

MAP_MEM
;incbin"Turrican Map/Turrican_Map1a.bin"
;incbin"Parkour_Maps/Parkour Redo Map4d.bin"
incbin"Parkour_Maps/Parkour Redo Map6.bin"


ATTRIBUTE_MEM
;incbin"Parkour_Maps/Parkour Redo ChsetAttrib6.bin"
;incbin"Parkour_Maps/Parkour Redo ChsetAttrib4d.bin"
incbin"Parkour_Maps/Parkour Redo ChsetAttrib6.bin"

TILE_MEM
;incbin"Turrican Map/Turrican_Tileset1a.bin"
;incbin"Parkour_Maps/Parkour Redo Tileset4d.bin"
incbin"Parkour_Maps/Parkour Redo Tileset6.bin"
