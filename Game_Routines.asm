;===================================================================================================
;                                                                               CORE ROUTINES
;===================================================================================================

        ; Wait for the raster to reach line $f8 - if it's aleady there, wait for
        ; the next screen blank. This prevents mistimings if the code runs too fast
#region "WaitFrame"
WaitFrame
        lda VIC_RASTER_LINE         ; fetch the current raster line
        cmp #$F8                ; wait here till l        lda VIC_RASTER_LINE         ; fetch the current raster lineine #$f8
        beq WaitFrame           
        
@WaitStep2
        lda VIC_RASTER_LINE
        cmp #$F8
        bne @WaitStep2
        rts
#endregion        
        ;-------------------------------------------------------------------------------------------
        ;                                                                         UPDATE TIMERS
        ;-------------------------------------------------------------------------------------------
        ; 2 basic timers - a fast TIMER that is updated every frame,
        ; and a SLOW_TIMER updated every 16 frames
        ;-----------------------------------------------------------------------
#region "UpdateTimers"
UpdateTimers
        inc TIMER                       ; increment TIMER by 1
        lda TIMER
        and #$0F                        ; check if it's equal to 16
        beq @updateSlowTimer            ; if so we update SLOW_TIMER        
        rts

@updateSlowTimer
        inc SLOW_TIMER                  ; increment slow timer
        rts

#endregion  

        ;-------------------------------------------------------------------------------------------
        ;                                                                       COPY CHARACTER SET
        ;-------------------------------------------------------------------------------------------
        ; Copy the custom character set into the VIC Memory Bank (2048 bytes)
        ; ZEROPAGE_POINTER_1 = Source
        ; ZEROPAGE_POINTER_2 = Dest
        ;
        ; Returns A,X,Y and PARAM2 intact
        ;-------------------------------------------------------------------------------------------

#region "CopyChars"

CopyChars
        
        saveRegs

        ldx #$00                                ; clear X, Y, A and PARAM2
        ldy #$00
        lda #$00
        sta PARAM2
@NextLine

; CHAR_MEM = ZEROPAGE_POINTER_1
; LEVEL_1_CHARS = ZEROPAGE_POINTER_2

        lda (ZEROPAGE_POINTER_1),Y              ; copy from source to target
        sta (ZEROPAGE_POINTER_2),Y

        inx                                     ; increment x / y
        iny                                     
        cpx #$08                                ; test for next character block (8 bytes)
        bne @NextLine                           ; copy next line
        cpy #$00                                ; test for edge of page (256 wraps back to 0)
        bne @PageBoundryNotReached

        inc ZEROPAGE_POINTER_1 + 1              ; if reached 256 bytes, increment high byte
        inc ZEROPAGE_POINTER_2 + 1              ; of source and target

@PageBoundryNotReached
        inc PARAM2                              ; Only copy 254 characters (to keep irq vectors intact)
        lda PARAM2                              ; If copying to F000-FFFF block
        cmp #255
        beq @CopyCharactersDone
        ldx #$00
        jmp @NextLine

@CopyCharactersDone

        restoreRegs

        rts
#endregion