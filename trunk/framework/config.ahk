; This framework includes many of the calculations and logic necessary 
; to allow developers to easily and efficently, develop a marco for
; Toadwater. Many of the difficulties Toadwater can give a developer has
; been compsenated within this framework.
;
; Created by: Oliver Spryn

; -------------------------------
; Pre-gamplay setup
; -------------------------------

; Set the coordinate mode relative to the entire screen
CoordMode, Mouse, Screen

; Parse the config file created by the setup and use its variables, or otherwise create the empty variables here
if (FileExist(configFile)) {
  FileRead, configContents, %configFile%
  
  Loop, parse, configContents, |
  {
    if (A_Index = 1) {
      windowName = %A_LoopField%
    } else {
      value := A_Index - 1 ; The counter will be +1 of all of the inventory items, since the first parsed item was the username
      inv%value% = %A_LoopField%
    }
  }
} else {
  windowName = "" ; The user's Toadwater username, which makes up the title of the Toadwater Window
  
  ; A loop creating the variables inv1 - inv20, each to be used for an inventory item
  loop 20 {
    inv%A_Index% = 
  } 
}

; -------------------------------
; Login
; -------------------------------

; Create a waiting window
Gui, +AlwaysOnTop -SysMenu
Gui, Color, White
Gui, Add, Text, x0 y40 w300 Center cBlack, Logging you in... ; ClassNN = "Static1" according to Window Spy
Gui, Show, w300 h100 Center, Start up

; The actual title of the Toadwater window
parsedName = TWC (%windowName%)

; Close any existing Toadwater windows, then open, focus on, and maximize on a new Toadwater window
if (WinExist(parsedName)) {
  WinClose TWC (%windowName%)
  sleep 1000
  Run %A_ProgramFiles%\Toadwater\TWC.exe
} else if (WinExist("TWC")) {
  WinClose TWC
  sleep 1000
  Run %A_ProgramFiles%\Toadwater\TWC.exe
} else {
  Run %A_ProgramFiles%\Toadwater\TWC.exe
}

; Close any existing Window Spy windows, and reopen it
if (WinExist("Active Window Info (Shift-Alt-Tab to freeze display)")) {
  WinClose Active Window Info (Shift-Alt-Tab to freeze display)
  Run %A_ProgramFiles%\AutoHotkey\AU3_Spy.exe
} else {
  Run %A_ProgramFiles%\AutoHotkey\AU3_Spy.exe
}

sleep 2000
WinActivate, TWC
WinMinimize, Active Window Info (Shift-Alt-Tab to freeze display)
WinActivate, TWC
WinClose, Login
WinMaximize, TWC

; Keep trying to login, as it doesn't always work the first time :(
loop {
  Send ^l
  Send {Enter}
  
  sleep 5000
  
  if (WinExist(parsedName)) {
    break
  }
}

; -------------------------------
; Configuration
; -------------------------------

; ------------------------------- Part 1 | System configuration -------------------------------
SysGet, windowBorder, 31 ; The height, in pixels, of the window border enclosing the Toadwater application
Sysget, menuHeight, 15 ; The height, in pixels, of the Toadwater application menu
SysGet, workableArea, MonitorWorkArea ; The area, in pixels, that a window may consume (screen height - task bar height)
screenWidth := workableAreaRight ; The width of the screen that a window may consume, in pixels
screenHeight := workableAreaBottom ; The height of the screen that a window may consume, in pixels

; ------------------------------- Part 2 | Application specifications -------------------------------
; Modify the waiting window
GuiControl, hide, Static1
Gui, Add, Text, x0 y30 w300 Center cBlack, Please wait while the marco is configured...`nDo not move your mouse during this process  ; ClassNN = "Static1" according to Window Spy

; Scan recursively for the left end (a.k.a the width) of the dock bar
MouseMove, screenWidth, screenHeight - 10
sleep 1000

; Find the width of the dockbar
dockBarWidth = 0

loop {
  global dockBarWidth

; Move the mouse to the appropriate location
  MouseMove, screenWidth - A_Index, screenHeight - 10

; Parse the color from Window Spy
  WinGetText, color, Active Window Info (Shift-Alt-Tab to freeze display)
  colorPos := InStr(color, "0x")
  StringTrimLeft, colorTrim, color, colorPos - 1
  StringSplit, colorParsed, colorTrim, %A_Space%
  
  if (colorParsed1 != 0xF0F0F0) {
    dockBarWidthGuess := A_Index ; A closeish guess of the width, in pixels, of the right-side dock bar
  
  ; Odds are, we went too fast and lost some precision... so do some fine tuning
    loop {
    ; Move the mouse to the appropriate location
      MouseGetPos mouseX, mouseY
      MouseMove, mouseX + 1, screenHeight - 10
      sleep 750
      
    ; Parse the color from Window Spy
      WinGetText, criticalColor, Active Window Info (Shift-Alt-Tab to freeze display)
      criticalColorPos := InStr(criticalColor, "0x")
      StringTrimLeft, criticalColorTrim, criticalColor, criticalColorPos - 1
      StringSplit, criticalColorParsed, criticalColorTrim, %A_Space%
      
      if (criticalColorParsed1 = 0xF0F0F0) {
        dockBarWidth := dockBarWidthGuess - A_Index ; The width, in pixels, of the right-side dock bar
        break
      }
    }
    
    break
  }
}

; Destroy the waiting window
Gui, Destroy

inventorySpacing = 14 ; The amount of space, in pixels, between each of the items in the inventory
inventoryClick := screenWidth - 100 ; The x-position of the inventory list
cellSize = 77 ; The width and height, in pixels, of a cell, when the game is configured as instructed above

cellPaddingX := Round(Mod(((screenWidth - dockBarWidth) / 2) - Round(cellSize / 2), cellSize)) ; Compute the padding added by partially hidden cells in the X direction
cellPaddingY := Round(Mod(((screenHeight - (windowBorder + menuHeight)) / 2) - Round(cellSize / 2), cellSize)) ; Compute the padding added by partially hidden cells in the Y direction 
cellsX := Floor((screenWidth - dockBarWidth - (cellPaddingX * 2)) / cellSize) ; The number of visibile cells to evaluate in the X direction
cellsY := Floor((screenHeight - (windowBorder + menuHeight) - (cellPaddingY * 2)) / cellSize) ; The number of visibile cells to evaluate in the Y direction

healthGood = 0x60CCF0 ; Health meter color indicator, good
healthFair = 0xE0D9CC ; Health meter color indicator, fair
healthPoor = 0x0000C0 ; Health meter color indicator, poor
pooMeter = 0x7C4A1C ; Poo meter color indicator
queueMeter = 0x0000FF ; Queue meter color indicator

; ------------------------------- Part 3 | Variables manipulated by the macro -------------------------------
hoverCellX = 0 ; The x position of the cell number that the mouse currently hovering over
hoverCellY = 0 ; The y position of the cell number that the mouse currently hovering over
locationX = 0 ; The x position of a targeted object
locationY = 0 ; The y position of a targeted object