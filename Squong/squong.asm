            .MODEL small
            .STACK 256
            videoseg = 0A000h
            .DATA ;Pointer

highscore   DB "toplist.txt", 0
;input_hs    DB "USERNAME - HIGHSCORE",10,13
handle_hs   DW ?
fbuff_hs    DB ? ;file data buffer
oemsg_hs    DB 'Cannot open BUFF.ASM.$'
rfmsg_hs    DB 'Cannot read BUFF.ASM.$'
cfmsg_hs    DB 'Cannot close BUFF.ASM.$'

menu        DB 10,13,"",10,13,09h
            DB "(S)tart Pong",10,13,09h ;10 bzw 0AH (LV) ,13 bzw. 0Dh (CR) Nummern im ASCI CODE Neue Zeile, carriage return (werden immer zusammen geschickt)
            DB "(H)ighscore (read only)", 10, 13, 09h
            DB "(A)bout",10,13,09h
            DB "All other Keys to E(x)it",10,13,09h
            DB "Your choise: "
            DB '$'

gameoverbmp DB 'gameoverbmp',0
handle_go   DW ?
header_go   DB 54 dup (0)
palette_go  DB 256*4 dup (0)
scrline_go  DB 320 dup (0)
errormsg_go DB 'Image Error', 13, 10,'$'

about       DB "This is Pong writen by A.Koernig and J.Kindler!", 10, 13,'$'

playerloc           DW 63501 ;startposi
ballloc             DW 62876 ;startposi ball
balllocold          DW 64000 ;alte ballposi
borderflagright     DB 0 ;rechte grenze gefunden
borderflagleft      DB 0
borderflagtop       DB 0
borderflagbottom    DB 1

            .CODE ;Pointer

            esc_code = 1Bh
            .386 

begin:      MOV AX, 3 ;clear screen
            INT 10h

            MOV AX, @DATA
            MOV DS, AX

showmenu:   MOV AH, 09h
            LEA DX, menu
            INT 21h    

getchoise:  MOV AH, 1
            INT 21h

            CMP AL, 41h ;A
            JE showabout
            CMP AL, 61h ;a
            JE showabout

            CMP AL, 48h ;H
            JE showhighscore
            CMP AL, 68h ;h
            JE showhighscore

            CMP AL, 53h ;S
            JE startgame
            CMP AL, 73h ;s
            JE startgame

            CMP AL, 58h ;X
            JMP quit
            CMP AL, 78h ;x
            JMP quit

startgame:  MOV AH, 0
            MOV AL, 13h ;320x200x8bit
            INT 10h

            MOV AX, videoseg ;offset video memory
            MOV ES, AX

            CALL printfield
            CALL printballstart
            CALL printplayerposi

gameloop:   CALL userinput
            CALL moveball
            CALL sleep
            JMP gameloop

userinput:  MOV AH, 1 ;lesen ohne warten auf Tastatureingabe
            INT 16h ;Tastatureingabe interrupt
            JZ inputend ;falls nichts gedr?ckt wird ZF gesetzt

inputget:   XOR AH, AH ;AH wird genullt
            INT 16h
            CMP AL, esc_code ;ESC Taste
            JE quit ;Sprung zum ende des Programms
            CMP AH, 4Bh 
            ;Left Arrow   4B00
            JE moveleft
            CMP AH, 4Dh
            ;Right Arrow  4D00
            JE moveright

inputend:   RET

printfield: XOR BX, BX

printtop:   MOV DI, BX
            MOV DL, 2 ;green
            MOV ES:[DI], DL  ;Block
            INC BX
            CMP BX, 320 ; Obere Kante
            JNE printtop
            DEC BX

printfieldleftright:
            INC BX ;linke Kante
            MOV DI, BX
            MOV DL, 2 ;green
            MOV ES:[DI], DL ;Block
            ADD BX, 319 ;Sprung an rechte Kante
            MOV DI, BX
            MOV DL, 2 ;green
            MOV ES:[DI], DL ;Block
            CMP BX, 63999
            JNE printfieldleftright
            RET

;ball 2x2 +15 f?r mitte
printballstart:
            MOV BX, [ballloc]
            MOV DI, BX
            MOV DL, 4 ;red
            MOV ES:[DI], DL ;Block
            INC BX
            MOV DI, BX
            MOV DL, 4 ;red
            MOV ES:[DI], DL ;Block
            ADD BX, 319
            MOV DI, BX
            MOV DL, 4 ;red
            MOV ES:[DI], DL ;Block
            INC BX
            MOV DI, BX
            MOV DL, 4 ;red
            MOV ES:[DI], DL ;Block
            RET

clearball:  MOV BX, [ballloc]
            MOV DI, BX
            MOV DL, 0 ;black
            MOV ES:[DI], DL ;Block
            INC BX
            MOV DI, BX
            MOV DL, 0 
            MOV ES:[DI], DL ;Block
            ADD BX, 319
            MOV DI, BX
            MOV DL, 0 
            MOV ES:[DI], DL ;Block
            INC BX
            MOV DI, BX
            MOV DL, 0 
            MOV ES:[DI], DL ;Block
            RET

moveball:   MOV BX, [ballloc] 
            MOV CX, [balllocold]
            CMP CX, BX ;alte und neue loc vergleichen
            jb direktiondown
            JMP direktionup

direktiondown:
            MOV borderflagtop, 0
            CMP borderflagleft, 1
            JE moveballdirektiondownright
            CMP borderflagright, 1
            JE moveballdirektiondownleft

direktionup:MOV borderflagbottom, 0
            CMP borderflagleft, 1
            JE moveballdirektionupright
            CMP borderflagright, 1
            JE moveballdirektionupleft

moveballdirektionupright:
            MOV borderflagright, 0
            CALL checkrightborder
            CMP borderflagright, 1
            JE moveend
            CALL checktop
            CMP borderflagtop, 1
            JE moveend
            CALL moveballupright
            JMP moveend

moveballdirektionupleft:
            MOV borderflagleft, 0
            CALL checkleftborder
            CMP borderflagleft, 1
            JE moveend
            CALL checktop
            CMP borderflagtop, 1
            JE moveend
            CALL moveballupleft
            JMP moveend

moveballdirektiondownright:
            MOV borderflagright, 0
            CALL checkrightborder
            CMP borderflagright, 1
            JE moveend
            CALL checkbottom
            CMP borderflagbottom, 1
            JE moveend
            CALL moveballdownright
            JMP moveend

moveballdirektiondownleft:
            MOV borderflagleft, 0
            CALL checkleftborder
            CMP borderflagleft, 1
            JE moveend
            CALL checkbottom
            CMP borderflagbottom, 1
            JE moveend
            CALL moveballdownleft

moveend:    RET

moveballupleft:
            CALL clearball
            MOV BX, [ballloc]
            MOV [balllocold], BX ;alte posi sichern
            SUB BX, 642 ;w?re diagonal aber Bildschirm ist ja nicht quadratisch
            CMP BX, 642 ;bleibt vor oberer Kante stehen
            JBE moveballupleftend
            MOV [ballloc], BX

moveballupleftend:
            CALL printballstart
            MOV CX, [balllocold] ;ist n?tig um das Umlenken des Balles zu erm?glichen
            SUB CX, 640 ;hier wird garantiert, dass alte loc an oberer Kante kleiner wird
            MOV [balllocold], CX
            RET

moveballupright:
            CALL clearball
            MOV BX, [ballloc]
            MOV [balllocold], BX ;alte posi sichern
            SUB BX, 638 ;w?re diagonal aber Bildschirm ist ja nicht quadratisch (2hoch 2rechts)
            CMP BX, 638 ;bleibt vor oberer Kante stehen
            JBE moveballuprightend
            MOV [ballloc], BX

moveballuprightend:
            CALL printballstart
            MOV CX, [balllocold] ;ist n?tig um das Umlenken des Balles zu erm?glichen
            SUB CX, 637 ;hier wird garantiert, dass alte loc an oberer Kante kleiner wird, muss kleiner sein als erste SUB
            MOV [balllocold], CX
            RET

moveballdownleft:
            CALL clearball
            MOV BX, [ballloc]
            MOV [balllocold], BX
            ADD BX, 638 ;diagnonal
            MOV [ballloc], BX

moveballdownleftend:
            CALL printballstart
            RET

moveballdownright:
            CALL clearball
            MOV BX, [ballloc]
            MOV [balllocold], BX
            ADD BX, 642 ;diagnonal
            MOV [ballloc], BX

moveballdownrightend:
            CALL printballstart
            RET

checktop:   MOV BX, [ballloc]
            CMP BX, 642 ;eventuell wird hier von unten gesehen und bleibt am schl?ger h?ngen
            JBE checktopend
            RET

checktopend:MOV borderflagtop, 1
            RET

checkbottom:MOV BX, [ballloc]
            CMP BX, 62720 ;eventuell genau Zeile treffen um richtig zu pr?fen 4te Zeile von unten
            JAE checkbottomplayer ;nur pr?fen wenn kurz ?ber Schl?ger
            RET

checkbottomplayer:
            MOV BX, [ballloc]
            MOV DX, [playerloc] ;;hier CX, da BX in anderem Unterprogramm ben?tigt und noch nicht zur?ckgeschrieben ist
            XOR AX, AX

checkplayerloop:
            SUB DX, 320 ;jeweils 1te Zeile ?ber Schl?ger pr?fen
            CMP BX, DX
            JE checkplayerfound
            SUB DX, 320 ;jeweils 2te Zeile ?ber Schl?ger pr?fen
            CMP BX, DX
            JE checkplayerfound
            ADD DX, 641 ;zur?ck zu schl?ger und ein Pixel nach rechts
            INC AX
            CMP AX, 30
            JNE checkplayerloop
            CMP BX, 63040 ;?ber dem Cursor stehenbleiben, 3Zeilen ?ber grenze
            JAE gameOver ;funktioniert td:01E5
            RET

checkplayerfound:
            MOV BX, [ballloc] ;notwendig um den Ball wieder nach oben zu schicken
            MOV [balllocold], BX ;f?r den vergleich ob hoch oder runter
            MOV borderflagbottom, 1
            RET

checkrightborder:
            MOV BX, [ballloc]
            XOR AL, AL
            MOV DX, 317 ;317 genau an Grenze

checkrightborderloop:     
            CMP BX, DX
            JE foundright
            DEC DX ; 316 1 vor Grenze um diese nicht Schwarz zu schreiben
            CMP BX, DX
            JE foundright
            ADD DX, 321
            ADD AL, 1
            CMP AL, 200
            JNE checkrightborderloop

checkrightborderend:
            RET

foundright: MOV borderflagright, 1
            MOV borderflagleft, 0
            RET

checkleftborder:
            MOV BX, [ballloc]
            XOR AL, AL
            MOV DX, 322 ;genau an der Grenze

checkleftborderloop:     
            CMP BX, DX
            JE foundleft
            INC DX ;323 1 vor Grenze, schutz vor ?berschreiben
            CMP BX, DX
            JE foundleft
            ADD DX, 319
            ADD AL, 1
            CMP AL, 200
            JNE checkleftborderloop

checkleftborderend:
            RET

foundleft:  MOV borderflagleft, 1
            MOV borderflagright, 0
            RET

printplayerposi:
            MOV BX, [playerloc] ;startposi laden
            MOV DI, BX
            MOV DL, 7       ;grey
            MOV ES:[DI], DL  ;Block
            MOV AX, 30

addline:    INC BX
            MOV DI, BX
            MOV DL, 7       ;grey
            MOV ES:[DI], DL  ;Block
            DEC AX
            JNZ addline
            RET

clearplayerposi:
            MOV BX, [playerloc] ;startposi laden
            MOV DI, BX
            MOV DL, 0 ;black
            MOV ES:[DI], DL  ;Block
            MOV AX, 30

removeline: INC BX
            MOV DI, BX
            MOV DL, 0
            MOV ES:[DI], DL  ;Block
            DEC AX
            JNZ removeline
            RET

moveright:  CALL clearplayerposi ;aktuelle posi l?schen
            MOV BX, [playerloc] 
            ADD BX, 7 ;schritte zu aktuelle posi addieren
            CMP BX, 63649 ;pr?fen auf rechte Grenze
            JAE moverightend ;falls rechte Grenze dann kein ?berschreiben der playerloc
            MOV [playerloc], BX

moverightend:
            CALL printplayerposi
            RET

moveleft:
            CALL clearplayerposi
            MOV BX, [playerloc]
            SUB BX, 7
            CMP BX, 63360
            JBE moveleftend
            MOV [playerloc], BX

moveleftend:CALL printplayerposi
            RET

sleep:      MOV AH, 0 ;System Clock Counter, 18mal pro sekunde erh?ht
            INT 1ah ;INT 1ah wichtig, 
            ADD DX, 1 ;variable f?r sleepl?nge, 18=1sek
            MOV BX, DX ;Sekunden + Variable gespeichert

sleeploop:  INT 1ah ;erneutes lesen von System Clock Counter
            CMP DX, BX ;pr?fen ob Zeitvergangen
            JNE sleeploop
            RET

gameOver:   ; Graphic mode
            MOV AX, 13h
            INT 10h

            ; Process BMP file
            CALL OpenFile
            CALL ReadHeader
            CALL ReadPalette
            CALL CopyPal
            CALL CopyBitmap

            ; Wait for key press
            MOV AH, 1

            INT 21h
            ; Back to text mode
            MOV AH, 0
            MOV AL, 2
            INT 10h

            MOV AX, 3
            INT 10h

            ;file handler ?ffnen
;            MOV DX, offset highscore
;            MOV AL, 1
;            MOV AH, 3Dh
;            INT 21h

            ;in file schreiben
;            MOV BX, AX
;            MOV CX, 0
;            MOV AH, 42h
;            MOV AL, 02h
;            INT 21h

            ;file schreiben
;            MOV CX, 22 ;22 weil l?nge von input_hs
;            MOV DX, offset input_hs
;            MOV AH, 40h
;            INT 21h

            ;file handler schlie?en sonst kein schreiben m?glich
;            MOV AH, 3Eh
;            INT 21h

            ; datensegment quasi wieder zur?cksetzen
            MOV bx, 62876
            MOV [ballloc], bx ;zur?ck zur startposi
            MOV bx, 63501
            MOV [playerloc], bx ;startposi
            MOV bx, 64000
            MOV [balllocold], bx
            MOV borderflagright, 0
            MOV borderflagleft, 0
            MOV borderflagtop, 0
            MOV borderflagbottom, 1
            JMP showmenu

OpenFile:   ;Open file
            MOV AH, 3Dh
            XOR AL, AL
            MOV DX, offset gameoverbmp
            INT 21h

            JC openerror
            MOV [handle_go], AX
            RET

openerror:  MOV DX, offset errormsg_go
            MOV AH, 9h
            INT 21h
            RET

ReadHeader: ;Read BMP file header, 54 bytes
            MOV AH, 3fh
            MOV bx, [handle_go]
            MOV CX, 54
            MOV DX, offset header_go
            INT 21h
            RET

ReadPalette:;Read BMP file color palette, 256 colors * 4 bytes (400h)
            MOV AH, 3fh
            MOV CX, 400h
            MOV DX, offset palette_go
            INT 21h
            RET

CopyPal:    ;Copy the colors palette to the video memory
            ;The number of the first color should be sent to port 3C8h
            ;The palette is sent to port 3C9h
            MOV SI, offset palette_go
            MOV CX, 256
            MOV DX, 3C8h
            MOV AL, 0

            ;Copy starting color to port 3C8h
            OUT DX, AL

            ;Copy palette itself to port 3C9h
            INC DX

PalLoop:    ;Note: Colors in a BMP file are saved as BGR values rather than RGB.
            MOV AL, [SI+2] ;Get red value.
            SHR AL, 2 ;Max. is 255, but video palette maximal

            ;value is 63. Therefore dividing by 4.
            OUT DX, AL ;Send it.
            MOV AL, [SI+1] ;Get green value.
            SHR AL, 2
            OUT DX, AL ;Send it.
            MOV AL, [SI] ;Get blue value.
            SHR AL, 2
            OUT DX, AL ;Send it.
            ADD SI, 4 ;Point to next color.

            ; (There is a null chr. after every color.)
            LOOP PalLoop
            RET

CopyBitmap: ;BMP graphics are saved upside-down.
            ;Read the graphic line by line (200 lines in VGA format),
            ;displaying the lines from bottom to top.
            MOV AX, 0A000h
            MOV ES, AX
            MOV CX, 200

PrintBMPLoop:
            PUSH CX

            ;DI = CX*320, point to the correct screen line
            MOV DI, CX
            SHL CX, 6
            SHL DI, 8
            ADD DI, CX

            ;Read one line
            MOV AH, 3fh
            MOV CX, 320
            MOV DX, offset scrline_go
            INT 21h

            ;Copy one line into video memory
            CLD 

            ;Clear direction flag, for movsb
            MOV CX, 320
            MOV SI, offset scrline_go
            REP movsb 

            ;Copy line to the screen
            ;REP movsb is same as the following code:
            ;MOV ES:DI, ds:SI
            ;INC SI
            ;INC DI
            ;dec CX
            ;LOOP until CX=0

            POP CX
            LOOP PrintBMPLoop
            RET

showabout:  MOV AX, 3 ;clear screen
            INT 10h

            LEA DX, about
            MOV AH, 09h
            INT 21h    
            JMP showmenu

showhighscore:
            MOV AX, 3 ;clear screen
            INT 10h

            CALL openfile_hs   ;open BUFF.ASM
            JC quit            ;jump if error
            CALL readfile_hs   ;read BUFF.ASM
            CALL closefile_hs  ;close BUFF.ASM
            JMP showmenu

openfile_hs:
            MOV AH, 3DH        ;open file with handle function
            LEA DX, highscore  ;set up pointer to ASCIIZ string
            MOV AL, 0          ;read access
            INT 21H            ;DOS call
            JC openerr_hs      ;jump if error
            MOV handle_hs, AX  ;save file handle
            RET

openerr_hs: LEA DX, oemsg_hs   ;set up pointer to error message
            MOV AH, 9          ;display string function
            INT 21H            ;DOS call
            STC                ;set error flag
            RET

readfile_hs:MOV AH, 3FH        ;read from file function
            MOV BX, handle_hs  ;load file handle
            LEA DX, fbuff_hs   ;set up pointer to data buffer
            MOV CX, 1          ;read one byte
            INT 21H            ;DOS call
            JC readerr_hs      ;jump if error
            CMP AX, 0          ;were 0 bytes read?
            JZ eoff            ;yes, end of file found
            MOV DL, fbuff_hs   ;no, load file character
            CMP DL, 1AH        ;is it Control-Z <EOF>?
            JZ eoff            ;jump if yes
            MOV AH, 2          ;display character function
            INT 21H            ;DOS call
            JMP readfile_hs    ;and repeat

readerr_hs: LEA DX, rfmsg_hs   ;set up pointer to error message
            MOV AH, 9          ;display string function
            INT 21H            ;DOS call
            STC                ;set error flag

eoff:       RET

closefile_hs:
            MOV AH, 3EH        ;close file with handle function
            MOV BX, handle_hs  ;load file handle
            INT 21H            ;DOS call
            JC closeerr_hs     ;jump if error
            RET

closeerr_hs:LEA DX, cfmsg_hs   ;set up pointer to error message
            MOV AH, 9          ;display string function
            INT 21H            ;DOS call
            STC                ;set error flag
            RET

quit:       MOV AX, 3 ;bildschirm loeschen
            INT 10h    
            MOV AH, 04Ch ;ben?tigt sonst freeze
;            MOV AL,00 ;Exit Code n?tig/ m?glich f?r DEBUG hier 00
            INT 21h

END begin