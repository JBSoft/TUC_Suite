#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Resources\Images\TUC\TUC.ico
#AutoIt3Wrapper_Outfile=TUC_Downloader.exe
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Fileversion=1.0.0.3
#AutoIt3Wrapper_Res_Language=1036
#AutoIt3Wrapper_Run_AU3Check=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#cs
	2016-07-02 -- Premier commit sur github
	2016-07-06 v1.0.0.2 -- Correction du verrouillage de la taille mini de la fenêtre principale
	- Traductions en français
	- Corrections multiples
	2016-07-13 v1.0.0.3
	- Correction de la gestion des erreurs de connexions pour toutes les fonctions de récupérations sur le site Updapy
	- Ajout de traductions françaises
	- Ajout d'un max de traces de débug
	- Ajout d'une constante pour définir si on tourne en débug ou non (traces conditionnées)
	- Ajout de l'affichage du temps restant avant la prochaine recherche de MAJ automatique
	- Suppression de la vérification de la taille téléchargée en fin de téléchargement : ça plantait la plupart du temps alors que sans vérif ça marche :s
	- Modification du calcul de vitesses : on se base maintenant sur un tableau des 10 dernières valeurs glissantes pour calculer une moyenne
	- Initialisation de la liste des logiciels suivi si c'est la première utilisation du soft
#ce

FileChangeDir(@ScriptDir)
HttpSetProxy(0)

#include ".\Includes\TUC_Functions.au3"
#include <TrayConstants.au3>

If _TraceInit() Then _Trace("Ouverture de TUC_Downloader.")
Global $Updapy = "http://www.updapy.com/"
Global $First = False
Global $Add = 0
Global $Param = 0
Global $Survey = 0
Global $TimerValue = 0, $TimeValue = 0
Global $param_ini = @AppDataDir & "\TUC\TUC.ini"
Global Const $AVEC_HSCROLL = False
Global Const $AVEC_DEBUG = True

Global $sSQliteDll = _SQLite_Startup(".\Resources\DLL\SQLite3.dll")
If @error Then
	_Trace("SQLite Error", "SQLite3.dll Can't be Loaded!")
	Exit
EndIf
Global $hBDD = _SQLite_Open(".\Resources\BDD\TUC.sqlite") ; Open/Create a permanent disk database
If @error Then
	_Trace("SQLite Error", "Can't open or create a permanent Database!")
	Exit
EndIf
_SQLite_Exec($hBDD, 'CREATE TABLE IF NOT EXISTS Logiciels (Titre_Long, Titre_Court, Selection, Version_Dispo, Version_Download, Version_Install)')

If Not FileExists($param_ini) Then
	MsgBox($MB_ICONWARNING, "TUC_Downloader - First start", "It seems like it is the first time you open ""TUC_Downloader""." & @CRLF & @CRLF & "Please set your parameters.") ; Pas de traduction ici : la langue n'est pas encore sélectionnée !
	$First = True
	DirCreate(@AppDataDir & "\TUC")
	Init_Survey_List()
EndIf
Param_Set()

If @Compiled Then
	Dim Const $Version = FileGetVersion(@ScriptDir & "\TUC_Downloader.exe")
Else
	Dim Const $Version = "T.E.S.T."
EndIf



#Region ### START Koda GUI section ###
;Définition des options générales de la GUI
Opt("GUIOnEventMode", 1)
Global $Main = GUICreate("TUC_Downloader", 615, 430, -1, -1, BitOR($GUI_SS_DEFAULT_GUI, $WS_MAXIMIZEBOX, $WS_SIZEBOX))
GUISetOnEvent($GUI_EVENT_CLOSE, "MainClose")
GUISetOnEvent($GUI_EVENT_MINIMIZE, "MainMinimize")
GUISetOnEvent($GUI_EVENT_MAXIMIZE, "MainMaximize")
GUISetOnEvent($GUI_EVENT_RESTORE, "MainRestore")
GUISetIcon(".\Resources\Images\TUC\TUC.ico")
_WinSetMinMax($Main, 615, 225)

;Création de la MenuBar (mb)
Global Enum $mbExit = 200, $mbAdd, $mbDown, $mbSearch, $mbParam, $mbSite, $mbAbout
;Menu "Fichier"
Global $Menu_File = _GUICtrlMenu_CreateMenu() ;GUICtrlCreateMenu("&Fichier")
_GUICtrlMenu_InsertMenuItem($Menu_File, 0, Translate("&Quit"), $mbExit)
_GUICtrlMenu_SetItemBmp($Menu_File, 0, _BmpGetHandle(".\Resources\Images\cancel.bmp"))
;Menu "Gestion"
Global $Menu_Manage = _GUICtrlMenu_CreateMenu() ;GUICtrlCreateMenu("&Gestion")
_GUICtrlMenu_InsertMenuItem($Menu_Manage, 0, Translate("&Add a software to follow"), $mbAdd)
_GUICtrlMenu_SetItemBmp($Menu_Manage, 0, _BmpGetHandle(".\Resources\Images\ajout.bmp"))
_GUICtrlMenu_InsertMenuItem($Menu_Manage, 1, Translate("&Download all followed softwares"), $mbDown)
_GUICtrlMenu_SetItemBmp($Menu_Manage, 1, _BmpGetHandle(".\Resources\Images\download.bmp"))
_GUICtrlMenu_InsertMenuItem($Menu_Manage, 2, Translate("&Search for last online versions"), $mbSearch)
_GUICtrlMenu_SetItemBmp($Menu_Manage, 2, _BmpGetHandle(".\Resources\Images\recherche.bmp"))
_GUICtrlMenu_InsertMenuItem($Menu_Manage, 3, "", 0)
_GUICtrlMenu_InsertMenuItem($Menu_Manage, 4, Translate("&Change settings"), $mbParam)
_GUICtrlMenu_SetItemBmp($Menu_Manage, 4, _BmpGetHandle(".\Resources\Images\param.bmp"))
;Menu "Aide"
Global $Menu_Help = _GUICtrlMenu_CreateMenu() ;GUICtrlCreateMenu("&Aide")
_GUICtrlMenu_InsertMenuItem($Menu_Help, 0, Translate("&Updapy web site"), $mbSite)
_GUICtrlMenu_SetItemBmp($Menu_Help, 0, _BmpGetHandle(".\Resources\Images\updapy.bmp"))
_GUICtrlMenu_InsertMenuItem($Menu_Help, 1, Translate("&About"), $mbAbout)
_GUICtrlMenu_SetItemBmp($Menu_Help, 1, _BmpGetHandle(".\Resources\Images\TUC.bmp"))
;Création de la barre de Menu
Global $Menu = _GUICtrlMenu_CreateMenu()
_GUICtrlMenu_InsertMenuItem($Menu, 0, Translate("&File"), 0, $Menu_File)
_GUICtrlMenu_InsertMenuItem($Menu, 1, Translate("&Manage"), 0, $Menu_Manage)
_GUICtrlMenu_InsertMenuItem($Menu, 2, Translate("&Help"), 0, $Menu_Help)
;Affectation du menu à la GUI
_GUICtrlMenu_SetMenu($Main, $Menu)

$tbImages = _GUIImageList_Create(32, 32, 5)
_GUIImageList_AddIcon($tbImages, ".\Resources\Images\Updapy.ico", 0, True)
_GUIImageList_AddIcon($tbImages, ".\Resources\Images\ajout.ico", 0, True)
_GUIImageList_AddIcon($tbImages, ".\Resources\Images\download.ico", 0, True)
_GUIImageList_AddIcon($tbImages, ".\Resources\Images\recherche.ico", 0, True)
_GUIImageList_AddIcon($tbImages, ".\Resources\Images\param.ico", 0, True)
$ToolBar = _GUICtrlToolbar_Create($Main, BitOR($TBSTYLE_TRANSPARENT, $TBSTYLE_FLAT))
_GUICtrlToolbar_SetImageList($ToolBar, $tbImages)
$ToolTip = _GUIToolTip_Create($ToolBar)
_GUICtrlToolbar_SetToolTips($ToolBar, $ToolTip)
Global Enum $tbUpdapy = 100, $tbAdd, $tbDown, $tbSearch, $tbParam
_GUICtrlToolbar_AddButton($ToolBar, $tbUpdapy, 0, 0)
_GUICtrlToolbar_AddButtonSep($ToolBar)
_GUICtrlToolbar_AddButton($ToolBar, $tbAdd, 1, 0)
_GUICtrlToolbar_AddButton($ToolBar, $tbDown, 2, 0)
_GUICtrlToolbar_AddButton($ToolBar, $tbSearch, 3, 0)
_GUICtrlToolbar_AddButtonSep($ToolBar)
_GUICtrlToolbar_AddButton($ToolBar, $tbParam, 4, 0)
Global $TimeDisplay = GUICtrlCreateLabel("00:00:00", 510, 7, 100, 40, $SS_RIGHT)
GUICtrlSetResizing(-1, BitOR($GUI_DOCKMENUBAR, $GUI_DOCKWIDTH, $GUI_DOCKRIGHT))
GUICtrlSetFont(-1, 20)
GUICtrlSetState(-1, $GUI_HIDE)

Global $ItemClicked, $iCB, $tSCROLLINFO, $iDLLUser32 = DllOpen("user32.dll")
Global $ListView = GUICtrlCreateListView(Translate("Software|Local Version|Online Version"), 8, 48, 601, 332)
GUICtrlSetResizing(-1, BitOR($GUI_DOCKLEFT, $GUI_DOCKRIGHT, $GUI_DOCKTOP, $GUI_DOCKBOTTOM))
_GUICtrlListView_SetExtendedListViewStyle($ListView, BitOR($WS_EX_CLIENTEDGE, $LVS_EX_SUBITEMIMAGES, $LVS_EX_FULLROWSELECT, $LVS_EX_UNDERLINECOLD, $LVS_EX_DOUBLEBUFFER, $LVS_EX_CHECKBOXES))
If $AVEC_HSCROLL Then $wProcOldLV = _InitializeLV($ListView, $iCB, $tSCROLLINFO)
_GUICtrlListView_SetColumnWidth($ListView, 0, 300)
_GUICtrlListView_SetColumnWidth($ListView, 1, 140)
_GUICtrlListView_SetColumnWidth($ListView, 2, 140)
;~ _GUICtrlListView_SetColumnWidth($ListView, 2, $LVSCW_AUTOSIZE_USEHEADER)

;~ StyleToggle(1)
Global $StatusBar = _GUICtrlStatusBar_Create($Main, -1, "", BitOR($SBARS_SIZEGRIP, $WS_VISIBLE, $WS_CHILD))
Dim $aParts = [140, 300, 595]
_GUICtrlStatusBar_SetParts($StatusBar, $aParts)
If Not @Compiled Then
	_GUICtrlStatusBar_SetText($StatusBar, "  " & Translate("Not compiled version"), 0)
Else
	_GUICtrlStatusBar_SetText($StatusBar, "  " & Translate("Version:") & " " & $Version, 0)
EndIf
;~ _GUICtrlStatusBar_EmbedControl($StatusBar, 2, GUICtrlGetHandle(GUICtrlCreateLabel("Surveillance inactive     ", 5,5)))
_GUICtrlStatusBar_SetText($StatusBar, @TAB & @TAB & Translate("Survey disabled") & "     ", 2)
;~ _GUICtrlStatusBar_SetBkColor($StatusBar, 0x00ff00)
;~ StyleToggle(0)

;Création du TrayMenu
;Définition des options générales du Tray
Opt("TrayMenuMode", 2)
Opt("TrayIconDebug", 1)
Opt("TrayAutoPause", 0)
Opt("TrayOnEventMode", 1)

TraySetIcon(".\Resources\Images\TUC\TUC.ico")
TraySetClick("9")
Global $Tray_Survey = TrayCreateItem(Translate("Survey"), -1, -1, $TRAY_ITEM_RADIO)
TrayItemSetOnEvent(-1, "Tray_Survey")
Global $Tray_About = TrayCreateItem(Translate("About"))
TrayItemSetOnEvent(-1, "Tray_About")
Global $Tray_Quit = TrayCreateItem(Translate("Quit"))
TrayItemSetOnEvent(-1, "Tray_Exit")

;Mise en place de l'écoute des messages de fenêtre
GUIRegisterMsg($WM_SIZE, "MainResize")
GUIRegisterMsg($WM_NOTIFY, "MainNotify")
GUIRegisterMsg($WM_COMMAND, "MainCommand")

If $First = False Then
	GUISetState(@SW_SHOW, $Main)
Else
	tbParam()
EndIf
#EndRegion ### END Koda GUI section ###

Afficher_ListView()

While 1
	Sleep(100)
WEnd

Func Tray_Survey()
	If $Survey = 0 Then
		AdlibRegister("_DownReg", _Time_min2ms($TIME_SURVEY))
		$TimerValue = TimerInit()
		AdlibRegister("_TimeReg", 1000)
		GUICtrlSetState($TimeDisplay, $GUI_SHOW)
		_Trace("Surveillance active.")
		_GUICtrlStatusBar_SetText($StatusBar, @TAB & @TAB & Translate("Survey enabled") & "     ", 2)
		$Survey = 1
	Else
		AdlibUnRegister("_DownReg")
		AdlibUnRegister("_TimeReg")
		GUICtrlSetData($TimeDisplay, "00:00:00")
		GUICtrlSetState($TimeDisplay, $GUI_HIDE)
		_Trace("Surveillance inactive.")
		TrayItemSetState($Tray_Survey, $TRAY_UNCHECKED)
		_GUICtrlStatusBar_SetText($StatusBar, @TAB & @TAB & Translate("Survey disabled") & "     ", 2)
		$Survey = 0
	EndIf
EndFunc   ;==>Tray_Survey

Func Tray_About()
	Help_About()
EndFunc   ;==>Tray_About

Func Tray_Exit()
	Quit()
EndFunc   ;==>Tray_Exit

Func File_Exit()
	Quit()
EndFunc   ;==>File_Exit

Func Manage_Add()
	tbAdd()
EndFunc   ;==>Manage_Add

Func Manage_Down()
	tbDown()
EndFunc   ;==>Manage_Down

Func Manage_Search()
	tbSearch()
EndFunc   ;==>Manage_Search

Func Manage_Param()
	tbParam()
EndFunc   ;==>Manage_Param

Func Help_About()
	#Region ### START Koda GUI section ###
	Global $About_GUI = GUICreate(Translate("About"), 260, 235, -1, -1, -1, -1, $Main)
	GUISetOnEvent($GUI_EVENT_CLOSE, "About_Close")
	GUISetIcon(".\Resources\Images\TUC\TUC.ico")
	GUICtrlCreateGroup("", 5, 0, 250, 200)
	GUICtrlCreateGroup("", 10, 5, 70, 75)
	GUICtrlCreateIcon(".\Resources\Images\TUC\TUC.ico", -1, 13, 13, 64, 64)
	GUICtrlCreateLabel("TUC_Downloader", 100, 20, 100, 20)
	GUICtrlSetFont(-1, 10)
	GUICtrlCreateLabel(Translate("Version:") & " " & $Version, 100, 45, 100, 17)
	GUICtrlCreateLabel("Tiny Updapy Client - Downloader", 10, 90, 240, 17)
	GUICtrlCreateLabel(Translate("Related softwares: ""TUC Server"" and ""TUC Client""."), 10, 110, 240, 37)
	GUICtrlCreateLabel(Translate("Licence/Rights: GNU GPL."), 10, 160, 240, 17)
;~ 	GUICtrlCreateLabel(Translate("Ce produit n'est pas une marque déposée."), 10, 160, 240, 17)
;~ 	GUICtrlCreateLabel("L'utiliser, le modifier, le détourner est autorisé.", 10, 180, 240, 17)
	Global $About_BtOK = GUICtrlCreateButton("&OK", 95, 205, 70, 25)
	GUICtrlSetOnEvent(-1, "About_OK")
	GUISetState(@SW_SHOW, $About_GUI)
	#EndRegion ### END Koda GUI section ###
EndFunc   ;==>Help_About

Func Help_Site()
	OpenWeb($Updapy)
EndFunc   ;==>Help_Site

Func MainClose()
	Quit()
EndFunc   ;==>MainClose

Func MainMaximize()
	Resize()
EndFunc   ;==>MainMaximize

Func MainMinimize()
	Resize()
EndFunc   ;==>MainMinimize

Func MainRestore()
	Resize()
EndFunc   ;==>MainRestore

Func MainResize()
	Resize()
EndFunc   ;==>MainResize

Func MainNotify($hWndGUI, $iMsgID, $wParam, $lParam) ;Fonction qui gère la "ToolBar"
	$tNMHDR = DllStructCreate($tagNMHDR, $lParam)
	$hWndFrom = DllStructGetData($tNMHDR, "hWndFrom")
	$iCode = DllStructGetData($tNMHDR, "Code")
	Switch $hWndFrom
		Case $ToolBar
			Switch $iCode
				Case $NM_LDOWN ;Un Clic a été effectué, on vérife quel bouton on survolait à ce moment ($ItemClicked)
					Switch $ItemClicked
						Case $tbUpdapy
							tbUpdapy()
						Case $tbAdd
							tbAdd()
						Case $tbDown
							tbDown()
						Case $tbSearch
							tbSearch()
						Case $tbParam
							tbParam()
					EndSwitch
				Case $TBN_HOTITEMCHANGE ;Mise à jour de la valeur au survol
					$tNMTBHOTITEM = DllStructCreate($tagNMTBHOTITEM, $lParam)
					$ItemClicked = DllStructGetData($tNMTBHOTITEM, "idNew")
					$iFlags = DllStructGetData($tNMTBHOTITEM, "dwFlags")
			EndSwitch
	EndSwitch
	$tInfo = DllStructCreate($tagNMTTDISPINFO, $lParam)
	$iCodeTip = DllStructGetData($tInfo, "Code")
	If $iCodeTip = $TTN_GETDISPINFOW Then ;Affichage du Tip
		$iID = DllStructGetData($tInfo, "IDFrom")
		Switch $iID
			Case $tbUpdapy
				DllStructSetData($tInfo, "aText", Translate("Click here to open Updapy web site."))
			Case $tbAdd
				DllStructSetData($tInfo, "aText", Translate("Click here to add a software in your followed list."))
			Case $tbDown
				DllStructSetData($tInfo, "aText", Translate("Click here to download the followed softwares."))
			Case $tbSearch
				DllStructSetData($tInfo, "aText", Translate("Click here to check if new versions are online."))
			Case $tbParam
				DllStructSetData($tInfo, "aText", Translate("Click here to change some settings."))
		EndSwitch
	EndIf
	Return $GUI_RUNDEFMSG
EndFunc   ;==>MainNotify

Func MainCommand($hWnd, $iMsg, $wParam, $lParam) ;Fonction qui gère la "MenuBar"
	Switch _WinAPI_LoWord($wParam)
		Case $mbExit
			File_Exit()
		Case $mbAdd
			Manage_Add()
		Case $mbDown
			Manage_Down()
		Case $mbSearch
			Manage_Search()
		Case $mbParam
			Manage_Param()
		Case $mbAbout
			Help_About()
		Case $mbSite
			Help_Site()
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>MainCommand

Func tbUpdapy()
	OpenWeb($Updapy)
EndFunc   ;==>tbUpdapy

Func tbAdd()
	Local $gui_Largeur = 310
	Local $gui_Hauteur = 400
	Local $aCenter[2]
	If $Main <> 0 Then
		$aCenter = _WinGetCenter($Main)
		$aCenter[0] -= $gui_Largeur / 2
		$aCenter[1] -= $gui_Hauteur / 2
	Else
		$aCenter[0] = -1
		$aCenter[1] = -1
	EndIf
	If $Add = 0 Then
		#Region ### START Koda GUI section ###
		Global $Add = GUICreate(Translate("Add softwares"), $gui_Largeur, $gui_Hauteur, $aCenter[0], $aCenter[1])
		GUISetOnEvent($GUI_EVENT_CLOSE, "AddClose")
		GUISetIcon(".\Resources\Images\TUC\TUC.ico")
		Global $Add_btRefresh = GUICtrlCreateButton(Translate("&Refresh"), 50, 365, 70, 25)
		GUICtrlSetOnEvent(-1, "Add_btRefresh")
		Global $Add_btOK = GUICtrlCreateButton("&OK", 120, 365, 70, 25)
		GUICtrlSetOnEvent(-1, "Add_btOK")
		Global $Add_btCancel = GUICtrlCreateButton(Translate("&Cancel"), 190, 365, 70, 25)
		GUICtrlSetOnEvent(-1, "Add_btCancel")
		Global $Add_List = GUICtrlCreateListView("", 5, 5, 300, 350, -1, BitOR($WS_EX_CLIENTEDGE, $LVS_EX_SUBITEMIMAGES, $LVS_EX_CHECKBOXES))
		_GUICtrlListView_SetView($Add_List, 4)
		GUICtrlSetResizing(-1, BitOR($GUI_DOCKLEFT, $GUI_DOCKRIGHT, $GUI_DOCKTOP, $GUI_DOCKBOTTOM))
		GUICtrlSetOnEvent(-1, "Add_List")
		GUISetState(@SW_SHOW, $Add)
		#EndRegion ### END Koda GUI section ###
		Afficher_Add_List()
	Else
		WinMove($Add, "", $aCenter[0], $aCenter[1])
		GUISetState(@SW_SHOW, $Add)
	EndIf
EndFunc   ;==>tbAdd

Func tbDown($mb = 0)
	$FuncName = """tbDown"""
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Ouverture fonction.")
	If TrayItemGetState($Tray_Survey) = 65 Then
		AdlibUnRegister("_DownReg")
		AdlibUnRegister("_TimeReg")
		GUICtrlSetData($TimeDisplay, "00:00:00")
		If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Désenregistrement de la fonction ""_DownReg"".")
	EndIf
	If Not tbSearch(1) Then
		If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - La fonction ""tbSearch"" ne s'est pas terminée correctement : on sort de suite.")
		If $mb = 0 Then MsgBox($MB_ICONWARNING, Translate("Online error"), Translate("Something went wrong during the online search.") & @CRLF & Translate("Please check your internet connexion."))
		If TrayItemGetState($Tray_Survey) = 65 Then
			AdlibRegister("_DownReg", _Time_min2ms($TIME_SURVEY))
			AdlibRegister("_TimeReg", 1000)
			$TimerValue = TimerInit()
		EndIf
		Return
	EndIf
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Comptage du nombre de softs à surveiller.")
	;Telechargement des logiciels disponibles
	Local $Dim = _GUICtrlListView_GetItemCount($ListView)
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Il y a " & $Dim & " softs à surveiller.")
	Local $lien, $hDownload, $iBytesSize, $iFileSize, $prog, $delete
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Lancement de la boucle de récupération.")
	For $i = 0 To $Dim - 1
;~ 		_ConsoleWrite(">"&_GUICtrlListView_GetItem($ListView, $i, 1)[3]&" / "&_GUICtrlListView_GetItem($ListView, $i, 2)[3]&@CRLF)
		If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Itération n°" & $i & ".")
		If _GUICtrlListView_GetItem($ListView, $i, 1)[3] <> _GUICtrlListView_GetItem($ListView, $i, 2)[3] Then
			If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Cette appli n'a pas la même versio en local qu'en distant.")
			$sMsg = SQL_Get_Data($hBDD, "Logiciels", "Titre_Court", "Titre_Long = '" & SQL_String(_GUICtrlListView_GetItem($ListView, $i)[3]) & "'")
			If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Le titre court de cette appli est : """ & $sMsg & """.")
			If $sMsg <> "" Then
				$lien = ""
				$aGet = GetAppDetail($sMsg, $API, $Base64_ID)
				If Not IsArray($aGet) Then Return
				If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - La fonction ""GetAppDetail"" est finie. On traite ce qu'elle a renvoyé.")
				If $aGet[6] <> "null" Then ;Le logiciel existe en français en 64bit
					$lien = $aGet[6]
				ElseIf $aGet[5] <> "null" Then ;Le logiciel existe en français en 32bit
					$lien = $aGet[5]
				ElseIf $aGet[4] <> "null" Then ;Le logiciel existe en anglais en 64bit
					$lien = $aGet[4]
				ElseIf $aGet[3] <> "null" Then ;Le logiciel existe en anglais en 32bit
					$lien = $aGet[3]
				Else
					MsgBox($MB_ICONWARNING, Translate("No link found"), Translate("No download link has been found."))
				EndIf
				If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Le traitement est fini.")
				;Traitement des logiciels à la con :
				Switch _GUICtrlListView_GetItem($ListView, $i)[3]
					Case "Skype"
						$lien = "https://download.skype.com/msi/SkypeSetup_" & _GUICtrlListView_GetItem($ListView, $i, 2)[3] & ".msi"
;~ 					Case "Chrome"
;~ 						$lien = "https://dl.google.com/chrome/install/standalonesetup64.exe"
					Case Else
						$lien = $lien
				EndSwitch
				_Trace("Lancement du téléchargement à l'adresse : " & $lien)
				If $lien <> "" Then ;Téléchargement du logiciel
					_ProgressOn(Translate("Download"), _GUICtrlListView_GetItem($ListView, $i)[3], Translate("Version:") & " " & $aGet[2], ".\Resources\Images\Softs\BMP\" & $sMsg & ".bmp", False, $Main, True)
;~ 					$hDownload = InetGet($lien, $CheminLogiciels & $sMsg & "_" & $aGet[2] & ".exe", BitOR($INET_FORCERELOAD, $INET_IGNORESSL, $INET_BINARYTRANSFER), $INET_DOWNLOADBACKGROUND)
					$hDownload = InetGet($lien, $CheminLogiciels & $sMsg & "_" & $aGet[2] & ".exe", $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
					$iFileSize = InetGetSize($lien, $INET_FORCERELOAD)
					_ProgressSet(0, "0 / " & _GetDisplaySize($iFileSize))
					$delete = 0
					Do
						Sleep(250)
						If _ProgressGet() = 1 Then
							If $hDownload = 0 Then
;~ 								$hDownload = InetGet($lien, $CheminLogiciels & $sMsg & "_" & $aGet[2] & ".exe", BitOR($INET_LOCALCACHE, $INET_IGNORESSL, $INET_BINARYTRANSFER), $INET_DOWNLOADBACKGROUND)
								$hDownload = InetGet($lien, $CheminLogiciels & $sMsg & "_" & $aGet[2] & ".exe", $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
								_Trace("Reprise du téléchargement.")
							EndIf
							$iBytesSize = InetGetInfo($hDownload, $INET_DOWNLOADREAD)
							$prog = Round(($iBytesSize / $iFileSize) * 100)
							_ProgressSet($prog, _GetDisplaySize($iBytesSize) & " / " & _GetDisplaySize($iFileSize) & "  => " & _GetDisplaySize(Vitesse($iBytesSize)) & "/s")
						EndIf
						If _ProgressGet() = 2 Then ;Si le progress est en pause on fait en sorte que le for n'avance plus et on met un peu de sleep pour soulager le processeur.
							If $hDownload <> 0 Then
								$res = InetClose($hDownload)
								If $res Then
									$hDownload = 0
									_Trace("Téléchargement mis en pause : " & $res & ".")
								Else
									_Trace("Téléchargement mis en pause : " & $res & ". On force l'arrêt.")
									InetClose($hDownload)
									$hDownload = 0
								EndIf
;~ 								FileClose($CheminLogiciels & $sMsg & "_" & $aGet[2] & ".exe")
;~ 								FileSetAttrib($CheminLogiciels & $sMsg & "_" & $aGet[2] & ".exe", "+NT")
								_ProgressSet($prog, _GetDisplaySize($iBytesSize) & " / " & _GetDisplaySize($iFileSize) & "  => " & _GetDisplaySize(0) & "/s")
							EndIf
						EndIf
						If _ProgressGet() <= 0 Then ;Si le progress est annulé on sort du Do.
							$delete = 1
							ExitLoop
						EndIf
					Until InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)
					InetClose($hDownload)
;~ 					_ConsoleWrite("> Téléchargement terminé. Taille en ligne / Taille sur le disque : "&$iFileSize&" / "&FileGetSize($CheminLogiciels & $sMsg & "_" & $aGet[2] & ".exe")&" = "&Round($iFileSize/FileGetSize($CheminLogiciels&$sMsg&"_"&$aGet[2]&".exe"))&"--"&Round(FileGetSize($CheminLogiciels&$sMsg&"_"&$aGet[2]&".exe")/$iFileSize)&"%")
					If $delete = 1 Then
						Do
							FileDelete($CheminLogiciels & $sMsg & "_" & $aGet[2] & ".exe")
						Until Not FileExists($CheminLogiciels & $sMsg & "_" & $aGet[2] & ".exe")
						_Trace("Fichier """ & $CheminLogiciels & $sMsg & "_" & $aGet[2] & ".exe supprimé.")
					Else
						Local $FileSize = FileGetSize($CheminLogiciels & $sMsg & "_" & $aGet[2] & ".exe")
						If $iFileSize > 0 Then
							$recup = Round($iFileSize / $FileSize, 4)
							If $recup >= 1.0000 Then $recup -= 1.0000
							_Trace("Téléchargement terminé : " & $recup)
						EndIf
;~ 						If $recup > 0.5000 And $iFileSize > 0 Or $FileSize < 204800 Then
;~ 							MsgBox($MB_ICONWARNING, Translate("Download error"), Translate("The download has gone wrong.") & @CRLF & _
;~ 									Translate("Online size:") & " " & $iFileSize & " Bytes" & @CRLF & _
;~ 									Translate("Local size:") & " " & $FileSize & " Bytes" & @CRLF & _
;~ 									Translate("Ratio:") & " " & $recup, 15)
;~ 							FileDelete($CheminLogiciels & $sMsg & "_" & $aGet[2] & ".exe")
;~ 						Else
						SQL_Update_If_Different($hBDD, "Logiciels", "Version_Dispo", "Titre_Long = '" & SQL_String(_GUICtrlListView_GetItem($ListView, $i)[3]) & "'", $aGet[2])
						If _GUICtrlListView_GetItem($ListView, $i)[3] = "Skype" Then FileMove($CheminLogiciels & $sMsg & "_" & $aGet[2] & ".exe", $CheminLogiciels & $sMsg & "_" & $aGet[2] & ".msi", $FC_OVERWRITE)
;~ 						EndIf
					EndIf
					_ProgressOff()
				EndIf
			EndIf
;~ 			Sleep(100)
			Afficher_ListView()
;~ 			Sleep(200)
		EndIf
	Next
	If $mb = 0 Then MsgBox($MB_ICONINFORMATION, Translate("Download complete"), Translate("All downloads are completed."), 20)
	If TrayItemGetState($Tray_Survey) = 65 Then
		AdlibRegister("_DownReg", _Time_min2ms($TIME_SURVEY))
		AdlibRegister("_TimeReg", 1000)
		$TimerValue = TimerInit()
	EndIf
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Fin fonction.")
EndFunc   ;==>tbDown

Func tbSearch($mb = 0)
	$FuncName = """tbSearch"""
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Ouverture fonction.")
	If TrayItemGetState($Tray_Survey) = 65 Then
		AdlibUnRegister("_DownReg")
		AdlibUnRegister("_TimeReg")
		GUICtrlSetData($TimeDisplay, "00:00:00")
		If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Désenregistrement de la fonction ""_DownReg"".")
	EndIf
	Local $succes = True
	;Chercher les logiciels présents sur le disque
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Comptage du nombre de softs à surveiller.")
	Local $Dim = _GUICtrlListView_GetItemCount($ListView)
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Il y a " & $Dim & " softs à surveiller.")
	Local $aFileList = _FileListToArray($CheminLogiciels, "*", $FLTA_FILES)
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Récupération de la liste des softs locaux dans une array.")
	If IsArray($aFileList) Then
		If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - On a bien récupéré une array. On peut continuer.")
		Local $file_version
		_ProgressOn(Translate("Local Files"), Translate("Searching for local softwares."), "", "", True, $Main, True)
		If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - On lance un Progress.")
		_ProgressWait(True)
		If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - On met le Progress en mode attente.")
		Sleep(2000)
		_ProgressWait(False)
		If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - On met le Progress en mode progression.")
		_ProgressSet(0, "0 / " & $Dim)
		If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - On initialise le Progress à 0.")
		For $i = 0 To $Dim - 1
			If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Itération n°" & $i & ".")
			If _ProgressGet() = 1 Then
				$sMsg = SQL_Get_Data($hBDD, "Logiciels", "Titre_Court", "Titre_Long = '" & SQL_String(_GUICtrlListView_GetItem($ListView, $i)[3]) & "'")
				If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Le titre court de cette appli est : """ & $sMsg & """.")
				$file_version = ""
				If $sMsg <> "" Then
					For $j = 1 To $aFileList[0]
						If StringInStr($aFileList[$j], $sMsg) Then
							$file_version = StringTrimRight(StringTrimLeft($aFileList[$j], StringLen($sMsg) + 1), 4)
						EndIf
					Next
					SQL_Update_If_Different($hBDD, "Logiciels", "Version_Dispo", "Titre_Long = '" & SQL_String(_GUICtrlListView_GetItem($ListView, $i)[3]) & "'", $file_version)
				EndIf
				$prog = Round(($i + 1 / $Dim) * 100)
				_ProgressSet($prog, $i + 1 & " / " & $Dim)
				If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Fin itération n°" & $i & ".")
			EndIf
			If _ProgressGet() = 2 Then ;Si le progress est en pause on fait en sorte que le for n'avance plus et on met un peu de sleep pour soulager le processeur.
				$i -= 1
				Sleep(10)
			EndIf
			If _ProgressGet() <= 0 Then
				$succes = False
				ExitLoop
			EndIf
		Next
		If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Fin recherche locale.")
		_ProgressOff()
	EndIf
	If $succes = False Then Return
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Début recherche distante.")
	;Chercher les versions disponibles en ligne
	Local $sMsg
	_ProgressOn(Translate("Remote Files"), Translate("Searching for remote files versions."), Translate("Initializing..."), ".\Resources\Images\TUC\TUC.ico", True, $Main, True)
	_ProgressSet(0, "0 / " & $Dim)
	For $i = 0 To $Dim - 1
		If _ProgressGet() = 1 Then
			$sMsg = SQL_Get_Data($hBDD, "Logiciels", "Titre_Court", "Titre_Long = '" & SQL_String(_GUICtrlListView_GetItem($ListView, $i)[3]) & "'")
			If $sMsg <> "" Then
				$aGet = GetAppDetail($sMsg, $API, $Base64_ID)
				If Not IsArray($aGet) Then
					_ProgressOff()
					Return
				EndIf
				SQL_Update_If_Different($hBDD, "Logiciels", "Version_Download", "Titre_Long = '" & SQL_String(_GUICtrlListView_GetItem($ListView, $i)[3]) & "'", $aGet[2])
			EndIf
			$prog = Round(($i / $Dim) * 100)
			_ProgressSet($prog, $i + 1 & " / " & $Dim & " " & Translate("softwares."), _GUICtrlListView_GetItem($ListView, $i)[3])
			_Trace("Téléchargement infos en ligne : " & $i + 1 & " / " & $Dim & " logiciels. | " & _GUICtrlListView_GetItem($ListView, $i)[3])
		EndIf
		If _ProgressGet() = 2 Then ;Si le progress est en pause on fait en sorte que le for n'avance plus et on met un peu de sleep pour soulager le processeur.
			$i -= 1
			Sleep(10)
		EndIf
		If _ProgressGet() <= 0 Then ;Si le progress est annulé on sort du for et on met $mb à 1 pour éviter l'affichage de la MsgBox.
			$mb = 1
			$succes = False
			ExitLoop
		EndIf
	Next
	If $mb = 0 Then Afficher_ListView()
	_ProgressOff()
	If $mb = 0 Then MsgBox($MB_ICONINFORMATION, Translate("Update completed"), Translate("End of remote softwares versions research."), 20)
	If $succes Then
		Return True
	Else
		Return False
	EndIf
	If TrayItemGetState($Tray_Survey) = 65 Then
		AdlibRegister("_DownReg", _Time_min2ms($TIME_SURVEY))
		AdlibRegister("_TimeReg", 1000)
		$TimerValue = TimerInit()
	EndIf
	If $AVEC_DEBUG Then _Trace("{DEBUG} - " & $FuncName & " - Fin fonction.")
EndFunc   ;==>tbSearch

Func tbParam()
	Local $gui_Largeur = 315
	Local $gui_Hauteur = 400
	Local $aCenter[2]
	If $Main <> 0 Then
		$aCenter = _WinGetCenter($Main)
		$aCenter[0] -= $gui_Largeur / 2
		$aCenter[1] -= $gui_Hauteur / 2
	Else
		$aCenter[0] = -1
		$aCenter[1] = -1
	EndIf
	If $Param = 0 Then
		#Region ### START Koda GUI section ###
		;Création de la GUI
		Global $Param = GUICreate(Translate("Parameters"), $gui_Largeur, $gui_Hauteur, $aCenter[0], $aCenter[1])
		GUISetIcon(".\Resources\Images\TUC\TUC.ico")
		GUISetOnEvent($GUI_EVENT_CLOSE, "Param_Close")
		GUISetOnEvent($GUI_EVENT_MINIMIZE, "Param_Minimize")
		GUISetOnEvent($GUI_EVENT_RESTORE, "Param_Restore")
		;Création du gestionnaire d'onglets
		$TabParam = GUICtrlCreateTab(10, 10, $gui_Largeur - 20, $gui_Hauteur - 60)
		;Onglet Options
		Global $TabParam_Updapy = GUICtrlCreateTabItem(Translate("Updapy account"))
		GUICtrlCreateGroup(Translate("User informations"), 20, 35, 270, 75)
		GUICtrlSetFont(-1, 10)
		GUICtrlCreateLabel(Translate("User name:"), 40, 55, 80, 17, $SS_RIGHT)
		Global $iParam_UpdapyUser = GUICtrlCreateInput("", 125, 52, 150, 20)
		GUICtrlCreateLabel(Translate("User password:"), 40, 80, 80, 17, $SS_RIGHT)
		Global $iParam_UpdapyPwd = GUICtrlCreateInput("", 125, 77, 150, 20, $ES_PASSWORD)
		GUICtrlCreateGroup("", -99, -99, 1, 1)
		GUICtrlCreateGroup(Translate("API key"), 20, 115, 270, 50)
		GUICtrlSetFont(-1, 10)
		GUICtrlCreateLabel(Translate("Personal key:"), 40, 137, 80, 17, $SS_RIGHT)
		Global $iParam_UpdapyApi = GUICtrlCreateInput("", 125, 134, 150, 20)
		GUICtrlCreateGroup("", -99, -99, 1, 1)
		;Onglet Paramètres
		Global $TabParam_Options = GUICtrlCreateTabItem(Translate("Options"))
		GUICtrlCreateGroup(Translate("Language"), 20, 35, 270, 50)
		GUICtrlSetFont(-1, 10)
		GUICtrlCreateLabel(Translate("Choose a language:"), 30, 55, 110, 17, $SS_RIGHT)
		Global $cParam_Language = GUICtrlCreateCombo("", 145, 52, 130, 20)
		GUICtrlSetOnEvent(-1, "cParam_Language")
		GUICtrlSetData(-1, _LanguageInitCombo(), "English")
		;Mettre ici la fonction qui va parcourir le dossier de langues pour créer la liste du combo
		GUICtrlCreateGroup("", -99, -99, 1, 1)
		GUICtrlCreateGroup(Translate("Automated downloads"), 20, 90, 270, 50)
		GUICtrlSetFont(-1, 10)
		GUICtrlCreateLabel(Translate("Frequency:"), 30, 110, 110, 17, $SS_RIGHT)
		Global $iParam_CheckFreq = GUICtrlCreateInput("60", 145, 108, 90, 20)
		GUICtrlSetTip(-1, Translate("Write here the time (minutes) you want to wait between 2 searches for updates."))
		GUICtrlCreateLabel(Translate("minutes"), 240, 110, 50, 17)
		GUICtrlCreateGroup("", -99, -99, 1, 1)
		GUICtrlCreateGroup(Translate("GUI position"), 20, 145, 270, 75)
		GUICtrlSetFont(-1, 10)
		Global $rParam_PosMemo = GUICtrlCreateRadio(Translate("Memorize GUI position"), 40, 165, 200, 17)
		Global $rParam_PosNotMemo = GUICtrlCreateRadio(Translate("Do not memorize GUI position"), 40, 190, 200, 17)
		GUICtrlSetState(-1, $GUI_CHECKED)
		GUICtrlCreateGroup("", -99, -99, 1, 1)
		GUICtrlCreateGroup(Translate("Download directory"), 20, 225, 270, 100)
		GUICtrlSetFont(-1, 10)
		GUICtrlCreateLabel(Translate("Current directory:"), 30, 245, 170, 17)
		Global $iParam_DownDir = GUICtrlCreateInput(@MyDocumentsDir & "\TUC_Downloads", 35, 265, 240, 20)
		Global $bParam_DownDir = GUICtrlCreateButton(Translate("Select directory"), 175, 290, 100, 25)
		GUICtrlSetOnEvent(-1, "bParam_DownDir")
		GUICtrlCreateGroup("", -99, -99, 1, 1)
		;Onglet Proxy
		Global $TabParam_Proxy = GUICtrlCreateTabItem(Translate("Proxy"))
		GUICtrlCreateGroup(Translate("Proxy parameters"), 20, 35, 270, 205)
		GUICtrlSetFont(-1, 10)
		Global $rParam_NoProxy = GUICtrlCreateRadio(Translate("No proxy"), 40, 55, 200, 17)
		GUICtrlSetOnEvent(-1, "rParam_NoProxy")
		Global $rParam_SysProxy = GUICtrlCreateRadio(Translate("Use proxy system settings"), 40, 80, 200, 17)
		GUICtrlSetOnEvent(-1, "rParam_SysProxy")
		GUICtrlSetState(-1, $GUI_CHECKED)
		Global $rParam_ManProxy = GUICtrlCreateRadio(Translate("Configure the proxy manually"), 40, 105, 200, 17)
		GUICtrlSetOnEvent(-1, "rParam_ManProxy")
		Global $lParam_ProxyUrl = GUICtrlCreateLabel(Translate("Proxy URL:"), 40, 136, 80, 17, $SS_RIGHT)
		Global $lParam_ProxyPort = GUICtrlCreateLabel(Translate("Connexion port:"), 40, 161, 80, 17, $SS_RIGHT)
		Global $lParam_ProxyUser = GUICtrlCreateLabel(Translate("User name:"), 40, 186, 80, 17, $SS_RIGHT)
		Global $lParam_ProxyPwd = GUICtrlCreateLabel(Translate("User password:"), 40, 211, 80, 17, $SS_RIGHT)
		Global $iParam_ProxyUrl = GUICtrlCreateInput("", 125, 133, 150, 20)
		Global $iParam_ProxyPort = GUICtrlCreateInput("", 125, 158, 150, 20)
		Global $iParam_ProxyUser = GUICtrlCreateInput("", 125, 183, 150, 20)
		Global $iParam_ProxyPwd = GUICtrlCreateInput("", 125, 208, 150, 20, $ES_PASSWORD)
		ProxyManuEnable(False)
		GUICtrlCreateGroup("", -99, -99, 1, 1)
		GUICtrlCreateGroup(Translate("Connexion"), 20, 245, 270, 95)
		GUICtrlSetFont(-1, 10)
		Global $lParam_ProxyStatus = GUICtrlCreateLabel(Translate("Not tested yet"), 40, 270, 235, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE), $WS_EX_CLIENTEDGE)
		GUICtrlSetFont(-1, 9)
		Global $bParam_ProxyCheck = GUICtrlCreateButton(Translate("Test connect"), 175, 300, 100, 25)
		GUICtrlSetOnEvent(-1, "bParam_ProxyCheck")
		GUICtrlCreateGroup("", -99, -99, 1, 1)
		;Onglet Proxy
		$TabParam_Updates = GUICtrlCreateTabItem(Translate("Updates"))
		GUICtrlCreateTabItem("")
		;Boutons
		GUICtrlCreateButton("&" & Translate("Apply"), $gui_Largeur / 2 - 72 / 2 - 75 - 25, $gui_Hauteur - 37, 75, 25)
		GUICtrlSetOnEvent(-1, "bParam_Apply")
		GUICtrlCreateButton("&" & Translate("OK"), $gui_Largeur / 2 - 72 / 2, $gui_Hauteur - 37, 75, 25)
		GUICtrlSetOnEvent(-1, "bParam_OK")
		GUICtrlCreateButton("&" & Translate("Cancel"), $gui_Largeur / 2 + 72 / 2 + 25, $gui_Hauteur - 37, 75, 25)
		GUICtrlSetOnEvent(-1, "bParam_Cancel")
		;Récupérations des paramètres actuels
		Param_Load()
		GUISetState(@SW_SHOW)
		#EndRegion ### END Koda GUI section ###
	Else
		WinMove($Param, "", $aCenter[0], $aCenter[1])
		GUISetState(@SW_SHOW, $Param)
	EndIf
EndFunc   ;==>tbParam

Func Add_btRefresh()
	Local $aGet = GetAppsList($API, $Base64_ID)
	If Not IsArray($aGet) Then
		MsgBox($MB_ICONWARNING, Translate("Online error"), Translate("Something went wrong during the online search.") & @CRLF & Translate("Please check your internet connexion."))
		Return
	EndIf
	Local $aDim = UBound($aGet)
	Local $hDownload = 0
	Local $name = ""
	Local $hQuery, $aRow, $sMsg
	_ProgressOn(Translate("Progress"), Translate("Updating softwares list."), "", "", False, $Add, True)
	_ProgressSet(0, "Démarrage.")
	For $i = 0 To $aDim - 1
		$sMsg = SQL_Get_Data($hBDD, "Logiciels", "Titre_Long", "Titre_Court = '" & SQL_String(String($aGet[$i][1])) & "'")
		$name = String($aGet[$i][1])
		If $sMsg = "" Then _SQLite_Exec($hBDD, "INSERT INTO Logiciels(Titre_Long, Titre_Court) VALUES ('" & SQL_String(String($aGet[$i][0])) & "','" & SQL_String(String($aGet[$i][1])) & "');") ; INSERT Data
		If Not FileExists(".\Resources\Images\Softs\PNG\" & $name & ".png") Then
			_Trace("L'image " & $name & ".png n'existe pas : téléchargement.")
			$hDownload = InetGet("http://www.updapy.com/resources/img/application/small/" & $name & ".png", ".\Resources\Images\Softs\PNG\" & $name & ".png", $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
			Do
				Sleep(10)
			Until InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)
			InetClose($hDownload)
		EndIf
		If Not FileExists(".\Resources\Images\Softs\BMP\" & $name & ".bmp") Then
			If FileExists(".\Resources\Images\Softs\PNG\" & $name & ".png") Then
				_Trace("L'image " & $name & ".bmp n'existe pas : conversion.")
				_GUIImageList_Convert(".\Resources\Images\Softs\PNG\" & $name & ".png")
			Else
				_Trace("L'image " & $name & ".bmp n'existe pas : conversion impossible car source introuvable.")
			EndIf
		EndIf
		_ProgressSet(Round(($i / $aDim) * 100), Translate("Software N°") & $i + 1 & "/" & $aDim & ".")
	Next
	_ProgressSet(100, Translate("End."))
	Afficher_Add_List()
	_ProgressOff()
EndFunc   ;==>Add_btRefresh

Func Add_btOK()
	Local $value = ""
	Local $Dim = _GUICtrlListView_GetItemCount($Add_List)
	For $i = 0 To $Dim - 1
		If _GUICtrlListView_GetItemChecked($Add_List, $i) Then
			$value = "OUI"
		Else
			$value = "NON"
		EndIf
		SQL_Update_If_Different($hBDD, "Logiciels", "Selection", "Titre_Long = '" & SQL_String(_GUICtrlListView_GetItem($Add_List, $i)[3]) & "'", $value)
	Next
	GUISetState(@SW_HIDE, $Add)
	Afficher_ListView()
EndFunc   ;==>Add_btOK

Func Add_btCancel()
	AddClose()
EndFunc   ;==>Add_btCancel

Func AddClose()
	GUISetState(@SW_HIDE, $Add)
;~ 	GUIDelete($Add)
;~ 	$Add = 0
EndFunc   ;==>AddClose

Func About_OK()
	About_Close()
EndFunc   ;==>About_OK

Func About_Close()
	GUISetState(@SW_HIDE, $About_GUI)
EndFunc   ;==>About_Close

Func bParam_ProxyCheck()
	Check_Internet_Status()
EndFunc   ;==>bParam_ProxyCheck

Func cParam_Language()
	; ne rien faire : les actions nécessaires seront effectuées lors du clic sur "appliquer" ou "ok"
EndFunc   ;==>cParam_Language

Func bParam_DownDir()
	Local $sFolder = FileSelectFolder(Translate("Please select a destination folder."), GUICtrlRead($iParam_DownDir), 0, "", $Param)
	If $sFolder <> "" Then GUICtrlSetData($iParam_DownDir, $sFolder)
EndFunc   ;==>bParam_DownDir

Func rParam_NoProxy()
	SetProxy(1)
	ProxyManuEnable(False)
EndFunc   ;==>rParam_NoProxy

Func rParam_SysProxy()
	SetProxy(0)
	ProxyManuEnable(False)
EndFunc   ;==>rParam_SysProxy

Func rParam_ManProxy()
	SetProxy(2)
	ProxyManuEnable(True)
EndFunc   ;==>rParam_ManProxy

Func bParam_Cancel()
	If $First = True Then Exit
	Param_Close()
EndFunc   ;==>bParam_Cancel

Func bParam_OK()
	If Param_Save() Then
		Param_Close()
		If $First = True Then tbAdd()
	EndIf
EndFunc   ;==>bParam_OK

Func bParam_Apply()
	Param_Save()
EndFunc   ;==>bParam_Apply

Func Param_Close()
	If GUICtrlRead($iParam_UpdapyUser) <> "" And GUICtrlRead($iParam_UpdapyPwd) <> "" And GUICtrlRead($iParam_UpdapyApi) <> "" Then
		GUISetState(@SW_HIDE, $Param)
		GUISetState(@SW_SHOW, $Main)
	Else
		If MsgBox(BitOR($MB_OKCANCEL, $MB_ICONINFORMATION), Translate("Incorrect settings"), Translate("Please fill up at least the Updapy settings !")) = $IDCANCEL Then Exit
		GUICtrlSetState($TabParam_Updapy, $GUI_SHOW)
	EndIf
EndFunc   ;==>Param_Close

Func Param_Minimize()

EndFunc   ;==>Param_Minimize

Func Param_Restore()

EndFunc   ;==>Param_Restore
