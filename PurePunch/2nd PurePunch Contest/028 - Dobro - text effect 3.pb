;*****************************************************************************
;*
;* Name   : text effect 3
;* Author : Dobro
;* Date   : 20/Juin/2009
;* Notes  : -
;*
;*****************************************************************************
LoadFont(1,"arial",50,512):InitSprite():AM=50:Ts.s="Pure Basic"
WD=OpenWindow(1,50,50,640,200,"",13238272):
OpenWindowedScreen(WD,0,0,640,200,1,0,0):CreateImage(100,640,100):
StartDrawing(ImageOutput(100)):FrontColor($FFFF00):BackColor(0)
DrawingFont(FontID(1)):DrawingMode(1):DrawText(0,0,Ts.s):StopDrawing()
For t=0 To 100:GrabImage(100,t,0,t,640,1):Next:Repeat:
StartDrawing(ScreenOutput()):For Y=0 To 100:a+1:If a=360*10:a=0 :EndIf
 x=1+(1*Cos(a*2*3.1415926/100)*AM)+40:x1=1+(1*Sin(a*2*3.1415926/100)*AM)+40
DrawImage( ImageID(Y),x+40,x1+Y,640,1):dep+1:If dep>640:dep=-100:EndIf:Next
StopDrawing():FlipBuffers():ClearScreen(0):EV=WindowEvent():Until EV=16
; IDE Options = PureBasic 4.31 (Windows - x86)
; DisableDebugger