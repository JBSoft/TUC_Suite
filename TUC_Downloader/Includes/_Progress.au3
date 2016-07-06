#include-once
#include <GUIConstantsEx.au3>
#include <ProgressConstants.au3>
#include <WindowsConstants.au3>
#include <SendMessage.au3>
#include <_Tools.au3>
#include <_TaskBar.au3>

#Region Constantes
Const $_Progress_Icon = ".\Resources\Images\TUC\TUC.ico"
#EndRegion Constantes

#Region Variables propres à l'include
Dim $_Progress_Pause = 0
Dim $_Progress_Instances = 0
Dim $_Progress_PrevPercent = 0
Dim $_Progress_PrevText = ""
Dim $_Progress_PrevSubT = ""
Dim $_Progress_Array[7]
#EndRegion Variables propres à l'include

#Region Fonctions _Progress*
Func _ProgressOn($title, $mainText, $subText = "", $icon = "", $pause = False, $hGuiMain = 0, $TbProgress = False)
	If $_Progress_Instances = 0 Then
		$_Progress_Instances = 100
	Else
		_Trace("Une autre instance d'un ""_Progress"" existe déja.")
		Return 0
	EndIf
	Local $gui_Largeur = 300
	Local $gui_Hauteur = 0
	Local $tex_Gauche = 0
	Local $posPr_Progress = 0
	Local $posLb_Label = 0
	Local $posBt_Haut = 0
	Local $LarProg = 260
	Local $LarButt = 80
	Local $Interval = ($LarProg - ($LarButt * 2)) ;/2
	Local $PosButt = 16
	If $subText = "" And $icon = "" Then
		$gui_Hauteur = 160 - 17
		$posPr_Progress = 55 - 17
		$posLb_Label = 75 - 17
		$posBt_Haut = 95 - 17
	Else
		$gui_Hauteur = 160
		$posPr_Progress = 55
		$posLb_Label = 75
		$posBt_Haut = 95
	EndIf
	Local $aCenter[2]
	If $hGuiMain <> 0 Then
		$aCenter = _WinGetCenter($hGuiMain)
		$aCenter[0] -= $gui_Largeur / 2
		$aCenter[1] -= $gui_Hauteur / 2
	Else
		$aCenter[0] = -1
		$aCenter[1] = -1
	EndIf
	Local $proGui_Progress = GUICreate($title, $gui_Largeur, $gui_Hauteur, $aCenter[0], $aCenter[1], $DS_MODALFRAME, -1, 0)
	GUISetOnEvent($GUI_EVENT_CLOSE, "__Progress_Close")
	If $_Progress_Icon <> "" Then GUISetIcon($_Progress_Icon)
	If $icon <> "" Then
		Local $proIm_Icon = GUICtrlCreateIcon($icon, -1, 16, 10, 32, 32)
		$tex_Gauche = 65
	Else
		$tex_Gauche = 16
	EndIf
	Local $proLb_Text = GUICtrlCreateLabel($mainText, $tex_Gauche, 10, 300, 20)
	GUICtrlSetFont(-1, 10)
	If $subText <> "" Then Local $proLb_Sub = GUICtrlCreateLabel($subText, $tex_Gauche, 30, 300, 17)
	Local $proPr_Progress = GUICtrlCreateProgress(16, $posPr_Progress, $LarProg, 15, $PBS_SMOOTH)
	Local $proLb_Label = GUICtrlCreateLabel("0 %", 16, $posLb_Label, $LarProg, 17)
	Local $proBt_Pause = 0
	If $pause Then
		$proBt_Pause = GUICtrlCreateButton(" " & Translate("Pause"), $PosButt, $posBt_Haut, $LarButt, 25)
		GUICtrlSetImage(-1, ".\Resources\Images\Progress\Pause.ico")
		GUICtrlSetOnEvent(-1, "__Progress_Pause")
	EndIf
	$PosButt += $LarButt + $Interval
	Local $proBt_Cancel = GUICtrlCreateButton(" " & Translate("Cancel"), $PosButt, $posBt_Haut, $LarButt, 25)
	GUICtrlSetImage(-1, ".\Resources\Images\Progress\Cancel.ico")
	GUICtrlSetOnEvent(-1, "__Progress_Cancel")
	GUISetState(@SW_SHOW, $proGui_Progress)
	$_Progress_Array[0] = $proGui_Progress ;Handle de la GUI
	$_Progress_Array[1] = $proLb_Text ;Handle du texte principal
	$_Progress_Array[2] = $proPr_Progress ;Handle du progress
	$_Progress_Array[3] = $proLb_Label ;Handle du texte du progress
	$_Progress_Array[4] = $proBt_Pause ;Handle du bouton play/pause
	$_Progress_Array[5] = $proBt_Cancel ;Handle du bouton cancel
	If $subText <> "" Then $_Progress_Array[6] = $proLb_Sub
	If $hGuiMain <> 0 And $TbProgress = True Then _TaskBarProgressStart($hGuiMain, $proGui_Progress)
	Return $_Progress_Array
EndFunc   ;==>_ProgressOn

Func _ProgressWait($bSwitch)
	If $bSwitch Then GUICtrlSetStyle($_Progress_Array[2], $PBS_MARQUEE)
	If Not $bSwitch Then GUICtrlSetStyle($_Progress_Array[2], $PBS_SMOOTH)
	_SendMessage(GUICtrlGetHandle($_Progress_Array[2]), $PBM_SETMARQUEE, $bSwitch, 10)
EndFunc   ;==>_ProgressWait

Func _ProgressSet($percent, $text = "", $subText = "")
	If Not __Progress_Check($_Progress_Array) Then Return False
	If Not IsNumber($percent) Or $percent < 0 Then $percent = 0
	If $percent > 100 Then $percent = 100
	If $_Progress_PrevPercent <> $percent Then
		GUICtrlSetData($_Progress_Array[2], $percent)
		_TaskBarProgressSet($percent)
	EndIf
	If $_Progress_PrevPercent <> $percent Or $_Progress_PrevText <> $text Then
		If $text <> "" Then
			GUICtrlSetData($_Progress_Array[3], $percent & " %  |  " & $text)
		Else
			GUICtrlSetData($_Progress_Array[3], $percent & " %")
		EndIf
		$_Progress_PrevPercent = $percent
		$_Progress_PrevText = $text
	EndIf
	If $_Progress_PrevSubT <> $subText Then
		GUICtrlSetData($_Progress_Array[6], $subText)
		$_Progress_PrevSubT = $subText
	EndIf
EndFunc   ;==>_ProgressSet

Func _ProgressGet()
	If Not __Progress_Check($_Progress_Array) Then Return 0 ;Erreur de paramétrage du Progress
	If $_Progress_Instances = 0 Then Return -1 ;Progress inactif
	If $_Progress_Pause = 0 Then
		Return 1 ;Progress actif
	Else
		Return 2 ;Progress en pause
	EndIf
EndFunc   ;==>_ProgressGet

Func _ProgressOff()
	If Not __Progress_Check($_Progress_Array) Then Return False
	_TaskBarProgressStop()
	GUISetState(@SW_HIDE, $_Progress_Array[0])
	GUIDelete($_Progress_Array[0])
	$_Progress_Instances = 0
EndFunc   ;==>_ProgressOff
#EndRegion Fonctions _Progress*

#Region Sous-fonctions __Progress*
Func __Progress_Check($aParam)
	If IsArray($aParam) Then
		If UBound($aParam) = 7 Then
			If $aParam[0] <> 0 And $aParam[0] <> "" _
					And $aParam[2] <> 0 And $aParam[2] <> "" _
					And $aParam[5] <> 0 And $aParam[5] <> "" _
					 Then Return True
		EndIf
	EndIf
	_Trace("_Progress settings incorrects.")
	Return False
EndFunc   ;==>__Progress_Check

Func __Progress_Pause()
	If Not __Progress_Check($_Progress_Array) Or $_Progress_Array[4] = 0 Then Return False
	If $_Progress_Pause = 0 Then
		$_Progress_Pause = 1
		GUICtrlSetData($_Progress_Array[4], " " & Translate("Resume"))
		GUICtrlSetImage($_Progress_Array[4], ".\Resources\Images\Progress\Play.ico")
		_SendMessage(GUICtrlGetHandle($_Progress_Array[2]), $PBM_SETSTATE, 3)
		_TaskBarProgressPause()
		WinSetTitle($_Progress_Array[0], "", WinGetTitle($_Progress_Array[0]) & " - " & Translate("Paused"))
	Else
		$_Progress_Pause = 0
		GUICtrlSetData($_Progress_Array[4], " " & Translate("Pause"))
		GUICtrlSetImage($_Progress_Array[4], ".\Resources\Images\Progress\Pause.ico")
		_SendMessage(GUICtrlGetHandle($_Progress_Array[2]), $PBM_SETSTATE, 1)
		_TaskBarProgressIndeterminate()
		WinSetTitle($_Progress_Array[0], "", StringTrimRight(WinGetTitle($_Progress_Array[0]), StringLen(" - " & Translate("Paused"))))
	EndIf
EndFunc   ;==>__Progress_Pause

Func __Progress_Cancel()
	__Progress_Close()
EndFunc   ;==>__Progress_Cancel

Func __Progress_Close()
	If Not __Progress_Check($_Progress_Array) Then Return False
	_SendMessage(GUICtrlGetHandle($_Progress_Array[2]), $PBM_SETSTATE, 2)
	_TaskBarProgressError()
	GUISetState(@SW_HIDE, $_Progress_Array[0])
	GUIDelete($_Progress_Array[0])
	$_Progress_Instances = 0
EndFunc   ;==>__Progress_Close
#EndRegion Sous-fonctions __Progress*

#Region Fonctions annexes

#EndRegion Fonctions annexes
