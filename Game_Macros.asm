;===============================================================================
;                                                       CBM PRG STUDIO MACROS
;===============================================================================
;                                                       - Peter 'Sig' Hewett
;                                                                       2016
;-------------------------------------------------------------------------------
;  Helper macros to shorten repedative tasks and make more readable code
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;                                                                  LOADPOINTER
;-------------------------------------------------------------------------------
; usage :
; loadpointer <zeropage_pointer>, <label>
;
; loads the address of <label> into <zeropage_pointer>
; NOTE : the lable MUST be an absolute address
;-------------------------------------------------------------------------------

defm loadPointer
        lda #</2
        sta /1     ; ZEROPAGE_POINTER_1
        lda #>/2
        sta /1 + 1 ; ZEROPAGE_POINTER_1 + 1

        endm

;--------------------------------------------------------------------------------
;                                                                  COPY POINTER
;--------------------------------------------------------------------------------
; usage :
; copyPointer <source pointer>, <dest pointer>
;
; Copies the contents of one pointer to another
;--------------------------------------------------------------------------------

defm copyPointer
        lda /1     ; ZEROPAGE_POINTER_1
        sta /2     ; ZEROPAGE_POINTER_2
        lda /1 + 1 ; ZEROPAGE_POINTER_1 + 1
        sta /2 + 1 ; ZEROPAGE_POINTER_2 + 1
        
        endm

;--------------------------------------------------------------------------------
;                                                                  ADD POINTER
;--------------------------------------------------------------------------------
; usage :
; addPointer <pointer address>, <amount - 00 - ff>
;
; Adds an immediate 1 byte amount to a pointer
;--------------------------------------------------------------------------------
defm addPointer
        lda /1
        clc
        adc #/2
        sta /1
        lda /1 + 1
        adc #0
        sta /1 + 1

        endm
;--------------------------------------------------------------------------------
;---------------------------------------------------------------------------------
;                                                                  SAVE REGISTERS
;---------------------------------------------------------------------------------
; usage :
; saveRegs
;
; Saves the contents of A X and Y onto the stack
;----------------------------------------------------------------------------------
defm saveRegs
        pha             ; save A
        txa
        pha             ; save X
        tya
        pha             ; save Y
        endm

;----------------------------------------------------------------------------------
;                                                                RESTORE REGISTERS
;----------------------------------------------------------------------------------
; usage:
; restoreRegs
;
; Pulls saved values off the stack and returns them to A X and Y
;----------------------------------------------------------------------------------

defm restoreRegs
        pla
        tay             ; restore Y
        pla
        tax             ; restore X
        pla             ; restore A
        endm

