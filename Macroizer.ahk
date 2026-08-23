/* Script Info
Started: 1/5/2023
Edited: 8/22/2026
RUN WITHOUT OTHER AUTOHOTKEY SCRIPTS THAT USE KeybdHook (see:  https://www.autohotkey.com/docs/v1/lib/Send.htm#SendInputUnavail )
*/

/* Issues
	Recording:
If multiple keys are pressed at the same time, all of them will auto-repeat yet will still be added to KeyPresses
*/


;{ Functions
	ScaleGui(GuiHwnd, UseMoveDraw := "", OriginalFontSize := 7, MinFontSize := 5)  ;Call after Gui, Destroy to remove the static vars for that GuiHwnd
	{
		static ControlHwnds := []
		static GuiFontConstants := []
		
		if (!WinExist("ahk_id " GuiHwnd))
		{
			ControlHwnds[GuiHwnd] := "", GuiFontConstants[GuiHwnd] := ""
			return
		}
		
		if (A_EventInfo = 1) ;if minimized
			return
		
		
		if (!ControlHwnds[GuiHwnd])
		{
			WinGet, ControlHwndList, ControlListHwnd, ahk_id %GuiHwnd%
			ControlHwnds[GuiHwnd] := StrSplit(ControlHwndList, "`n")
			
			Loop, % ControlHwnds[GuiHwnd].MaxIndex()
			{
				GuiControlGet, Control, Pos, % ControlHwnds[GuiHwnd][A_Index]
				ControlHwnds[GuiHwnd][A_Index] := {Hwnd: ControlHwnds[GuiHwnd][A_Index]
				, ControlXToGuiWidthRatio: ControlX / A_GuiWidth
				, ControlYToGuiHeightRatio: ControlY / A_GuiHeight
				, ControlWidthToGuiWidthRatio: ControlW / A_GuiWidth
				, ControlHeightToGuiHeightRatio: ControlH / A_GuiHeight}
			}
			
			GuiFontConstants[GuiHwnd] := {WidthConstant: OriginalFontSize / A_GuiWidth, HeightConstant: OriginalFontSize / A_GuiHeight, OriginalWidth: A_GuiWidth, OriginalHeight: A_GuiHeight}
			
			return
		}
		
		if ((A_GuiWidth * GuiFontConstants[GuiHwnd].WidthConstant + A_GuiHeight * GuiFontConstants[GuiHwnd].HeightConstant) / 2 > MinFontSize)
			Gui, % GuiHwnd ":Font", % "s" (A_GuiWidth * GuiFontConstants[GuiHwnd].WidthConstant + A_GuiHeight * GuiFontConstants[GuiHwnd].HeightConstant) / 2
		else
			Gui, % GuiHwnd ":Font", % "s" MinFontSize
		
		Loop, % ControlHwnds[GuiHwnd].MaxIndex()
		{
			GuiControl, Font, % ControlHwnds[GuiHwnd][A_Index].Hwnd
			GuiControl, % ((UseMoveDraw) ? ("MoveDraw") : ("Move")), % ControlHwnds[GuiHwnd][A_Index].Hwnd, % "x" Round(A_GuiWidth * ControlHwnds[GuiHwnd][A_Index].ControlXToGuiWidthRatio) 
			. " y" Round(A_GuiHeight * ControlHwnds[GuiHwnd][A_Index].ControlYToGuiHeightRatio) 
			. " w" Round(A_GuiWidth * ControlHwnds[GuiHwnd][A_Index].ControlWidthToGuiWidthRatio) 
			. " h" Round(A_GuiHeight * ControlHwnds[GuiHwnd][A_Index].ControlHeightToGuiHeightRatio)
		}
	}
	
	DllCall("QueryPerformanceFrequency", "Int64*", QPCFrequency)
	
	A_SuperTickCount() ;returns the current QPC tickcount in ms ;takes about 0.00068 ms to run
	{
		global QPCFrequency
		DllCall("QueryPerformanceCounter", "Int64*", TickCount)
		return (TickCount / QPCFrequency) * 1000
	}
	
	SuperAccuSleepBreakable(TimeToSleep := 10, ByRef VarThatStopsTheSleepLoopIfItsValueChanges := 0)
	{ ;time to Sleep in ms ;returns time slept in ms ;Accuracy: ~0.001ms (with BatchLines set to -1) ;Uses a lot of CPU power because it's a mixture of AccuWait() and AccuSleepBreakable()
		DllCall("QueryPerformanceCounter", "Int64*", StartTime)
		global QPCFrequency
		OldVarValue := VarThatStopsTheSleepLoopIfItsValueChanges
		TimeToSleep := ((TimeToSleep / 1000) - 0.002) * QPCFrequency ;subtract the amount of time to wait (high cpu usage part) ;(0.002 * QPCFrequency) = 2ms
		
		DllCall("QueryPerformanceCounter", "Int64*", CurrentTime)
		while (CurrentTime - StartTime < TimeToSleep && VarThatStopsTheSleepLoopIfItsValueChanges == OldVarValue)
		{
			DllCall("Winmm\timeBeginPeriod", "UInt", 1)
			DllCall("Sleep", "UInt", 1)
			DllCall("Winmm\timeEndPeriod", "UInt", 1)
			DllCall("QueryPerformanceCounter", "Int64*", CurrentTime)
		}
		
		if (VarThatStopsTheSleepLoopIfItsValueChanges == OldVarValue) ;if true, there is < 2ms left to sleep/wait
		{
			TimeToSleep += (0.002 * QPCFrequency)
			while (CurrentTime - StartTime < TimeToSleep) ; && VarThatStopsTheSleepLoopIfItsValueChanges == OldVarValue) commented out because who can't wait <2 ms?
				DllCall("QueryPerformanceCounter", "Int64*", CurrentTime)
		}
		
		return ((CurrentTime - StartTime) / QPCFrequency) * 1000
	}
;}
	
	
	if (!FileExist(A_MyDocuments "\Macroizer"))
	{
		FileCreateDir, % A_MyDocuments "\Macroizer"
		SetWorkingDir, % A_MyDocuments "\Macroizer"
		FileAppend, 
(
To edit macro files, simply open them with Notepad or anything that supports .txt files.
The format of all macros must be (without the braces {}):
{name of the key} {either "Down" or "Up"}|{milliseconds until next key press}|
Then it just repeats until the final key, which should NOT have the "milliseconds until next key press" part.
If you don't follow this format exactly, you may get some weird results or errors.
So please, be careful editing macros manually.
), % A_WorkingDir "\readme.txt", UTF-8
	}
	
	SetWorkingDir, % "C:\Users\" A_UserName "\Documents\Macroizer"
	
	#NoEnv
	#SingleInstance Off  ;so multiple macro players/recorders can exist
	#MaxMem 4095  ;so recorded macros can be HUGE
	#MaxThreadsPerHotkey, 2
	#UseHook On
	#KeyHistory 0
	Process, Priority,, Realtime
	CoordMode, Mouse, Screen
	SetBatchLines, -1
	SetMouseDelay, -1  ;affects send click speed
	SetKeyDelay, -1, -1
	SetControlDelay, -1
	SetWinDelay, -1
	SendMode, Input
	
	
	;{ Variables
	KeyList := ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "``", "-", "=", "[", "]", "`;", "'", "\", "`,", ".", "/", "CapsLock", "Space", "Tab", "Enter", "Escape", "Backspace", "Up", "Down", "Right", "Left", "ScrollLock", "Delete", "Insert", "Home", "End", "PgUp", "PgDn", "Numpad0", "Numpad1", "Numpad2", "Numpad3", "Numpad4", "Numpad5", "Numpad6", "Numpad7", "Numpad8", "Numpad9", "NumpadDot", "NumLock", "NumpadDiv", "NumpadMult", "NumpadAdd", "NumpadSub", "NumpadEnter", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "F13", "F14", "F15", "F16", "F17", "F18", "F19", "F20", "F21", "F22", "F23", "F24", "LWin", "RWin", "LControl", "RControl", "LShift", "RShift", "LAlt", "RAlt", "Browser_Back", "Browser_Forward", "Browser_Refresh", "Browser_Stop", "Browser_Search", "Browser_Favorites", "Browser_Home", "Volume_Mute", "Volume_Down", "Volume_Up", "Media_Next", "Media_Prev", "Media_Stop", "Media_Play_Pause", "Launch_Mail", "Launch_Media", "Launch_App1", "Launch_App2", "AppsKey", "PrintScreen", "CtrlBreak", "Pause", "Help", "Sleep"]
	
	MouseButtonList := ["LButton", "MButton", "RButton", "WheelDown", "WheelUp", "WheelLeft", "WheelRight"]
	
	PlayingHotkey := "*^q"
	RecordingHotkey := "*^r"
	OfferToSaveMacro := 1
	PlayOnImageSearch := 0
	;KeyPresses
	;TimestampOfLastRecordingEvent
	;}
	
	Gui, +HwndGuiHwnd +Resize +MinSize400x225
	Gui, Font, s10 c00FFFF, MS Shell Dlg
	Gui, Color, 252525, 252525
	
	Gui, Add, Button, x275 y160 w230 h120 +HwndShowChooseHotkeyGuiButton gShow_Choose_Hotkey_Gui, Set Hotkeys`n`n(Play: Ctrl + Q)`n`n(Record: Ctrl + R)
	
	Gui, Add, Button, x275 y10 w110 h60 +HwndRecordButton gRecord, Record
	Gui, Add, Button, x275 y10 w110 h60 Hidden +HwndStopRecordingButton gStop_Recording, Stop Recording  ;seperate buttons so you can stop while the "Recording in x seconds" ToolTip loop is showing
	Gui, Add, Button, x395 y10 w110 h60 +HwndPlayButton gPlay, Play
	Gui, Add, Button, x395 y10 w110 h60 Hidden +HwndStopPlayingButton gStop_Playing, Stop Playing
	Gui, Add, Button, x275 y85 w110 h60 gSave, Save
	Gui, Add, Button, x395 y85 w110 h60 gLoad, Load
	Gui, Add, Button, x10 y330 w120 h50 gShow_Settings_Gui, More Settings
	Gui, Add, Button, x140 y330 w120 h50 gReset_Gui_Size, Reset Gui Size
	Gui, Add, Button, x10 y390 w120 h50 gSave_Settings, Save Settings
	Gui, Add, Button, x140 y390 w120 h50 gLoad_Settings, Load Settings
	
	Gui, Add, Checkbox, x10 y0 w264 r2 Checked vRecordKeyboard gSubmit, Record Keyboard? ;Record Keyboard
	Gui, Add, Checkbox, x10 y30 w264 r2 vRecordMouse gSubmit, Record Mouse? ;Record Mouse
	Gui, Add, Checkbox, x10 y60 w264 r2 Checked vShowRecordingToolTip gSubmit, Show "Recording..." while recording? ;Show "Recording..."
	Gui, Add, Checkbox, x10 y90 w264 r2 Checked vShowPlayingToolTip gSubmit, Show "Playing..." during playback? ;Show "Playing..."
	Gui, Add, Checkbox, x10 y120 w264 r2 vAutoLoadSettings gSubmit, Load saved settings when launched? ;AutoLoad Settings
	
	Gui, Add, Text, x10 y157 w119 r2 BackgroundTrans, Playback speed `%: ;make width of each text control = the distance form x10 to the beginning of the Record button and such
	Gui, Add, Edit, x130 y154 w50 Number vPlaybackSpeed gSubmit, 100
	
	Gui, Add, Text, x10 y188 w45 r2 BackgroundTrans, Play
	Gui, Add, Edit, x45 y185 w100 Number vNumberOfTimesToPlay gSubmit, 1
	Gui, Add, UpDown, Range1-2147483646 Wrap 0x80, 1
	Gui, Add, Text, x150 y188 w124 r2 BackgroundTrans +HwndNumberOfTimesToPlayText, time
	
	Gui, Add, Text, x10 y218 w50 r2 BackgroundTrans, Wait
	Gui, Add, Edit, x45 y215 w40 Number Limit2 vSecondsToWaitBeforeRecording gSubmit, 5
	Gui, Add, UpDown, Range0-99 0x80, 5
	Gui, Add, Text, x90 y218 w184 r2 BackgroundTrans, seconds before recording
	
	Gui, Add, Text, x10 y248 w50 r2 BackgroundTrans, Wait
	Gui, Add, Edit, x45 y245 w40 Number Limit2 vSecondsToWaitBeforePlaying gSubmit, 5
	Gui, Add, UpDown, Range0-99 0x80, 5
	Gui, Add, Text, x90 y248 w184 r2 BackgroundTrans, seconds before playing
	
	Gui, Add, Text, x10 y275 w264 r4 BackgroundTrans, Note: The above two settings only apply to`nthe Gui buttons, not the hotkeys.
	
	Gui, Add, Edit, x520 y10 w270 h430 ReadOnly +HwndKeyPressesDisplay, The macro will be displayed here.
	
	
	IniRead, AutoLoadSettings, % A_WorkingDir "\Macroizer Settings.ini", MainGui, AutoLoadSettings
	if (AutoLoadSettings)
		gosub, Load_Settings
	
	
	Gui, Show, w800 h450, Macroizer
	
	if (PlayingHotkey)  ;we have the if's in case the loaded hotkeys = ""
		Hotkey, % PlayingHotkey, Play, On
	if (RecordingHotkey)
		Hotkey, % RecordingHotkey, Record, On
	
	gosub, Submit
return


;{ Recording

Record: ;{
	Gui, %GuiHwnd%:+OwnDialogs
	
	if (Playing)
		gosub, Stop_Playing
	
	if (OfferToSaveMacro && KeyPresses)
	{
		MsgBox, 262179, Save Macro?, Would you like to save your current macro to file?
		
		
		IfMsgBox, Yes
			goto, Save
		
		IfMsgBox, Cancel
			return
	}
	
	if (!RecordKeyboard && !RecordMouse)
	{
		MsgBox, 16, Record Nothing?, Check "Record Keyboard" or "Record Mouse" to record input.
		return
	}
	
	Recording := 1

	GuiControl, Hide, % RecordButton
	GuiControl, Show, % StopRecordingButton
	
	if (PlayingHotkey)
		Hotkey, %PlayingHotkey%, Play, Off
	if (RecordingHotkey)
		Hotkey, %RecordingHotkey%, Stop_Recording, On
	
	if (StrReplace(A_ThisHotkey, "~") != RecordingHotkey || RecordingHotkey = "")  ;if the Gui button was used, do a countdown before playing
	{
		StartTime := A_SuperTickCount()
		
		While (A_SuperTickCount() - StartTime < SecondsToWaitBeforeRecording * 1000)
		{
			ToolTip, % "Recording in " Round(SecondsToWaitBeforeRecording - (A_SuperTickCount() - StartTime) / 1000, 1) " seconds..."
			Sleep, 50
			if (!Recording)
			{
				if (PlayingHotkey)
					Hotkey, %PlayingHotkey%, Play, Off
				if (RecordingHotkey)
					Hotkey, %RecordingHotkey%, Stop_Recording, On
				ToolTip ;remove the ToolTip
				StartTime := ""
				return
			}
		}
		StartTime := ""
	}
	
	
	if (ShowRecordingToolTip)
		SetTimer, Show_Recording_ToolTip, 50, -1
	
	KeyPresses := "" ;erase the old key press data, if there is any
	
	if (RecordKeyboard)
	{
		Loop, % KeyList.MaxIndex()
		{
			if (KeyList[A_Index] != StrReplace(RecordingHotkey, "*"))  ;don't record key for recording unless the hotkey includes modifiers  ;RegExReplace(RecordingHotkey, "[*!+^]") removes the hotkey symbol attatched to the hotkey
			{
				Hotkey, % "*~" KeyList[A_Index], Key_Down, On
				Hotkey, % "*~" KeyList[A_Index] " Up", Key_Up, On
			}
		}
	}
	
	if (RecordMouse)
	{
		Loop, 3  ;for LButton, MButton, and RButton
		{
			Hotkey, % "*~" MouseButtonList[A_Index], Mouse_Down, On
			Hotkey, % "*~" MouseButtonList[A_Index] " Up", Mouse_Up, On
		}
		
		Loop, 4  ;for WheelDown, WheelUp, WheelLeft, WheelRight
			Hotkey, % "*~" MouseButtonList[A_Index + 3], Mouse_Up, On
	}
return ;}


Stop_Recording: ;{
	Recording := 0
	
	TimestampOfLastRecordingEvent := 0
	
	SetTimer, Show_Recording_ToolTip, Off
	ToolTip ;to remove the remaining tooltip
	
	;disable recording hotkeys
	Loop, % KeyList.MaxIndex()
	{
		if (KeyList[A_Index] != StrReplace(RecordingHotkey, "*"))  ;don't record/change the hotkey for recording  ;RegExReplace(RecordingHotkey, "[*!+^]") remove the modifiers and hotkey symbols attatched to the hotkey
		{
			Hotkey, % "*~" KeyList[A_Index], Key_Down, Off
			Hotkey, % "*~" KeyList[A_Index] " Up", Key_Up, Off
		}
	}
	
	Loop, 3  ;for LButton, MButton, and RButton
	{
		Hotkey, % "*~" MouseButtonList[A_Index], Mouse_Down, Off
		Hotkey, % "*~" MouseButtonList[A_Index] " Up", Mouse_Up, Off
	}
	Loop, 4  ;for WheelDown, WheelUp, WheelLeft, WheelRight
		Hotkey, % "*~" MouseButtonList[A_Index + 3], Mouse_Up, Off  ;Mouse_Up so happens to work for Wheel events, rather have one label than two of the same with diff names
	
	
	GuiControl, Hide, % StopRecordingButton
	GuiControl, Show, % RecordButton
	
	KeyPresses := RegExReplace(KeyPresses, "[*~]")  ;remove hotkey modifiers ;could be done when pressed, but that would less efficient and slower.
	KeyPresses := RegExReplace(KeyPresses, "^[^\|]*\|")  ;remove the blank part made by the first key press
	
	Hotkey, %PlayingHotkey%, Play, On
	Hotkey, %RecordingHotkey%, Record, On
	
	gosub, Update_KeyPressesDisplay
return ;}


Show_Recording_ToolTip: ;{
	ToolTip, Recording...
return ;}


;{ Key and mouse events

Key_Down: ;{
	Thread, NoTimers ;for Show_Recording_ToolTip
	
	if (A_ThisHotkey = A_PriorHotkey) ;if auto-repeated keystroke by windows ;see issue in Issues
		return
	
	KeyPresses .= A_SuperTickCount() - TimestampOfLastRecordingEvent "|" A_ThisHotkey " Down|"
	
	TimestampOfLastRecordingEvent := A_SuperTickCount() 
return ;}

Key_Up: ;{
	Thread, NoTimers
	
	KeyPresses .= A_SuperTickCount() - TimestampOfLastRecordingEvent "|" A_ThisHotkey "|"
	
	TimestampOfLastRecordingEvent := A_SuperTickCount()
return ;}

Mouse_Down: ;{
	Thread, NoTimers ;for Show_Recording_ToolTip
	
	MouseGetPos, MouseX, MouseY
	
	KeyPresses .= A_SuperTickCount() - TimestampOfLastRecordingEvent "|Click " MouseX " " MouseY " " StrReplace(A_ThisHotkey, "Button") " Down|"
	
	TimestampOfLastRecordingEvent := A_SuperTickCount()
return ;}

Mouse_Up: ;{
	Thread, NoTimers ;for Show_Recording_ToolTip
	
	MouseGetPos, MouseX, MouseY
	
	KeyPresses .= A_SuperTickCount() - TimestampOfLastRecordingEvent "|Click " MouseX " " MouseY " " StrReplace(A_ThisHotkey, "Button") "|"
	
	TimestampOfLastRecordingEvent := A_SuperTickCount()
return ;}

;}

;}


;{ Playing

Play: ;{
	Gui, %GuiHwnd%:+OwnDialogs
	
	if (Recording)  ;only necessary if a gui button is added for playing macro
		gosub, Stop_Recording
	
	if (!KeyPresses)
	{
		MsgBox, 262212, No Macro Recorded, There is no macro to play.  Would you like to record one?  You can also load a macro using the "Load Macro" button (if you have one saved).
		
		IfMsgBox, Yes
			goto, Record
		
		return
	}
	
	Playing := 1
	
	Hotkey, %RecordingHotkey%, Record, Off
	Hotkey, %PlayingHotkey%, Stop_Playing, On
	
	GuiControl, Hide, % PlayButton
	GuiControl, Show, % StopPlayingButton
	
	
	if (StrReplace(A_ThisHotkey, "~") != PlayingHotkey || PlayingHotkey = "") ;if the Gui button was used, do a countdown before playing
	{
		StartTime := A_SuperTickCount()
		
		While (A_SuperTickCount() - StartTime < SecondsToWaitBeforePlaying * 1000)
		{
			ToolTip, % "Playing in " Round(SecondsToWaitBeforePlaying - (A_SuperTickCount() - StartTime) / 1000, 1) " seconds..."
			Sleep, 50
			if (!Playing)
			{
				StartTime := ""
				goto, Stop_Playing
			}
		}
		
		StartTime := ""
		ToolTip  ;erase tooltip
	}
	
	KeyPressesArray := StrSplit(KeyPresses, "|")  ;odd numbers = keys, even = time to wait before pressing next key
	
	if (RegExMatch(PlayingHotkey, "[!^+]"))  ;release modifiers that are in PlayingHotkey so they don't interfere with the macro
		Send, % "{Blind}" StrReplace(StrReplace(StrReplace(RegExReplace(PlayingHotkey, "[^^!+]*"), "^", "{LControl Up}{RControl Up}"), "+", "{LShift Up}{RShift Up}"), "!", "{LAlt Up}{RAlt Up}")
	
	if (ShowPlayingToolTip)
		SetTimer, Show_Playing_ToolTip, 50  ;may cause issues like slow/inaccurate playback so may need to remove
	
	
	if (PlayOnImageSearch)  ;if ImagesToSearch has no values, PlayOnImageSearch is set to 0 in Apply_More_Settings, so need need to check for ImagesToSearch having values
	{
		Loop
		{
			Loop, % ImagesToSearch.MaxIndex()  ;for each image, search it
			{
				ImageSearch, FoundImageX, FoundImageY, 0, 0, A_ScreenWidth, A_ScreenHeight, % ImagesToSearch[A_Index]
				if (!ErrorLevel)
					break
			}
			
			if (!ErrorLevel)
				break
			
			SuperAccuSleepBreakable(TimeBetweenImageSearches, Playing)
			
			if (!Playing)
				goto, Stop_Playing
		}
	}
	
	
	while (A_Index <= NumberOfTimesToPlay && Playing)
	{
		Loop, % KeyPressesArray.MaxIndex() // 2 ;the final key will be left out because of the flooring, but all still-held-down keys get released after this loop, so it doesn't matter i think
		{
			if (!Playing)  ;if was stopped by the PlayingHotkey
				break
			
			Send, % "{Blind}{" KeyPressesArray[A_Index * 2 - 1] "}"
			ToolTip, % "{Blind}{" KeyPressesArray[A_Index * 2 - 1] "}"
			SuperAccuSleepBreakable(KeyPressesArray[A_Index * 2], Playing)
		}
	}
	
	Loop, % KeyList.MaxIndex()  ;Release any keys left held down by playing the macro
	{
		if (GetKeyState(KeyList[A_Index]) && !GetKeyState(KeyList[A_Index], "P"))  ;if held down but not physically held down
			Send, % "{Blind}{" KeyList[A_Index] " Up}"
		
		Sleep, 0  ;without the sleep, it doesn't work
	}
	
	KeyPressesArray := ""
	
Stop_Playing:  ;this gets run twice if stopped by hotkey
	Playing := 0
	
	SetTimer, Show_Playing_ToolTip, Off
	ToolTip  ;to remove any tooltip still visible
	
	Hotkey, %PlayingHotkey%, Play, On
	Hotkey, %RecordingHotkey%, Record, On
	
	GuiControl, Hide, % StopPlayingButton
	GuiControl, Show, % PlayButton 
return ;}

Show_Playing_ToolTip: ;{
	ToolTip, Playing...
return ;}
;}


;{ Save and Load

Save: ;{
	Gui, %GuiHwnd%:+OwnDialogs
	
	if (!KeyPresses)
	{
		MsgBox, 64, No Macro to Save, You haven't recorded a macro yet.  Record one by hitting the "Record Macro" button.
		return
	}
	
	if (Playing)
		gosub, Stop_Playing
	
	if (Recording)
		gosub, Stop_Recording
	
	Hotkey, %PlayingHotkey%, Play, Off
	Hotkey, %RecordingHotkey%, Record, Off
	
	FileSelectFile, SavedMacroLocation, S24, % A_WorkingDir "\Untitled Macro.macro", Save As, Macro (*.macro)
	if (SavedMacroLocation)
		FileAppend, % KeyPresses, % ((!RegExMatch(SavedMacroLocation, ".macro$")) ? (SavedMacroLocation ".macro") : (SavedMacroLocation)), UTF-8
	
	SavedMacroLocation := ""
	
	Hotkey, %PlayingHotkey%, Play, On
	Hotkey, %RecordingHotkey%, Record, On
return ;}


Load: ;{
	Gui, %GuiHwnd%:+OwnDialogs
	
	if (Playing)
		gosub, Stop_Playing
	
	if (Recording)
		gosub, Stop_Recording
	
	Hotkey, %PlayingHotkey%, Play, Off
	Hotkey, %RecordingHotkey%, Record, Off
	
	FileSelectFile, SavedMacroLocation, ,  % A_WorkingDir, Load Macro, Macro (*.macro)
	
	if (SavedMacroLocation)
	{
		FileRead, KeyPresses, % SavedMacroLocation
		
		gosub, Update_KeyPressesDisplay
	}
	
	Hotkey, %PlayingHotkey%, Play, On
	Hotkey, %RecordingHotkey%, Record, Off
return ;}


Save_Settings: ;{
	Critical  ;so you can't play/record a macro while saving settings
	Gui, %GuiHwnd%:+OwnDialogs
	
	if (FileExist(A_WorkingDir "\Macroizer Settings.ini"))
		FileDelete, % A_WorkingDir "\Macroizer Settings.ini"
	
	FileAppend, 
(
[Hotkeys]
PlayingHotkey = %PlayingHotkey%
RecordingHotkey = %RecordingHotkey%
[MainGui]
RecordKeyboard = %RecordKeyboard%
RecordMouse = %RecordMouse%
ShowRecordingToolTip = %ShowRecordingToolTip%
ShowPlayingToolTip = %ShowPlayingToolTip%
AutoLoadSettings = %AutoLoadSettings%
PlaybackSpeed = %PlaybackSpeed%
NumberOfTimesToPlay = %NumberOfTimesToPlay%
SecondsToWaitBeforeRecording = %SecondsToWaitBeforeRecording%
SecondsToWaitBeforePlaying = %SecondsToWaitBeforePlaying%
[MoreSettingsGui]
OfferToSaveMacro = %OfferToSaveMacro%
[ChooseHotkeyGui]
PlayingHotkeyIsFromDDL = %PlayingHotkeyIsFromDDL%
RecordingHotkeyIsFromDDL = %RecordingHotkeyIsFromDDL%
), % A_WorkingDir "\Macroizer Settings.ini", UTF-16
return ;}


Load_Settings: ;{
	Critical
	
	if (!FileExist(A_WorkingDir "\Macroizer Settings.ini"))
		return
	
	if (PlayingHotkey)
		Hotkey, % PlayingHotkey, Play, Off  ;so the current hotkeys don't remain hotkeys
	if (RecordingHotkey)
		Hotkey, % RecordingHotkey, Record, Off
	
	IniRead, PlayingHotkey, % A_WorkingDir "\Macroizer Settings.ini", Hotkeys, PlayingHotkey
	IniRead, RecordingHotkey, % A_WorkingDir "\Macroizer Settings.ini", Hotkeys, RecordingHotkey
	
	if (PlayingHotkey)
		Hotkey, % PlayingHotkey, Play, On
	if (RecordingHotkey)
		Hotkey, % RecordingHotkey, Record, On
	GuiControl, , % ShowChooseHotkeyGuiButton, % "Set Hotkeys`n`n(Play: " ((PlayingHotkey) ? (StrReplace(StrReplace(StrReplace(((StrLen(RegExReplace(PlayingHotkey, "[*!^+]")) = 1) ? (Format("{:U}", StrReplace(PlayingHotkey, "*"))) 
	: (StrReplace(PlayingHotkey, "*"))), "+", "Shift + "), "!", "Alt + "), "^", "Ctrl + ")) : ("None")) ")`n`n(Record: " ((RecordingHotkey) ? (StrReplace(StrReplace(StrReplace(((StrLen(RegExReplace(RecordingHotkey, "[*!^+]")) = 1) ? (Format("{:U}", StrReplace(RecordingHotkey, "*"))) : (StrReplace(RecordingHotkey, "*"))), "+", "Shift + "), "!", "Alt + "), "^", "Ctrl + ")) : ("None")) ")"   ;issue: out of order, should be Ctrl + Shift + Alt
	
	IniRead, RecordKeyboard, % A_WorkingDir "\Macroizer Settings.ini", MainGui, RecordKeyboard
	IniRead, RecordMouse, % A_WorkingDir "\Macroizer Settings.ini", MainGui, RecordMouse
	IniRead, ShowRecordingToolTip, % A_WorkingDir "\Macroizer Settings.ini", MainGui, ShowRecordingToolTip
	IniRead, ShowPlayingToolTip, % A_WorkingDir "\Macroizer Settings.ini", MainGui, ShowPlayingToolTip
	IniRead, PlaybackSpeed, % A_WorkingDir "\Macroizer Settings.ini", MainGui, PlaybackSpeed
	IniRead, NumberOfTimesToPlay, % A_WorkingDir "\Macroizer Settings.ini", MainGui, NumberOfTimesToPlay
	IniRead, SecondsToWaitBeforeRecording, % A_WorkingDir "\Macroizer Settings.ini", MainGui, SecondsToWaitBeforeRecording
	IniRead, SecondsToWaitBeforePlaying, % A_WorkingDir "\Macroizer Settings.ini", MainGui, SecondsToWaitBeforePlaying
	GuiControl, % GuiHwnd ":", RecordKeyboard, % RecordKeyboard
	GuiControl, % GuiHwnd ":", RecordMouse, % RecordMouse
	GuiControl, % GuiHwnd ":", ShowRecordingToolTip, % ShowRecordingToolTip
	GuiControl, % GuiHwnd ":", ShowPlayingToolTip, % ShowPlayingToolTip
	GuiControl, % GuiHwnd ":", AutoLoadSettings, % AutoLoadSettings
	GuiControl, % GuiHwnd ":", PlaybackSpeed, % Floor(PlaybackSpeed * 100)
	GuiControl, % GuiHwnd ":", NumberOfTimesToPlay, % NumberOfTimesToPlay
	GuiControl, % GuiHwnd ":", SecondsToWaitBeforeRecording, % SecondsToWaitBeforeRecording
	GuiControl, % GuiHwnd ":", SecondsToWaitBeforePlaying, % SecondsToWaitBeforePlaying
	
	IniRead, OfferToSaveMacro, % A_WorkingDir "\Macroizer Settings.ini", MoreSettingsGui, OfferToSaveMacro
	
	IniRead, PlayingHotkeyIsFromDDL, % A_WorkingDir "\Macroizer Settings.ini", ChooseHotkeyGui, PlayingHotkeyIsFromDDL
	IniRead, RecordingHotkeyIsFromDDL, % A_WorkingDir "\Macroizer Settings.ini", ChooseHotkeyGui, RecordingHotkeyIsFromDDL
return ;}

;}


;{ Choose Hotkey

Show_Choose_Hotkey_Gui: ;{
	if (Recording || Playing) ;so you can't open it while playing/recording
		return
	
	Hotkey, %PlayingHotkey%, Play, Off
	Hotkey, %RecordingHotkey%, Record, Off
	
	Gui, %GuiHwnd%:+Disabled
	Gui, ChooseGui:Default
	
	Gui, +HwndChooseHotkeyGuiHwnd +ToolWindow +Resize +MinSize180x200 +Owner%GuiHwnd%
	Gui, Font, s10 c00FFFF
	Gui, Color, 252525, 252525
	
	
	Gui, Add, Text, x15 y10 r3, Type your desired play/stop playing hotkey below `n                            (can include modifiers):
	Gui, Add, Hotkey, x10 y55 w310 vPlayingHotkey, % ((PlayingHotkeyIsFromDDL) ? ("") : (StrReplace(PlayingHotkey, "*")))
	
	Gui, Add, Checkbox, x45 y95 w280 vPlayingHotkeyIsFromDDL gDisable_Hotkey_Control, Use a key from the list below instead?
	Gui, Add, DropDownList, x175 y125 w150 Disabled vChosenDDLKeyForPlayingHotkey, Space||Tab|Enter|Escape|Backspace|Delete|NumpadEnter|Browser_Back|Browser_Forward|Browser_Refresh|Browser_Stop|Browser_Search|Browser_Favorites|Browser_Home|Volume_Mute|Volume_Down|Volume_Up|Media_Next|Media_Prev|Media_Stop|Media_Play_Pause|Launch_Mail|Launch_Media|Launch_App1|Launch_App2|AppsKey|PrintScreen|CtrlBreak|Pause|Help|Sleep
	Gui, Add, Checkbox, x10 y128 Disabled vAddCtrlToDDLHotkeyPlayingHotkey, Ctrl +
	Gui, Add, Checkbox, x+w Disabled vAddShiftToDDLHotkeyPlayingHotkey, Shift +
	Gui, Add, Checkbox, x+w Disabled vAddAltToDDLHotkeyPlayingHotkey, Alt +
	
	
	Gui, Add, Text, x80 y170 r2, Now for the recording hotkey:
	Gui, Add, Hotkey, x10 y200 w310 vRecordingHotkey, % ((RecordingHotkeyIsFromDDL) ? ("") : (StrReplace(RecordingHotkey, "*")))
	
	Gui, Add, Checkbox, x45 y240 w280 vRecordingHotkeyIsFromDDL gDisable_Hotkey_Control, Use a key from the list below instead?
	Gui, Add, DropDownList, x170 y270 w150 Disabled vChosenDDLKeyForRecordingHotkey, Space||Tab|Enter|Escape|Backspace|Delete|NumpadEnter|Browser_Back|Browser_Forward|Browser_Refresh|Browser_Stop|Browser_Search|Browser_Favorites|Browser_Home|Volume_Mute|Volume_Down|Volume_Up|Media_Next|Media_Prev|Media_Stop|Media_Play_Pause|Launch_Mail|Launch_Media|Launch_App1|Launch_App2|AppsKey|PrintScreen|CtrlBreak|Pause|Help|Sleep
	Gui, Add, Checkbox, x10 y273 Disabled vAddCtrlToDDLHotkeyRecordingHotkey, Ctrl +
	Gui, Add, Checkbox, x+w Disabled vAddShiftToDDLHotkeyRecordingHotkey, Shift +
	Gui, Add, Checkbox, x+w Disabled vAddAltToDDLHotkeyRecordingHotkey, Alt +
	
	
	Gui, Add, Button, x10 y320 w310 h40 gSet_Hotkeys, Done
	
	if (PlayingHotkeyIsFromDDL)
	{
		GuiControl, , PlayingHotkeyIsFromDDL, 1
		GuiControl, Choose, ChosenDDLKeyForPlayingHotkey, % RegExReplace(PlayingHotkey, "[*!+^]")
		GuiControl, , AddCtrlToDDLHotkeyPlayingHotkey, % (InStr(PlayingHotkey, "^") != 0)
		GuiControl, , AddShiftToDDLHotkeyPlayingHotkey, % (InStr(PlayingHotkey, "+") != 0)
		GuiControl, , AddAltToDDLHotkeyPlayingHotkey, % (InStr(PlayingHotkey, "!") != 0)
	}
	if (RecordingHotkeyIsFromDDL)
	{
		GuiControl, , RecordingHotkeyIsFromDDL, 1
		GuiControl, Choose, ChosenDDLKeyForRecordingHotkey, % RegExReplace(RecordingHotkey, "[*!+^]")
		GuiControl, , AddCtrlToDDLHotkeyRecordingHotkey, % (InStr(RecordingHotkey, "^") != 0)
		GuiControl, , AddShiftToDDLHotkeyRecordingHotkey, % (InStr(RecordingHotkey, "+") != 0)
		GuiControl, , AddAltToDDLHotkeyRecordingHotkey, % (InStr(RecordingHotkey, "!") != 0)
	}
	
	gosub, Disable_Hotkey_Control
	
	WinGetPos, MainGuiX, MainGuiY, MainGuiWidth
	Gui, Show, % "x" MainGuiX + MainGuiWidth / 2 - 330 / 2 " y" MainGuiY + 30 " w" 330 " h" 370, Choose Hotkeys
	MainGuiX := MainGuiY := MainGuiWidth := ""
return ;}


Set_Hotkeys: ;{
	Gui, +OwnDialogs
	Gui, Submit, NoHide
	
	if (PlayingHotkeyIsFromDDL)
		PlayingHotkey := ((AddShiftToDDLHotkeyPlayingHotkey) ? ("+") : ("")) . ((AddCtrlToDDLHotkeyPlayingHotkey) ? ("^") : ("")) . ((AddAltToDDLHotkeyPlayingHotkey) ? ("!") : ("")) . ChosenDDLKeyForPlayingHotkey
	
	if (RecordingHotkeyIsFromDDL)
		RecordingHotkey := ((AddShiftToDDLHotkeyRecordingHotkey) ? ("+") : ("")) . ((AddCtrlToDDLHotkeyRecordingHotkey) ? ("^") : ("")) . ((AddAltToDDLHotkeyRecordingHotkey) ? ("!") : ("")) . ChosenDDLKeyForRecordingHotkey
	
	if (PlayingHotkey = RecordingHotkey && PlayingHotkey != "")
	{
		MsgBox, 16, Can't set two of the same hotkey!, Your play/stop playing hotkey can't be the same as your recording hotkey.`nChoose a different hotkey for one of them.
		return
	}
	
	GuiControl, , % ShowChooseHotkeyGuiButton, % "Set Hotkeys`n`n(Play: " ((PlayingHotkey) ? (StrReplace(StrReplace(StrReplace(((StrLen(RegExReplace(PlayingHotkey, "[!^+]")) = 1) ? (Format("{:U}", PlayingHotkey)) : (PlayingHotkey)), "+", "Shift + "), "!", "Alt + "), "^", "Ctrl + ")) : ("None")) ")`n`n(Record: " ((RecordingHotkey) ? (StrReplace(StrReplace(StrReplace(((StrLen(RegExReplace(RecordingHotkey, "[!^+]")) = 1) ? (Format("{:U}", RecordingHotkey)) : (RecordingHotkey)), "+", "Shift + "), "!", "Alt + "), "^", "Ctrl + ")) : ("None")) ")"   ;issue: out of order, should be Ctrl + Shift + Alt
	
	PlayingHotkey := ((PlayingHotkey) ? ("*" PlayingHotkey) : (""))
	RecordingHotkey := ((RecordingHotkey) ? ("*" RecordingHotkey) : (""))
	
	gosub, ChooseGuiGuiClose
return ;}


Disable_Hotkey_Control: ;{
	CurrentPlayingHotkey := PlayingHotkey ;Because we don't want to submit the hotkeys yet
	CurrentRecordingHotkey := RecordingHotkey
	Gui, Submit, NoHide
	PlayingHotkey := CurrentPlayingHotkey 
	RecordingHotkey := CurrentRecordingHotkey
	CurrentPlayingHotkey := "", CurrentRecordingHotkey := ""
	
	if (PlayingHotkeyIsFromDDL)
	{
		GuiControl, Disable, PlayingHotkey
		GuiControl, Enable, ChosenDDLKeyForPlayingHotkey
		GuiControl, Enable, AddCtrlToDDLHotkeyPlayingHotkey
		GuiControl, Enable, AddAltToDDLHotkeyPlayingHotkey
		GuiControl, Enable, AddShiftToDDLHotkeyPlayingHotkey
	}
	else
	{
		GuiControl, Enable, PlayingHotkey
		GuiControl, Disable, ChosenDDLKeyForPlayingHotkey
		GuiControl, Disable, AddCtrlToDDLHotkeyPlayingHotkey
		GuiControl, Disable, AddAltToDDLHotkeyPlayingHotkey
		GuiControl, Disable, AddShiftToDDLHotkeyPlayingHotkey
	}
	
	if (RecordingHotkeyIsFromDDL)
	{
		GuiControl, Disable, RecordingHotkey
		GuiControl, Enable, ChosenDDLKeyForRecordingHotkey
		GuiControl, Enable, AddCtrlToDDLHotkeyRecordingHotkey
		GuiControl, Enable, AddAltToDDLHotkeyRecordingHotkey
		GuiControl, Enable, AddShiftToDDLHotkeyRecordingHotkey
	}
	else
	{
		GuiControl, Enable, RecordingHotkey
		GuiControl, Disable, ChosenDDLKeyForRecordingHotkey
		GuiControl, Disable, AddCtrlToDDLHotkeyRecordingHotkey
		GuiControl, Disable, AddAltToDDLHotkeyRecordingHotkey
		GuiControl, Disable, AddShiftToDDLHotkeyRecordingHotkey
	}
return ;}


ChooseGuiGuiSize: ;{
	ScaleGui(ChooseHotkeyGuiHwnd, 1, 10, 5)
return ;}


ChooseGuiGuiClose: ;{
	Gui, %GuiHwnd%:-Disabled
	Gui, Destroy
	
	if (PlayingHotkey)
		Hotkey, %PlayingHotkey%, Play, On
	if (RecordingHotkey)
		Hotkey, %RecordingHotkey%, Record, On
	
	ScaleGui(ChooseHotkeyGuiHwnd)
	ChooseHotkeyGuiHwnd := ""
return ;}

;}


;{ More Settings Gui
Show_Settings_Gui: ;{
	if (Recording || Playing) ;so you can't open it while playing/recording
		return
	
	Hotkey, %PlayingHotkey%, Play, Off
	Hotkey, %RecordingHotkey%, Record, Off
	
	Gui, %GuiHwnd%:+Disabled
	Gui, MoreSettingsGui:Default
	
	Gui, +HwndMoreSettingsGuiHwnd +ToolWindow +Resize +MinSize500x500 +Owner%GuiHwnd%
	Gui, Font, s10 c00FFFF
	Gui, Color, 252525, 252525
	
	Gui, Add, Checkbox, x10 y0 w264 r2 Checked vOfferToSaveMacro gSubmit, Show recording overwrite warning?  ;Show overwrite warning
	GuiControl, , OfferToSaveMacro, % OfferToSaveMacro
	
	
	Gui, Add, Checkbox, x10 y30 w280 h40 vPlayOnImageSearch, Play macro when image appears on screen?
	GuiControl, , PlayOnImageSearch, % PlayOnImageSearch
	
	Gui, Add, Button, x10 y80 w480 h40 vSelectImagesButton gAdd_Images_For_PlayOnImageSearch, Select Images To Search
	Gui, Add, ListView, x10 y130 w480 h150 AltSubmit vImagesToSearchListView, Images To Search
	if (ImagesToSearch)
	{
		Loop, % ImagesToSearch.MaxIndex()
			LV_Add(, ImagesToSearch[A_Index])
	}
	
	Gui, Add, Edit, x205 y295 w90 Number vTimeBetweenImageSearches, % ((TimeBetweenImageSearches) ? (TimeBetweenImageSearches) : (5000))
	Gui, Add, UpDown, Wrap Range0-9999999 0x80, % ((TimeBetweenImageSearches) ? (TimeBetweenImageSearches) : (5000))
	Gui, Add, Text, x10 y297 w284 r2 BackgroundTrans, Time between image searches:
	Gui, Add, Text, x300 y297 w50 r2 BackgroundTrans, ms
	
	
	Gui, Add, Button, x10 y450 w480 h40 gApply_More_Settings, Done
	
	Gui, Show, w500 h500, Settings
	
	Hotkey, IfWinActive, ahk_id %MoreSettingsGuiHwnd%
	Hotkey, *Delete, Remove_Image_To_Search, On
	Hotkey, *^a, Select_All_Rows_In_ImagesToSearchListView, On
	Hotkey, IfWinActive
return ;}


MoreSettingsGuiGuiSize: ;{
	ScaleGui(MoreSettingsGuiHwnd, 1, 10, 5)
return ;}


MoreSettingsGuiGuiClose: ;{
	Gui, %GuiHwnd%:-Disabled
	Gui, Destroy
	
	Hotkey, IfWinActive, ahk_id %MoreSettingsGuiHwnd%
	Hotkey, *Delete, Remove_Image_To_Search, Off
	Hotkey, *^a, Select_All_Rows_In_ImagesToSearchListView, On
	Hotkey, IfWinActive
	
	ScaleGui(MoreSettingsGuiHwnd)
	MoreSettingsGuiHwnd := ""
	
	if (PlayingHotkey)
		Hotkey, %PlayingHotkey%, Play, On
	if (RecordingHotkey)
		Hotkey, %RecordingHotkey%, Record, On
return ;}


Apply_More_Settings: ;{
	Gui, Submit, NoHide
	
	if (LV_GetCount())  ;if there are images in ImagesToSearchListView.  no if (PlayOnImageSearch) in case someone wants to keep the images in the list, but simply wants to disable image searching for now
	{
		ImagesToSearch := []
		Loop, % LV_GetCount()
		{
			LV_GetText(ImageFile, A_Index)
			ImagesToSearch[A_Index] := ImageFile
		}
	}
	
	gosub, MoreSettingsGuiGuiClose
return ;}


Add_Images_For_PlayOnImageSearch: ;{
	Gui, MoreSettingsGui:Default
	FileSelectFile, ImagesToSearch, M3, % "C:\Users\" A_UserName "\Pictures", Add Images To Search For, Image Files (*.png; *.jpg; *.gif; *.bmp; *.ani; *.ico; *.cur; *.tif; *.wmf; *.emf)
	if (ImagesToSearch)
	{
		ImagesToSearch := StrSplit(ImagesToSearch, "`n")
		Loop, % ImagesToSearch.MaxIndex() - 1
		{
			ImagesToSearch[A_Index + 1] := ImagesToSearch[1] "\" ImagesToSearch[A_Index + 1]
			LV_Add(, ImagesToSearch[A_Index + 1])
		}
		ImagesToSearch := ""
	}
return ;}

Remove_Image_To_Search: ;{
	Gui, MoreSettingsGui:Default
	Loop
		LV_Delete(LV_GetNext())
	until (!LV_GetNext())  ;until all selected images were removed from the list
return ;}

Select_All_Rows_In_ImagesToSearchListView: ;{
	Gui, MoreSettingsGui:Default
	LV_Modify(0, "+Select")
return ;}

;}


;{ Main Gui Labels

Submit: ;{
	Gui, Submit, NoHide
	PlaybackSpeed := ((PlaybackSpeed) ? (PlaybackSpeed) : (1)) / 100  ;if PlaybackSpeed = 0, make it 1% speed
	GuiControl, , % NumberOfTimesToPlayText, % ((NumberOfTimesToPlay > 1 || !NumberOfTimesToPlay) ? ("times") : ("time"))
return ;}

GuiSize: ;{
	ScaleGui(GuiHwnd, 1, 10)
return ;}

Reset_Gui_Size: ;{
	Gui, Show, w800 h450 Center, Macroizer
return ;}

GuiClose: ;{
	Critical
	
	if (Playing)
	{
		gosub, Stop_Playing
		
		Loop, % KeyList.MaxIndex()  ;Release any keys left held down by playing the macro
		{
			if (GetKeyState(KeyList[A_Index]) && !GetKeyState(KeyList[A_Index], "P"))  ;if held down but not physically held down
				Send, % "{Blind}{" KeyList[A_Index] " Up}"
		}
	}
	
	if (OfferToSaveMacro && !Recording && KeyPresses)
	{
		MsgBox, 262179, Save Macro?, Would you like to save your current macro to file?
		
		IfMsgBox, Yes
			gosub, Save
		
		IfMsgBox, Cancel
			return
	}
	
	ExitApp 
return ;}
;}


;{ Miscellaneous

Update_KeyPressesDisplay: ;{
	if (KeyPresses)
	{
		KeyPressesArray := StrSplit(KeyPresses, "|")  ;odd numbers = keys, even = time to wait before pressing next key
		
		Loop, % KeyPressesArray.MaxIndex() // 2
			Test .= KeyPressesArray[A_Index * 2 - 1] "`nWait " KeyPressesArray[A_Index * 2] "ms`n"
		
		Test := StrReplace(Test, "`nWait ms`n")
		
		GuiControl, , % KeyPressesDisplay, % Test
		
		Test := ""
	}
return ;}

;}


*!Escape:: ExitApp ;emergency exit hotkey