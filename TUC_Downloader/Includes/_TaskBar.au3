#include-once
#include <AutoItObject.au3>
#include <WinAPI.au3>
#include <_Tools.au3>
;~ #include <MsgBoxConstants.au3>

#Region Constantes
Dim Const $TBPF_NOPROGRESS    = 0x0
Dim Const $TBPF_INDETERMINATE = 0x1
Dim Const $TBPF_NORMAL        = 0x2
Dim Const $TBPF_ERROR         = 0x4
Dim Const $TBPF_PAUSED        = 0x8
#EndRegion Constantes

#Region Variables
Global $tbReady=False, $tbGui[10]
Global $pTB3, $oTB3
#EndRegion Variables

;Lancement de l'enregistrement de la fonction "__TaskBarReady"
GUIRegisterMsg(_WinAPI_RegisterWindowMessage("TaskbarButtonCreated"), "__TaskBarReady")

#Region Fonctions _TaskBar*
Func _TaskBarProgressStart($hGui0, $hGui1=0, $hGui2=0, $hGui3=0, $hGui4=0, $hGui5=0, $hGui6=0, $hGui7=0, $hGui8=0, $hGui9=0)
;~ 	_Trace("Initialisation de l'utilisation de la TaskBar Windows.")
	$tbGui[0] = WinGetHandle($hGui0)
	If $hGui1 <> 0 Then $tbGui[1] = WinGetHandle($hGui1)
	If $hGui2 <> 0 Then $tbGui[2] = WinGetHandle($hGui2)
	If $hGui3 <> 0 Then $tbGui[3] = WinGetHandle($hGui3)
	If $hGui4 <> 0 Then $tbGui[4] = WinGetHandle($hGui4)
	If $hGui5 <> 0 Then $tbGui[5] = WinGetHandle($hGui5)
	If $hGui6 <> 0 Then $tbGui[6] = WinGetHandle($hGui6)
	If $hGui7 <> 0 Then $tbGui[7] = WinGetHandle($hGui7)
	If $hGui8 <> 0 Then $tbGui[8] = WinGetHandle($hGui8)
	If $hGui9 <> 0 Then $tbGui[9] = WinGetHandle($hGui9)
	;Register to receive the message that our button is ready
	_AutoItObject_StartUp()
	;Get interfaces
	Local $CLSID_TaskBarlist = _AutoItObject_CLSIDFromString("{56FDF344-FD6D-11D0-958A-006097C9A090}")
	;ITaskbarList3:  http://msdn.microsoft.com/en-us/library/dd391692(VS.85).aspx
	Local $IID_ITaskbarList3 = _AutoItObject_CLSIDFromString("{EA1AFB91-9E28-4B86-90E9-9E9F8A5EEFAF}")
	_AutoItObject_CoCreateInstance(DllStructGetPtr($CLSID_TaskBarlist), 0, 1, DllStructGetPtr($IID_ITaskbarList3), $pTB3)
	If Not $pTB3 Then
		_Trace("Failed to create ITaskbarList3 interface, exiting.")
		_AutoItObject_Shutdown()
		Return False
	EndIf
	; setup AIO wrapper for the interface
	Local $tagInterface = _
						"QueryInterface long(ptr;ptr;ptr);" & _
						"AddRef ulong();" & _
						"Release ulong();" & _
						"HrInit long();" & _
						"AddTab long(hwnd);" & _
						"DeleteTab long(hwnd);" & _
						"ActivateTab long(hwnd);" & _
						"SetActiveAlt long(hwnd);" & _
						"MarkFullscreenWindow long(hwnd;int);" & _
						"SetProgressValue long(hwnd;uint64;uint64);" & _
						"SetProgressState long(hwnd;int);" & _
						"RegisterTab long(hwnd;hwnd);" & _
						"UnregisterTab long(hwnd);" & _
						"SetTabOrder long(hwnd;hwnd);" & _
						"SetTabActive long(hwnd;hwnd;dword);" & _
						"ThumbBarAddButtons long(hwnd;uint;ptr);" & _
						"ThumbBarUpdateButtons long(hwnd;uint;ptr);" & _
						"ThumbBarSetImageList long(hwnd;ptr);" & _
						"SetOverlayIcon long(hwnd;ptr;wstr);" & _
						"SetThumbnailTooltip long(hwnd;wstr);" & _
						"SetThumbnailClip long(hwnd;ptr);"
	;Create the AIO object using the wrapper
	$oTB3 = _AutoItObject_WrapperCreate($pTB3, $tagInterface)
	If Not IsObj($oTB3) Then
		_Trace("Erreur lors de la création de l'objet ""$oTB3"".")
		_AutoItObject_Shutdown()
		Return False
	EndIf
	;Call the HrInit method to initialize the ITaskbarList3 interface
	$oTB3.HrInit()
;~ 	Local $tbCpt = 0
;~ 	_Trace("TaskBar : lancement de l'attente du bouton de la Gui.")
;~ 	While Not $tbReady And $tbCpt<=200
;~ 		$tbCpt+=1
;~         Sleep(10)
;~     WEnd
;~ 	If $tbCpt>200 Then
;~ 		_Trace("L'attente de la barre des tâche est trop longue : abandon.")
;~ 		__TaskBarExit()
;~ 		Return False
;~ 	EndIf
;~ 	_Trace("TaskBar : bouton de la barre des tâches en mode indéterminé.")
	_TaskBarProgressIndeterminate()
	Return True
EndFunc

Func _TaskBarProgressSet($iPercent)
	If Not $tbReady Then
		_Trace("Barre des tâches non prête. Abandon.")
		Return
	EndIf
	For $i = 0 To 9
		If $tbGui[$i] <> 0 Then
			$oTB3.SetProgressValue($tbGui[$i], $iPercent, 100)
			If $iPercent=100 Then $oTB3.SetProgressState($tbGui[$i], $TBPF_NORMAL)
		EndIf
	Next
EndFunc

Func _TaskBarProgressIndeterminate()
	If Not $tbReady Then
		_Trace("Barre des tâches non prête. Abandon.")
		Return
	EndIf
	For $i = 0 To 9
		If $tbGui[$i] <> 0 Then $oTB3.SetProgressState($tbGui[$i], $TBPF_INDETERMINATE)
	Next
EndFunc

Func _TaskBarProgressPause()
	If Not $tbReady Then
		_Trace("Barre des tâches non prête. Abandon.")
		Return
	EndIf
	For $i = 0 To 9
		If $tbGui[$i] <> 0 Then $oTB3.SetProgressState($tbGui[$i], $TBPF_PAUSED)
	Next
EndFunc

Func _TaskBarProgressError()
	If Not $tbReady Then
		_Trace("Barre des tâches non prête. Abandon.")
		Return
	EndIf
	For $i = 0 To 9
		If $tbGui[$i] <> 0 Then $oTB3.SetProgressState($tbGui[$i], $TBPF_ERROR)
	Next
EndFunc

Func _TaskBarProgressStop()
	If $tbReady Then
		For $i = 0 To 9
			If $tbGui[$i] <> 0 Then $oTB3.SetProgressState($tbGui[$i], $TBPF_NOPROGRESS)
		Next
	EndIf
	__TaskBarExit()
EndFunc

#EndRegion Fonctions _TaskBar*

#Region Sous-fonctions __TaskBar*
Func __TaskBarReady($hWnd, $msg, $wParam, $lParam)
;~ 	_Trace("TaskbarButtonCreated : $hWnd="&$hWnd&" / $tbGui="&$tbGui&".")
;~     If $hWnd = $tbGui Then $tbReady = True
    $tbReady = True
EndFunc

Func __TaskBarExit()
	$tbReady = False
	$oTB3 = 0
	_AutoItObject_Shutdown()
EndFunc

#EndRegion Sous-fonctions __TaskBar*
























;~ Global $goflag = False


; register error handler and startup AIO
;~ Global $oError = ObjEvent("AutoIt.Error", "_ErrFunc")
;~ _AutoItObject_StartUp()

; get interfaces
;~ Global $CLSID_TaskBarlist = _AutoItObject_CLSIDFromString("{56FDF344-FD6D-11D0-958A-006097C9A090}")
; ITaskbarList3:  http://msdn.microsoft.com/en-us/library/dd391692(VS.85).aspx
;~ Global $IID_ITaskbarList3 = _AutoItObject_CLSIDFromString("{EA1AFB91-9E28-4B86-90E9-9E9F8A5EEFAF}")

; create the ITaskbarList3 interface instance
;~ Global $pTB3
;~ _AutoItObject_CoCreateInstance(DllStructGetPtr($CLSID_TaskBarlist), 0, 1, DllStructGetPtr($IID_ITaskbarList3), $pTB3)
;~ If Not $pTB3 Then
;~     MsgBox($MB_ICONERROR, "Error", "Failed to create ITaskbarList3 interface, exiting.")
;~     _AutoItObject_Shutdown()
;~     Exit
;~ EndIf

;~ ; setup AIO wrapper for the interface
;~ Global $tagInterface = _
;~         "QueryInterface long(ptr;ptr;ptr);" & _
;~         "AddRef ulong();" & _
;~         "Release ulong();" & _
;~         "HrInit long();" & _
;~         "AddTab long(hwnd);" & _
;~         "DeleteTab long(hwnd);" & _
;~         "ActivateTab long(hwnd);" & _
;~         "SetActiveAlt long(hwnd);" & _
;~         "MarkFullscreenWindow long(hwnd;int);" & _
;~         "SetProgressValue long(hwnd;uint64;uint64);" & _
;~         "SetProgressState long(hwnd;int);" & _
;~         "RegisterTab long(hwnd;hwnd);" & _
;~         "UnregisterTab long(hwnd);" & _
;~         "SetTabOrder long(hwnd;hwnd);" & _
;~         "SetTabActive long(hwnd;hwnd;dword);" & _
;~         "ThumbBarAddButtons long(hwnd;uint;ptr);" & _
;~         "ThumbBarUpdateButtons long(hwnd;uint;ptr);" & _
;~         "ThumbBarSetImageList long(hwnd;ptr);" & _
;~         "SetOverlayIcon long(hwnd;ptr;wstr);" & _
;~         "SetThumbnailTooltip long(hwnd;wstr);" & _
;~         "SetThumbnailClip long(hwnd;ptr);"

;~ ; create the AIO object using the wrapper
;~ Global $oTB3 = _AutoItObject_WrapperCreate($pTB3, $tagInterface)
;~ If Not IsObj($oTB3) Then
;~     MsgBox(16, "Error", "Something has gone horribly awry...")
;~     _AutoItObject_Shutdown()
;~     Exit
;~ EndIf

;~ ; call the HrInit method to initialize the ITaskbarList3 interface
;~ $oTB3.HrInit()

;~ Global $gui = Number(GUICreate("Toolbar Progress", 250, 80))
;~ Global $b1 = GUICtrlCreateButton("Start Progress Bar", 10, 10)
;~ GUISetState()

;~ While 1 <> 2
;~     Switch GUIGetMsg()
;~         Case $b1
;~             _GoProgressTest()
;~         Case -3
;~             ExitLoop
;~     EndSwitch
;~ WEnd

;~ $oTB3 = 0
;~ _AutoItObject_Shutdown()

;~ Func _GoProgressTest()
;~     While Not $goflag
;~         Sleep(10)
;~     WEnd
;~     ConsoleWrite("here we go..." & @CRLF)
;~     ; go through various states and progress
;~     $oTB3.SetProgressState($gui, $TBPF_INDETERMINATE)
;~     Sleep(3000)
;~     For $i = 0 To 33
;~         $oTB3.SetProgressValue($gui, $i, 100)
;~         Sleep(50)
;~     Next
;~     $oTB3.SetProgressState($gui, $TBPF_PAUSED)
;~     For $i = 34 To 66
;~         $oTB3.SetProgressValue($gui, $i, 100)
;~         Sleep(50)
;~     Next
;~     $oTB3.SetProgressState($gui, $TBPF_ERROR)
;~     For $i = 67 To 100
;~         $oTB3.SetProgressValue($gui, $i, 100)
;~         Sleep(50)
;~     Next
;~     $oTB3.SetProgressState($gui, $TBPF_NORMAL)
;~     Sleep(1500)
;~     $oTB3.SetProgressState($gui, $TBPF_NOPROGRESS)
;~ EndFunc



;~ Func _ErrFunc()
;~     ConsoleWrite("! COM Error !  Number: 0x" & Hex($oError.number, 8) & "   ScriptLine: " & $oError.scriptline & " - " & $oError.windescription & @CRLF)
;~     Return
;~ EndFunc   ;==>_ErrFunc