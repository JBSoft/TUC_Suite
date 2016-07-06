#include-once
#include <AutoItObject.au3>
#include <Crypt.au3>

#Region Fonctions liées à la gestion des GUI
; #FUNCTION# ====================================================================================================================
; Name ..........: _WinGetCenter
; Description ...: Permet de renvoyer la position X/Y du centre d'une fenêtre
; Syntax ........: GuiCenter($hGuiMain)
; Parameters ....: $hGuiMain            - a handle value or a string value (Win title).
; Return values .: Array[0] = Position X
; 				   Array[1] = Position Y
; Author ........: jbs
; ===============================================================================================================================
Func _WinGetCenter($hGuiMain)
	Local $aGet[4], $aRet[2]
	$aGet = WinGetPos($hGuiMain)
;~ 	_Trace("Position de la fenêtre : X("&$aGet[0]&")/Y("&$aGet[1]&")/W("&$aGet[2]&")/H("&$aGet[3]&").")
	$aRet[0] = $aGet[0] + $aGet[2] / 2
	$aRet[1] = $aGet[1] + $aGet[3] / 2
;~ 	_Trace("Centre de la fenêtre : X("&$aRet[0]&")/Y("&$aRet[1]&").")
	Return $aRet
EndFunc   ;==>_WinGetCenter

; #FUNCTION# ====================================================================================================================
; Name ..........: _WinSetSize
; Description ...: Change la taille d'une fenêtre en conservant sa position
; Syntax ........: _WinSetSize($hGui, $iWidth, $iHeight)
; Parameters ....: $hGui                - a handle value.
;                  $iWidth              - an integer value.
;                  $iHeight             - an integer value.
; Return values .: None
; Author ........: jbs
; ===============================================================================================================================
Func _WinSetSize($hGui, $iWidth, $iHeight)
	Local $sTitle, $aSize[4]
	$sTitle = WinGetTitle($hGui)
	$aSize = WinGetPos($sTitle)
	If $aSize[2] < $iWidth Then WinMove($sTitle, "", $aSize[0], $aSize[1], $iWidth, $aSize[3])
	If $aSize[3] < $iHeight Then WinMove($sTitle, "", $aSize[0], $aSize[1], $aSize[2], $iHeight)
EndFunc   ;==>_WinSetSize

; #FUNCTION# ====================================================================================================================
; Name ..........: _WinSetMinMax
; Description ...:
; Syntax ........: InitMinMax($x0, $y0[, $x1 = -1[, $y1 = -1]])
; Parameters ....: $x0                  - an unknown value.
;                  $y0                  - an unknown value.
;                  $x1                  - [optional] an unknown value. Default is -1.
;                  $y1                  - [optional] an unknown value. Default is -1.
; Return values .: None
; Author ........: jbs
; ===============================================================================================================================
Func _WinSetMinMax($hWnd, $x0, $y0, $x1 = -1, $y1 = -1)
	Local Const $WM_GETMINMAXINFO = 0x24
	Global $aWset_MinMax[5][10] ; La variable globale est définie ici pour que la fonction soit "à emporter"
	Local $i = 0, $ok = False
	Do
		If $aWset_MinMax[0][$i] = 0 Then
			$aWset_MinMax[0][$i] = $hWnd
			$aWset_MinMax[1][$i] = $x0
			$aWset_MinMax[2][$i] = $y0
			$aWset_MinMax[3][$i] = $x1
			$aWset_MinMax[4][$i] = $y1
			$ok = True
		EndIf
		$i += 1
		If $i > 9 Then _Trace("Erreur lors de la définition Max/Min de la GUI (Mémoire pleine).")
	Until $ok = True Or $i > 9
	GUIRegisterMsg($WM_GETMINMAXINFO, '_WM_GETMINMAXINFO')
EndFunc   ;==>_WinSetMinMax

; #FUNCTION# ====================================================================================================================
; Name ..........: MY_WM_GETMINMAXINFO
; Description ...:
; Syntax ........: MY_WM_GETMINMAXINFO($hWnd, $Msg, $wParam, $lParam)
; Parameters ....: $hWnd                - a handle value.
;                  $Msg                 - an unknown value.
;                  $wParam              - an unknown value.
;                  $lParam              - an unknown value.
; Return values .: None
; Author ........: jbs
; ===============================================================================================================================
Func _WM_GETMINMAXINFO($hWnd, $Msg, $wParam, $lParam)
	Local $minmaxinfo = DllStructCreate('int;int;int;int;int;int;int;int;int;int', $lParam)
	For $i = 0 To 9
		If $aWset_MinMax[0][$i] = $hWnd Then
			DllStructSetData($minmaxinfo, 7, $aWset_MinMax[1][$i]) ; min X
			DllStructSetData($minmaxinfo, 8, $aWset_MinMax[2][$i]) ; min Y
			If $aWset_MinMax[3][$i] <> -1 Then DllStructSetData($minmaxinfo, 9, $aWset_MinMax[3][$i]) ; max X
			If $aWset_MinMax[4][$i] <> -1 Then DllStructSetData($minmaxinfo, 10, $aWset_MinMax[4][$i]) ; max Y
		EndIf
	Next
	Return $GUI_RUNDEFMSG
EndFunc   ;==>_WM_GETMINMAXINFO

;~ Func StyleToggle($Off = 1)
;~ 	If Not StringInStr(@OSTYPE, "WIN32_NT") Then Return 0
;~ 	Local $XS_n
;~ 	If $Off Then
;~ 		$XS_n = DllCall("uxtheme.dll", "int", "GetThemeAppProperties")
;~ 		DllCall("uxtheme.dll", "none", "SetThemeAppProperties", "int", 0)
;~ 		Return 1
;~ 	ElseIf IsArray($XS_n) Then
;~ 		DllCall("uxtheme.dll", "none", "SetThemeAppProperties", "int", $XS_n[0])
;~ 		$XS_n = ""
;~ 		Return 1
;~ 	EndIf
;~ 	Return 0
;~ EndFunc

#EndRegion Fonctions liées à la gestion des GUI

#Region Fonctions d'aide au debug
; #FUNCTION# ====================================================================================================================
; Name ..........: _ConsoleWrite
; Description ...: Permet d'écrire dans la console en UTF8
; Syntax ........: GuiCenter($hGuiMain)
; Parameters ....: $sString            - a string value.
; Return values .: None
; Author ........: jchd
; ===============================================================================================================================
Func _ConsoleWrite($sString)
	Local $aResult = DllCall("kernel32.dll", "int", "WideCharToMultiByte", "uint", 65001, "dword", 0, "wstr", $sString, "int", -1, _
			"ptr", 0, "int", 0, "ptr", 0, "ptr", 0)
	If @error Then Return SetError(1, @error, 0)
	Local $tText = DllStructCreate("char[" & $aResult[0] & "]")
	$aResult = DllCall("Kernel32.dll", "int", "WideCharToMultiByte", "uint", 65001, "dword", 0, "wstr", $sString, "int", -1, _
			"ptr", DllStructGetPtr($tText), "int", $aResult[0], "ptr", 0, "ptr", 0)
	If @error Then Return SetError(2, @error, 0)
	ConsoleWrite(DllStructGetData($tText, 1) & @CRLF)
EndFunc   ;==>_ConsoleWrite

; #FUNCTION# ====================================================================================================================
; Name ..........: _TraceInit
; Description ...: Initialise les éléments nécessaires à la fonction _Trace : répertoire, variables.
; Syntax ........: _TraceInit()
; Return values .: True si succès, False sinon.
; Author ........: jbs
; ===============================================================================================================================
Func _TraceInit()
	Global $logDir = @ScriptDir & "\Traces"
	Global $logFile = $logDir & "\" & @YEAR & "-" & @MON & "-" & @MDAY & ".log"
	Local $cpt = 0
	If Not FileExists($logDir) Then
		If Not DirCreate($logDir) Then Return False
	Else
		While DirGetSize($logDir) > 5242880 And $cpt <= 1000 ;5Mo
			FileDelete(FileFindFirstFile($logDir)
			$cpt += 1
		WEnd
		If $cpt > 1000 Then Return False
	EndIf
	Return True
EndFunc   ;==>_TraceInit

; #FUNCTION# ====================================================================================================================
; Name ..........: _Trace
; Description ...: Enregistre une string dans un fichier de log et envoie également le texte vers la console.
; Syntax ........: _Trace($sString)
; Parameters ....: $sString             - a string value.
; Return values .: True si succès, False sinon.
; Author ........: jbs
; ===============================================================================================================================
Func _Trace($sString)
	If Not FileExists($logDir) Then Return False
	If $logDir & "\" & @YEAR & "-" & @MON & "-" & @MDAY & ".log" <> $logFile Then $logFile = $logDir & "\" & @YEAR & "-" & @MON & "-" & @MDAY & ".log" ; Gestion du changement de date en cours d'exécution du soft.
	Local $hFileOpen = FileOpen($logFile, $FO_APPEND)
	If $hFileOpen <> -1 Then
		FileWriteLine($hFileOpen, "[" & @YEAR & "/" & @MON & "/" & @MDAY & "_" & @HOUR & ":" & @MIN & ":" & @SEC & ":" & @MSEC & "] " & $sString)
		FileClose($hFileOpen)
		_ConsoleWrite(">" & $sString)
	EndIf
	Return True
EndFunc   ;==>_Trace

#EndRegion Fonctions d'aide au debug

#Region Fonctions de conversion
Func _Time_sec2ms($Time)
	Local $retVal = 0
	$retVal = $Time * 1000
	Return $retVal
EndFunc   ;==>_Time_sec2ms

Func _Time_min2ms($Time)
	Local $retVal = 0
	$retVal = $Time * 60 * 1000
	Return $retVal
EndFunc   ;==>_Time_min2ms

Func _Time_hour2ms($Time)
	Local $retVal = 0
	$retVal = $Time * 60 * 60 * 1000
	Return $retVal
EndFunc   ;==>_Time_hour2ms

Func _Time_day2ms($Time)
	Local $retVal = 0
	$retVal = $Time * 24 * 60 * 60 * 1000
	Return $retVal
EndFunc   ;==>_Time_day2ms

#EndRegion Fonctions de conversion

#Region Fonctions de connexion
Func Check_Internet_Status()
	If OnlineStatus() = 1 Then
		GUICtrlSetColor($lParam_ProxyStatus, 0x007f00)
		GUICtrlSetData($lParam_ProxyStatus, Translate("You are connected"))
	Else
		GUICtrlSetColor($lParam_ProxyStatus, 0xAA0000)
		GUICtrlSetData($lParam_ProxyStatus, Translate("You are disconnected"))
	EndIf
EndFunc   ;==>Check_Internet_Status

Func OnlineStatus()
	GUICtrlSetColor($lParam_ProxyStatus, 0xFF9104)
	GUICtrlSetData($lParam_ProxyStatus, Translate("Testing"))
	$inet = InetGet("http://www.google.com", @TempDir & "\connectivity-test.tmp", 3, 0)
	If @error Or $inet = 0 Then
		Return 0
	Else
		Return 1
	EndIf
EndFunc   ;==>OnlineStatus

Func SetProxy($param)
	Switch $param
		Case 0
			HttpSetProxy(0)
		Case 1
			HttpSetProxy(1)
		Case 2
			Local $proxy_url = IniRead($param_ini, "PROXY", "Url", "")
			Local $proxy_port = IniRead($param_ini, "PROXY", "Port", "")
			Local $proxy_username = IniRead($param_ini, "PROXY", "User", "")
			Local $proxy_password = _StringCryptDecrypt(False, IniRead($param_ini, "PROXY", "Password", ""))
			If $proxy_url <> "" And $proxy_port <> "" Then
				$proxy_url &= ":" & $proxy_port
				If $proxy_username <> "" Then
					If $proxy_password <> "" Then
						HttpSetProxy(2, $proxy_url, $proxy_username, $proxy_password)
					Else
						HttpSetProxy(2, $proxy_url, $proxy_username)
					EndIf
				Else
					HttpSetProxy(2, $proxy_url)
				EndIf
			EndIf
	EndSwitch
EndFunc   ;==>SetProxy

#EndRegion Fonctions de connexion

#Region Fonctions diverses
; #FUNCTION# ====================================================================================================================
; Name ..........: _SelectFolder
; Description ...: Opens a windows for selecting a destination folder.
; Syntax ........: _SelectFolder([$hGui = 0])
; Parameters ....: $hGui                - [optional] a handle value. Default is 0.
; Return values .: None
; Author ........: The AutoItObject-Team
; Modified ......: jbs
; ===============================================================================================================================
Func _SelectFolder($hGui = 0)
	;Starts AIO up
	_AutoItObject_StartUp()
	;Define IShellDispatch vTable methods
	Local $tagIShellDispatch = $ltagIDispatch & _
			"Application;" & _
			"Parent;" & _
			"NameSpace;" & _
			"BrowseForFolder;" & _
			"Windows;" & _
			"Open;" & _
			"Explore;" & _
			"MinimizeAll;" & _
			"UndoMinimizeAll;" & _
			"FileRun;" & _
			"CascadeWindows;" & _
			"TileVertically;" & _
			"TileHorizontally;" & _
			"ShutdownWindows;" & _
			"Suspend;" & _
			"EjectPC;" & _
			"SetTime;" & _
			"TrayProperties;" & _
			"Help;" & _
			"FindFiles;" & _
			"FindComputer;" & _
			"RefreshMenu;" & _
			"ControlPanelItem;" & _ ; IShellDispatch
			"IsRestricted;" & _
			"ShellExecute;" & _
			"FindPrinter;" & _
			"GetSystemInformation;" & _
			"ServiceStart;" & _
			"ServiceStop;" & _
			"IsServiceRunning;" & _
			"CanStartStopService;" & _
			"ShowBrowserBar;" & _ ; IShellDispatch2
			"AddToRecent;" & _ ; IShellDispatch3
			"WindowsSecurity;" & _
			"ToggleDesktop;" & _
			"ExplorerPolicy;" & _
			"GetSetting;" ; IShellDispatch4
	;Creates the object
	Local $oShellWrapped = _AutoItObject_ObjCreate("Shell.Application", Default, $tagIShellDispatch)
	;Byref (last parameter):
	;iOptions param is BIF_EDITBOX
	Local $aCall = $oShellWrapped.BrowseForFolder("long", "hwnd", $hGui, "wstr", Translate("Please select a destination folder."), "dword", 0x00000010, "variant", 0x00, "idispatch*", 0)
	Local $oFolder = $aCall[5]
	Local $sFolder = ""
	If IsObj($oFolder) Then $sFolder = $oFolder.Self.Path
	;Shuts AIO down
	_AutoItObject_Shutdown()
	Return $sFolder
EndFunc   ;==>_SelectFolder

; #FUNCTION# ====================================================================================================================
; Name ..........: _StringCryptDecrypt
; Description ...:
; Syntax ........: _StringCryptDecrypt($bEncrypt, $sData)
; Parameters ....: $bEncrypt            - a boolean value.
;                  $sData               - a string value.
; Return values .: a string value
; Author ........: monoceres / jchd
; Modified ......: jbs
; ===============================================================================================================================
Func _StringCryptDecrypt($bEncrypt, $sData)
	_Crypt_Startup() ; Start the Crypt library.
	Local $sReturn = ""
	If $bEncrypt Then ; If the flag is set to True then encrypt, otherwise decrypt.
		$sReturn = _Crypt_EncryptData($sData, "TUC_Downloader", $CALG_AES_256)
	Else
		$sReturn = BinaryToString(_Crypt_DecryptData($sData, "TUC_Downloader", $CALG_AES_256))
	EndIf
	_Crypt_Shutdown() ; Shutdown the Crypt library.
	Return $sReturn
EndFunc   ;==>_StringCryptDecrypt

#EndRegion Fonctions diverses
