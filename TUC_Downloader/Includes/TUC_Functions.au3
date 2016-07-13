#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <Array.au3>
#include <GuiImageList.au3>
#include <GuiStatusBar.au3>
#include <GuiToolbar.au3>
#include <GuiToolTip.au3>
#include <ImageListConstants.au3>
#include <ListViewConstants.au3>
#include <ProgressConstants.au3>
#include <ToolbarConstants.au3>
#include <ScrollBarsConstants.au3>
#include <WindowsConstants.au3>
#include <WinAPI.au3>
#include <File.au3>
#include <InetConstants.au3>
#include <GuiListView.au3>
#include <GuiImageList.au3>
#include <GDIPlus.au3>
#include <SQLite.au3>
#include <GuiMenu.au3>
#include <EditConstants.au3>
#include <StaticConstants.au3>
#include "..\Includes\JSON.au3"
#include "..\Includes\_Progress.au3"

; #FUNCTION# ;===============================================================================
;
; Name...........: _Base64Encode
; Description ...: Returns the given strinng encoded as a Base64 string.
; Syntax.........: _Base64Encode($sData)
; Parameters ....: $sData
; Return values .: Success - Base64 encoded string.
;                  Failure - Returns 0 and Sets @Error:
;                  |0 - No error.
;                  |1 - Could not create DOMDocument
;                  |2 - Could not create Element
;                  |3 - No string to return
; Author ........: turbov21
; Modified.......:
; Remarks .......:
; Related .......: _Base64Decode
; Link ..........;
; Example .......; Yes
;
; ;==========================================================================================
Func _Base64Encode($sData)
	Local $oXml = ObjCreate("Msxml2.DOMDocument")
	If Not IsObj($oXml) Then
		SetError(1, 1, 0)
	EndIf

	Local $oElement = $oXml.createElement("b64")
	If Not IsObj($oElement) Then
		SetError(2, 2, 0)
	EndIf

	$oElement.dataType = "bin.base64"
	$oElement.nodeTypedValue = Binary($sData)
	Local $sReturn = $oElement.Text

	If StringLen($sReturn) = 0 Then
		SetError(3, 3, 0)
	EndIf

	Return $sReturn
EndFunc   ;==>_Base64Encode

; #FUNCTION# ====================================================================================================================
; Name ..........: GetAppDetail
; Description ...:
; Syntax ........: GetAppDetail($app, $API, $Base64_ID)
; Parameters ....: $app                 - The app to be retrieve.
;                  $API                 - The API ID.
;                  $Base64_ID           - The User:Pwd in Base64.
; Return values .: [$Name, $Date, $Vers, $En32, $En64, $Fr32, $Fr64]
; Author ........: Jean Browaeys
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func GetAppDetail($app, $API, $Base64_ID)
	$FuncName = """GetAppDetail"""
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Ouverture fonction.")
	;Créaction de l'objet HTTP
	Local $oHTTP = ObjCreate("winhttp.winhttprequest.5.1")
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Lancement création objet HTTP.")
	If Not IsObj($oHTTP) Then
		If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncNamea & " - Erreur de création de l'objet HTTP.")
		MsgBox($MB_ICONERROR, "Erreur", "Erreur de création de l'objet ""Requête HTTP"".")
		Return -1
	EndIf
	If Not Ping("updapy.com") Then
		_Trace("Abandon car site Updapy injoignable [1]")
		Return
	EndIf
	;Envoi de le requête HTTP
	$oHTTP.Open("GET", "http://www.updapy.com/api/v1/last-version?application=" & $app & "&key=" & $API)
	If @error Then Return
	If Not Ping("updapy.com") Then
		_Trace("Abandon car site Updapy injoignable [2].")
		Return
	EndIf
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Ouverture HTTP GET request.")
	$oHTTP.SetRequestHeader("Authorization", "Basic " & $Base64_ID)
	If @error Then Return
	If Not Ping("updapy.com") Then
		_Trace("Abandon car site Updapy injoignable [3].")
		Return
	EndIf
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Définition du header HTTP.")
	$oHTTP.Send()
	If @error Then Return
	If Not Ping("updapy.com") Then
		_Trace("Abandon car site Updapy injoignable [4].")
		Return
	EndIf
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Envoi de la requète HTTP.")
	;Récupération de la réponse HTTP
	$HTTPresponse = $oHTTP.Responsetext
	If @error Then Return
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Récupération de la réponse HTTP.")
	;On split le texte suivant les "," pour avoir tous les "items"
	$items = StringSplit($HTTPresponse, ",", $STR_NOCOUNT)
	;Récupération du nom de l'appli
	$Name = StringTrimLeft($items[0], 19)
	If $Name <> "null" Then $Name = StringTrimRight(StringTrimLeft($Name, 1), 1)
	;Récupération de la date d'édition de cette version
	$Date = StringTrimLeft($items[1], 14)
	If $Date <> "null" Then $Date = StringTrimRight(StringTrimLeft($Date, 1), 1)
	;Récupération du numéro de version
	$Vers = StringTrimLeft($items[2], 16)
	If $Vers <> "null" Then $Vers = StringTrimRight(StringTrimLeft($Vers, 1), 1)
	;Récupération du lien vers l'appli x86 en anglais
	$En32 = StringTrimLeft($items[3], 13)
	If $En32 <> "null" Then $En32 = StringTrimRight(StringTrimLeft($En32, 1), 1)
	;Récupération du lien vers l'appli x64 en anglais
	$En64 = StringTrimLeft($items[4], 13)
	If $En64 <> "null" Then $En64 = StringTrimRight(StringTrimLeft($En64, 1), 1)
	;Récupération du lien vers l'appli x86 en français
	$Fr32 = StringTrimLeft($items[5], 13)
	If $Fr32 <> "null" Then $Fr32 = StringTrimRight(StringTrimLeft($Fr32, 1), 1)
	;Récupération du lien vers l'appli x64 en français
	$Fr64 = StringTrimLeft($items[6], 13)
	If $Fr64 <> "null" Then $Fr64 = StringTrimRight(StringTrimLeft($Fr64, 1), 1)
	;Utilisation d'un tableau pour le renvoi des informations
	Local $aRet[7] = [$Name, $Date, $Vers, $En32, $En64, $Fr32, $Fr64]
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Fin fonction, retourne le tableau lu via HTTP.")
	;Affectation du tableau au "Return"
	Return $aRet
EndFunc   ;==>GetAppDetail

Func GetAppsList($API, $Base64_ID)
	$FuncName = """GetAppsList"""
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Ouverture fonction.")
	_ProgressOn(Translate("Progress"), Translate("Getting the softwares list."), "", "", False, $Add, True)
	_ProgressSet(0, Translate("Please be patient."))
	_ProgressWait(True)
;~ 	Sleep(100)
	;Créaction de l'objet HTTP
	Local $oHTTP = ObjCreate("winhttp.winhttprequest.5.1")
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Lancement création objet HTTP.")
	If Not IsObj($oHTTP) Then
		If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncNamea & " - Erreur de création de l'objet HTTP.")
		MsgBox($MB_ICONERROR, "Erreur", "Erreur de création de l'objet ""Requête HTTP"".")
		_ProgressOff()
		Return -1
	EndIf
	If Not Ping("updapy.com") Then
		_Trace("Abandon car site Updapy injoignable [11]")
		_ProgressOff()
		Return
	EndIf
	;Envoi de le requête HTTP
	$oHTTP.Open("GET", "http://www.updapy.com/api/v1/application-names?key=" & $API)
	If @error Then
		_ProgressOff()
		Return
	EndIf
	If Not Ping("updapy.com") Then
		_Trace("Abandon car site Updapy injoignable [12].")
		_ProgressOff()
		Return
	EndIf
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Ouverture HTTP GET request.")
	$oHTTP.SetRequestHeader("Authorization", "Basic " & $Base64_ID)
	If @error Then
		_ProgressOff()
		Return
	EndIf
	If Not Ping("updapy.com") Then
		_Trace("Abandon car site Updapy injoignable [13].")
		_ProgressOff()
		Return
	EndIf
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Définition du header HTTP.")
	$oHTTP.Send()
	If @error Then
		_ProgressOff()
		Return
	EndIf

	If Not Ping("updapy.com") Then
		_Trace("Abandon car site Updapy injoignable [14].")
		_ProgressOff()
		Return
	EndIf
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Envoi de la requète HTTP.")
;~ 	_ProgressSet(10, "Attente de la réponse HTTP.")
	;Récupération de la réponse HTTP
	$HTTPresponse = $oHTTP.Responsetext
	If @error Then
		_ProgressOff()
		Return
	EndIf
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Récupération de la réponse HTTP.")
;~ 	_ProgressSet(20, "Décodage de la réponse HTTP.")
	Local $tab1 = _JSONDecode($HTTPresponse)
	Local $tab2 = $tab1[1][1]
	Local $NbSofts = UBound($tab2)
;~ 	_ProgressSet(30, $NbSofts&" logiciels trouvés.")
;~ 	MsgBox(64, "Nombre de Logiciels détectés", "Un total de "&$NbSofts&" logiciels existent.")
	Local $Tableau[$NbSofts][2]
	Local $tab3
	For $i = 0 To $NbSofts - 1
		$tab3 = $tab2[$i]
		$Tableau[$i][0] = $tab3[1][1]
		$Tableau[$i][1] = $tab3[2][1]
;~ 		_ProgressSet(30+Round($i/$NbSofts*70), $NbSofts&" logiciels trouvés.")
	Next
;~ 	_ProgressSet(100, "Récupération terminée.")
;~ 	Sleep(200)
	_ProgressWait(False)
	_ProgressOff()
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Fin fonction, retourne le tableau lu via HTTP.")
	;Affectation du tableau au "Return"
	Return $Tableau
EndFunc   ;==>GetAppsList

Func Quit()
	_SQLite_Close($hBDD)
	_SQLite_Shutdown()
	If $AVEC_HSCROLL Then
		If $iCallback Then DllCallbackFree($iCallback)
		If $iDLLUser32 Then DllClose($iDLLUser32)
	EndIf
	_Trace("Fermeture de TUC_Downloader.")
	Exit
EndFunc   ;==>Quit

Func Resize()
	Local $aPos[4]
	Local $Width = 0
	$aPos = WinGetPos($Main)
	$Width = $aPos[2]
	_WinAPI_MoveWindow($ToolBar, -1, -1, $Width, 48)
	_GUICtrlStatusBar_Resize($StatusBar)
EndFunc   ;==>Resize

Func OpenWeb($adr)
	ShellExecute($adr)
EndFunc   ;==>OpenWeb

Func _GUIImageList_Convert($gc_Image) ; Created by guinness 2011
	_GDIPlus_Startup()
	Local $gc_Bitmap = _GDIPlus_BitmapCreateFromFile($gc_Image)
	Local $gc_Redim = _GDIPlus_ImageResize($gc_Bitmap, 32, 32)
;~     Local $gc_PNG = _GDIPlus_BitmapCreateHBITMAPFromBitmap($gc_Redim)
	_GDIPlus_ImageSaveToFile($gc_Redim, StringLeft($gc_Image, 25) & "BMP\" & StringTrimRight(StringTrimLeft($gc_Image, 29), 4) & ".bmp")
	_GDIPlus_ImageDispose($gc_Bitmap)
	_GDIPlus_ImageDispose($gc_Redim)
	_GDIPlus_Shutdown()
;~     Return $gc_Redim
EndFunc   ;==>_GUIImageList_Convert

Func _BmpGetHandle($image)
	_GDIPlus_Startup()
	Local $hBitmap = _GDIPlus_BitmapCreateFromFile($image)
	$hBitmap = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hBitmap)
	_GDIPlus_Shutdown()
	Return $hBitmap
EndFunc   ;==>_BmpGetHandle

Func Afficher_ListView()
	_GUICtrlListView_DeleteAllItems($ListView)
	Local $aResult, $iRows, $iColumns, $iRval, $aResult2, $iRows2, $iColumns2, $iRval2, $aResult3, $iRows3, $iColumns3, $iRval3, $aResult4, $iRows4, $iColumns4, $iRval4
	$iRval = _SQLite_GetTable2d($hBDD, "SELECT Titre_Long, Titre_Court FROM Logiciels ORDER BY Titre_Court ASC;", $aResult, $iRows, $iColumns)
	$iRval2 = _SQLite_GetTable2d($hBDD, "SELECT Titre_Court, Selection FROM Logiciels ORDER BY Titre_Court ASC;", $aResult2, $iRows2, $iColumns2)
	$iRval3 = _SQLite_GetTable2d($hBDD, "SELECT Titre_Court, Version_Dispo FROM Logiciels ORDER BY Titre_Court ASC;", $aResult3, $iRows3, $iColumns3)
	$iRval4 = _SQLite_GetTable2d($hBDD, "SELECT Titre_Court, Version_Download FROM Logiciels ORDER BY Titre_Court ASC;", $aResult4, $iRows4, $iColumns4)
	If $iRval = $SQLITE_OK And $iRval2 = $SQLITE_OK And $iRval3 = $SQLITE_OK And $iRval4 = $SQLITE_OK Then
		_GUICtrlListView_BeginUpdate($ListView)
		For $i = 1 To $iRows - 1
			If $aResult2[$i][1] = "OUI" Then
				$item = $aResult[$i][0] & "|" & $aResult3[$i][1] & "|" & $aResult4[$i][1]
;~ 				_ConsoleWrite(">"&$item)
				GUICtrlCreateListViewItem($item, $ListView)
				If $aResult3[$i][1] <> $aResult4[$i][1] Then GUICtrlSetColor(-1, 0xFF0000)
				GUICtrlSetImage(-1, @ScriptDir & "\Resources\Images\Softs\BMP\" & String($aResult[$i][1]) & ".bmp")
			EndIf
		Next
		_GUICtrlListView_EndUpdate($ListView)
	EndIf
	_GUICtrlStatusBar_SetText($StatusBar, @TAB & _GUICtrlListView_GetItemCount($ListView) & " " & Translate("softwares followed."), 1)
EndFunc   ;==>Afficher_ListView

Func Afficher_Add_List()
	_GUICtrlListView_DeleteAllItems($Add_List)
	Local $aResult, $iRows, $iColumns, $iRval, $aResult2, $iRows2, $iColumns2, $iRval2
	$iRval = _SQLite_GetTable2d($hBDD, "SELECT Titre_Long, Titre_Court FROM Logiciels ORDER BY Titre_Court ASC;", $aResult, $iRows, $iColumns)
	$iRval2 = _SQLite_GetTable2d($hBDD, "SELECT Titre_Court, Selection FROM Logiciels ORDER BY Titre_Court ASC;", $aResult2, $iRows2, $iColumns2)
	If $iRval = $SQLITE_OK And $iRval2 = $SQLITE_OK Then
		_GUICtrlListView_BeginUpdate($Add_List)
		For $i = 1 To $iRows
			GUICtrlCreateListViewItem($aResult[$i][0], $Add_List)
			GUICtrlSetImage(-1, ".\Resources\Images\Softs\BMP\" & String($aResult[$i][1]) & ".bmp")
			If $aResult2[$i][1] = "OUI" Then _GUICtrlListView_SetItemChecked($Add_List, $i - 1)
		Next
		_GUICtrlListView_EndUpdate($Add_List)
	EndIf
EndFunc   ;==>Afficher_Add_List

Func Init_Survey_List()
	_Trace("Initialisation de la liste des Softs suivis.")
	Local $aResult, $iRows, $iColumns, $iRval, $aResult2, $iRows2, $iColumns2, $iRval2, $aResult3, $iRows3, $iColumns3, $iRval3, $aResult4, $iRows4, $iColumns4, $iRval4
	$iRval = _SQLite_GetTable2d($hBDD, "SELECT Titre_Long, Titre_Court FROM Logiciels ORDER BY Titre_Court ASC;", $aResult, $iRows, $iColumns)
	$iRval2 = _SQLite_GetTable2d($hBDD, "SELECT Titre_Court, Selection FROM Logiciels ORDER BY Titre_Court ASC;", $aResult2, $iRows2, $iColumns2)
	If $iRval = $SQLITE_OK And $iRval2 = $SQLITE_OK Then
		For $i = 1 To $iRows - 1
			If $aResult2[$i][1] = "OUI" Then
				SQL_Update_If_Different($hBDD, "Logiciels", "Selection", "Titre_Long = '" & SQL_String($aResult[$i][0]) & "'", "NON")
			EndIf
		Next
	EndIf
EndFunc   ;==>Init_Survey_List

Func SQL_String($string)
	$string = StringReplace($string, "'", "''")
	Return $string
EndFunc   ;==>SQL_String

Func SQL_Update_If_Different($bdd, $tab, $col, $where, $data)
	Local $sMsg = SQL_Get_Data($bdd, $tab, $col, $where)
	If $sMsg <> $data Then _SQLite_Exec($bdd, "UPDATE " & $tab & " SET " & $col & " = '" & $data & "' WHERE " & $where & ";")
EndFunc   ;==>SQL_Update_If_Different

Func SQL_Get_Data($bdd, $tab, $col, $where)
	Local $hQuery, $aRow, $sMsg = ""
	_SQLite_Query($bdd, "SELECT " & $col & " FROM " & $tab & " WHERE " & $where & ";", $hQuery)
	While _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK
		$sMsg &= $aRow[0]
	WEnd
	Return $sMsg
EndFunc   ;==>SQL_Get_Data

Func _GetDisplaySize($iSize, $iPlaces = 2)
	Local $aBytes[5] = [' Bytes', ' KB', ' MB', ' GB', ' TB']
	If $iSize < 0 Then $iSize = 0
	For $i = 4 To 1 Step -1
		If $iSize >= 1024 ^ $i Then
			Return Round($iSize / 1024 ^ $i, $iPlaces) & $aBytes[$i]
		EndIf
	Next
	Return $iSize & ' Bytes'
EndFunc   ;==>_GetDisplaySize

Dim $Data_Old = 0, $Vitesse_Time = 0, $vit = 0, $Index = 0, $Vitesse_Hist[10], $max = False
Func Vitesse($data)
	;Initialisation la première fois
	If $Vitesse_Time = 0 Then $Vitesse_Time = TimerInit()
	;Enregistrement du delta
	If $data <> $Data_Old And TimerDiff($Vitesse_Time) >= 250 Then
		$vit = 0
		$Vitesse_Hist[$Index] = $data - $Data_Old
		If $Index < 10 Then $Index += 1
		If $Index = 10 Then
			$Index = 0
			$max = True
		EndIf
;~ 		If ($data - $Vitesse_Old) * 4 > $vit Then $vit += (($data - $Vitesse_Old) * 4 - $vit) / 64
;~ 		If ($data - $Vitesse_Old) * 4 < $vit Then $vit -= ($vit - ($data - $Vitesse_Old) * 4) / 64
		For $i = 0 To 9
			If $Vitesse_Hist[$i] <> 0 Then $vit += $Vitesse_Hist[$i]
			If $Vitesse_Hist[$i] = 0 Or $i = 9 Then
				$vit = ($vit / $i + 1) * 4
				If Not $max Then ExitLoop
			EndIf
		Next
		$Data_Old = $data
		$Vitesse_Time = TimerInit()
;~ 		ConsoleWrite("> Vitesse = "&$vit&" Bytes/s"&@CRLF)
	EndIf
	Return $vit
EndFunc   ;==>Vitesse

Func _InitializeLV($cLV, ByRef $iCallback, ByRef $tInfo)
	;coded by rover 2k12
	;http://www.autoitscript.com/forum/topic/124308-listview-without-scrollbar/page__view__findpost__p__971386
	;create struct for setting mouse scrolling limit
	$tInfo = DllStructCreate($tagSCROLLINFO)
	DllStructSetData($tInfo, "cbSize", DllStructGetSize($tInfo))
	DllStructSetData($tInfo, "fMask", BitOR($SIF_RANGE, $SIF_TRACKPOS))
	Local $hLV = GUICtrlGetHandle($cLV)
	Local $aPos = ControlGetPos($hLV, "", $hLV)
	;adjust listview size for number of items that can be shown
	Local $iY = _GUICtrlListView_ApproximateViewHeight($cLV, _GUICtrlListView_GetCounterPage($cLV) - 1)
	GUICtrlSetPos($cLV, $aPos[0], $aPos[1], $aPos[2], $iY + 3)
	$iCallback = DllCallbackRegister("_LVWndProc", "ptr", "hwnd;uint;wparam;lparam")
	Return _WinAPI_SetWindowLong($hLV, $GWL_WNDPROC, DllCallbackGetPtr($iCallback))
EndFunc   ;==>_InitializeLV

Func _LVWndProc($hWnd, $Msg, $wParam, $lParam)
;~ 	$cpt+=1
;~ 	ConsoleWrite("!!! Debug Jeannot - "&" - !!!"&@CRLF);&$cpt
	;coded by rover 2k11
	;http://www.autoitscript.com/forum/topic/124308-listview-without-scrollbar/page__view__findpost__p__971386
	#forceref $hWnd, $Msg, $wParam, $lParam
	If $Msg = $WM_WINDOWPOSCHANGING Then DllCall($iDLLUser32, "int", "ShowScrollBar", "hwnd", $hWnd, "int", $SB_HORZ, "int", 0) ;Hide horizontal scrollbar
	;pass the unhandled messages to default WindowProc
	Local $aResult = DllCall($iDLLUser32, "lresult", "CallWindowProcW", "ptr", $wProcOldLV, "hwnd", $hWnd, "uint", $Msg, "wparam", $wParam, "lparam", $lParam)
	If @error Then Return -1
	Return $aResult[0]
EndFunc   ;==>_LVWndProc

Func _DownReg()
	tbDown(1)
EndFunc   ;==>_DownReg

Func _TimeReg()
	$min_old = $TimeValue
	$TimeValue = TimerDiff($TimerValue)
	$Ms = _Time_min2ms($TIME_SURVEY) - $TimeValue
	$temp1 = $Ms / 1000
	$temp2 = Mod($temp1, 3600)
	$hours = ($temp1 - $temp2) / 3600
	$temp1 = $temp2
	$temp2 = Mod($temp1, 60)
	$minutes = ($temp1 - $temp2) / 60
	$TimeValue = $minutes
	$temp1 = $temp2
	$seconds = Round($temp1)
	If $hours < 10 Then $hours = "0" & $hours
	If $minutes < 10 Then $minutes = "0" & $minutes
	If $min_old <> $TimeValue Then _Trace("Nouvelle recherche de mises à jour dans : " & $hours & "h" & $minutes & "min59sec.")
	If $seconds < 10 Then $seconds = "0" & $seconds
	GUICtrlSetData($TimeDisplay, $hours & ":" & $minutes & ":" & $seconds)
EndFunc   ;==>_TimeReg

Func _LanguageInitCombo()
	; Assign a Local variable the search handle of all files in the current directory.
	Local $hSearch = FileFindFirstFile(".\Resources\Languages\*.ini")
	; Check if the search was successful, if not display a message and return False.
	If $hSearch = -1 Then
		MsgBox($MB_SYSTEMMODAL, "_LanguageInitCombo()", "Error: No files/directories matched the search pattern.")
		Return False
	EndIf
	; Assign a Local variable the empty string which will contain the files names found.
	Local $sFileName = "", $sResult = ""
	While 1
		$sFileName = FileFindNextFile($hSearch)
		; If there is no more file matching the search.
		If @error Then ExitLoop
		; Create the combo text.
		$sResult &= StringTrimRight($sFileName, 4) & "|"
	WEnd
	; Close the search handle.
	FileClose($hSearch)
	$sResult = StringTrimRight($sResult, 1)
	Return $sResult
EndFunc   ;==>_LanguageInitCombo

Func Translate($txt)
	Local $sRet = IniRead($lang_ini, $lang, $txt, "@error@")
	If $sRet = "@error@" Then ;on en profite pour créer le champ dans le .ini : ça permettra de ne pas en oublier lors de la trad ;)
		IniWrite($lang_ini, $lang, $txt, $txt)
		$sRet = $txt
	EndIf
	Return $sRet
EndFunc   ;==>Translate

Func Param_Load() ;Charge les paramètres courants dans la GUI de paramétrage
	Local $sTemp = ""
	GUICtrlSetData($iParam_UpdapyUser, IniRead($param_ini, "UPDAPY", "User", ""))
	GUICtrlSetData($iParam_UpdapyPwd, _StringCryptDecrypt(False, IniRead($param_ini, "UPDAPY", "Password", "")))
	GUICtrlSetData($iParam_UpdapyApi, IniRead($param_ini, "UPDAPY", "ApiKey", ""))
	GUICtrlSetData($cParam_Language, IniRead($param_ini, "OPTIONS", "Language", "English"))
	GUICtrlSetData($iParam_CheckFreq, IniRead($param_ini, "OPTIONS", "CheckFreq", "60"))
	If IniRead($param_ini, "OPTIONS", "PosMemo", "False") = "True" Then
		GUICtrlSetState($rParam_PosMemo, $GUI_CHECKED)
		GUICtrlSetState($rParam_PosNotMemo, $GUI_UNCHECKED)
	Else
		GUICtrlSetState($rParam_PosMemo, $GUI_UNCHECKED)
		GUICtrlSetState($rParam_PosNotMemo, $GUI_CHECKED)
	EndIf
	GUICtrlSetData($iParam_DownDir, IniRead($param_ini, "OPTIONS", "DownDir", @MyDocumentsDir & "\TUC_Downloads"))
	$sTemp = IniRead($param_ini, "PROXY", "Mode", "System")
	If $sTemp = "None" Then
		GUICtrlSetState($rParam_NoProxy, $GUI_CHECKED)
		GUICtrlSetState($rParam_SysProxy, $GUI_UNCHECKED)
		GUICtrlSetState($rParam_ManProxy, $GUI_UNCHECKED)
		ProxyManuEnable(False)
	ElseIf $sTemp = "System" Then
		GUICtrlSetState($rParam_NoProxy, $GUI_UNCHECKED)
		GUICtrlSetState($rParam_SysProxy, $GUI_CHECKED)
		GUICtrlSetState($rParam_ManProxy, $GUI_UNCHECKED)
		ProxyManuEnable(False)
	Else
		GUICtrlSetState($rParam_NoProxy, $GUI_UNCHECKED)
		GUICtrlSetState($rParam_SysProxy, $GUI_UNCHECKED)
		GUICtrlSetState($rParam_ManProxy, $GUI_CHECKED)
		ProxyManuEnable(True)
	EndIf
	GUICtrlSetData($iParam_ProxyUrl, IniRead($param_ini, "PROXY", "Url", ""))
	GUICtrlSetData($iParam_ProxyPort, IniRead($param_ini, "PROXY", "Port", ""))
	GUICtrlSetData($iParam_ProxyUser, IniRead($param_ini, "PROXY", "User", ""))
	GUICtrlSetData($iParam_ProxyPwd, _StringCryptDecrypt(False, IniRead($param_ini, "PROXY", "Password", "")))
EndFunc   ;==>Param_Load

Func Param_Set() ;Charge les paramètres courants dans les variables du programme
	Local $user = IniRead($param_ini, "UPDAPY", "User", "")
	Local $pwd = _StringCryptDecrypt(False, IniRead($param_ini, "UPDAPY", "Password", ""))
	Global $Base64_ID = _Base64Encode($user & ":" & $pwd)
	Global $API = IniRead($param_ini, "UPDAPY", "ApiKey", "")
	Global $lang = IniRead($param_ini, "OPTIONS", "Language", "English")
	Global $lang_ini = ".\Resources\Languages\" & $lang & ".ini"
	Global $CheminLogiciels = IniRead($param_ini, "OPTIONS", "DownDir", "") & "\"
	Global $TIME_SURVEY = IniRead($param_ini, "OPTIONS", "CheckFreq", 60)
	Local $sTemp = ""
	$sTemp = IniRead($param_ini, "PROXY", "Mode", "System")
	If $sTemp = "None" Then
		SetProxy(1)
	ElseIf $sTemp = "System" Then
		SetProxy(0)
	Else
		SetProxy(2)
	EndIf
	Return True
EndFunc   ;==>Param_Set

Func Param_Save() ;Enregistre les paramètres dans le fichier ini et  lance Param_Set()
	If GUICtrlRead($iParam_UpdapyUser) = "" Or GUICtrlRead($iParam_UpdapyPwd) = "" Or GUICtrlRead($iParam_UpdapyApi) = "" Then
		If MsgBox(BitOR($MB_OKCANCEL, $MB_ICONINFORMATION), Translate("Incorrect settings"), Translate("Please fill up at least the Updapy settings !")) = $IDCANCEL Then Exit
		GUICtrlSetState($TabParam_Updapy, $GUI_SHOW)
		Return False
	EndIf
	Local $sTemp = ""
	IniWrite($param_ini, "UPDAPY", "User", GUICtrlRead($iParam_UpdapyUser))
	IniWrite($param_ini, "UPDAPY", "Password", _StringCryptDecrypt(True, GUICtrlRead($iParam_UpdapyPwd)))
	IniWrite($param_ini, "UPDAPY", "ApiKey", GUICtrlRead($iParam_UpdapyApi))
	IniWrite($param_ini, "OPTIONS", "Language", GUICtrlRead($cParam_Language))
	IniWrite($param_ini, "OPTIONS", "CheckFreq", GUICtrlRead($iParam_CheckFreq))
	If GUICtrlRead($rParam_PosMemo) = $GUI_CHECKED Then
		$sTemp = "True"
	Else
		$sTemp = "False"
	EndIf
	IniWrite($param_ini, "OPTIONS", "PosMemo", $sTemp)
	If Not FileExists(GUICtrlRead($iParam_DownDir)) Then
		If MsgBox(BitOR($MB_ICONQUESTION, $MB_OKCANCEL), Translate("New directory"), Translate("The selected path leads to a non-existing directory.") & @CRLF & Translate("Do you want us to create it ?") & @CRLF & @CRLF & Translate("(Click OK to create the new directory.)")) = $IDCANCEL Then
			GUICtrlSetState($TabParam_Options, $GUI_SHOW)
			Return False
		Else
			DirCreate(GUICtrlRead($iParam_DownDir))
		EndIf
	EndIf
	IniWrite($param_ini, "OPTIONS", "DownDir", GUICtrlRead($iParam_DownDir))
	If GUICtrlRead($rParam_NoProxy) = $GUI_CHECKED Then
		$sTemp = "None"
	ElseIf GUICtrlRead($rParam_SysProxy) = $GUI_CHECKED Then
		$sTemp = "System"
	Else
		$sTemp = "Manual"
	EndIf
	IniWrite($param_ini, "PROXY", "Mode", $sTemp)
	IniWrite($param_ini, "PROXY", "Url", GUICtrlRead($iParam_ProxyUrl))
	IniWrite($param_ini, "PROXY", "Port", GUICtrlRead($iParam_ProxyPort))
	IniWrite($param_ini, "PROXY", "User", GUICtrlRead($iParam_ProxyUser))
	IniWrite($param_ini, "PROXY", "Password", _StringCryptDecrypt(True, GUICtrlRead($iParam_ProxyPwd)))
;~ 	$First = False
	Param_Set()
	Return True
EndFunc   ;==>Param_Save

Func ProxyManuEnable($param)
	If $param Then
		GUICtrlSetState($lParam_ProxyUrl, $GUI_ENABLE)
		GUICtrlSetState($lParam_ProxyPort, $GUI_ENABLE)
		GUICtrlSetState($lParam_ProxyUser, $GUI_ENABLE)
		GUICtrlSetState($lParam_ProxyPwd, $GUI_ENABLE)
		GUICtrlSetState($iParam_ProxyUrl, $GUI_ENABLE)
		GUICtrlSetState($iParam_ProxyPort, $GUI_ENABLE)
		GUICtrlSetState($iParam_ProxyUser, $GUI_ENABLE)
		GUICtrlSetState($iParam_ProxyPwd, $GUI_ENABLE)
	Else
		GUICtrlSetState($lParam_ProxyUrl, $GUI_DISABLE)
		GUICtrlSetState($lParam_ProxyPort, $GUI_DISABLE)
		GUICtrlSetState($lParam_ProxyUser, $GUI_DISABLE)
		GUICtrlSetState($lParam_ProxyPwd, $GUI_DISABLE)
		GUICtrlSetState($iParam_ProxyUrl, $GUI_DISABLE)
		GUICtrlSetState($iParam_ProxyPort, $GUI_DISABLE)
		GUICtrlSetState($iParam_ProxyUser, $GUI_DISABLE)
		GUICtrlSetState($iParam_ProxyPwd, $GUI_DISABLE)
	EndIf
EndFunc   ;==>ProxyManuEnable
