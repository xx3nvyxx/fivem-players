#Requires AutoHotkey v2.0
#Include <Jxon>

IPs := []
Favorites := []
Stream := Map()
players := {}
Characters := Map()
IDs := []
LoadVariables()


MainGui := Gui()
GuiFavorites := MainGui.Add("ListView", "Sort x10 r10 w800", ["id", "name", "stream", "main character(s)", "discord", "steam"])
GuiFavorites.ModifyCol(1, "Integer")
GuiFavorites.OnEvent("DoubleClick", UpdateStream)
GuiFavorites.OnEvent("ContextMenu", ActiveList_ContextMenu)

GuiUp := MainGui.Add("Button", "x380 y210", "↑")
GuiUp.OnEvent("Click", AddFavorite)


GuiDown := MainGui.Add("Button", "x400 y210", "↓")
GuiDown.OnEvent("Click", RemoveFavorite)

GuiRefresh := MainGui.Add("Button", "x780 y210", "🗘")
GuiRefresh.OnEvent("Click", DataRefresh)

GuiPlayers := MainGui.Add("ListView", "Sort x10 r20 w800", ["id", "name", "stream", "main character(s)", "discord", "steam"])
GuiPlayers.ModifyCol(1, "Integer")
GuiPlayers.OnEvent("DoubleClick", UpdateStream)
GuiPlayers.OnEvent("ContextMenu", ActiveList_ContextMenu)

GuiMenu := Menu()
StreamMenu := Menu()
CharacterMenu := Menu()
DiscordMenu := Menu()
SteamMenu := Menu()

MainGui.Show()

Tray := A_TrayMenu
Tray.Delete()
Tray.Add("&Show", ShowWindow)
Tray.Add()
Tray.AddStandard()
Tray.Default := "&Show"

DataRefresh()

Return

DataRefresh(*)
{
	GuiRefresh.Opt("+Disabled")
	whr := ComObject("WinHttp.WinHttpRequest.5.1")
	i := random(1, IPs.Length)
	whr.Open("GET", "http://" . IPs[i] . ":30120/players.json", true)
	whr.Send()
	; Using 'true' above and the call below allows the script to remain responsive.
	try
	{
		whr.WaitForResponse()
		response := whr.ResponseText
	}
	catch
	{
		Error := "response timeout"
		GuiRefresh.Opt("-Disabled")
		Return
	}
	if StrLen(response) < 10
	{
		GuiRefresh.Opt("-Disabled")
		return
	}
	CurrentIDs := Array()
	Loop GuiFavorites.GetCount()
	{
		RowID := GuiFavorites.GetText(A_Index, 1)
		CurrentIDs.Push(RowID)
	}
	Loop GuiPlayers.GetCount()
	{
		RowID := GuiPlayers.GetText(A_Index, 1)
		CurrentIDs.Push(RowID)
	}
	players := jxon_load(&response)
	Loop players.Length
	{
		player := players.Pop()
		identifiers := player.Get("identifiers")
		discord := ""
		steam := ""
		Loop identifiers.Length
		{
			identifier := identifiers.Pop()
			if SubStr(identifier, 1, 1) = "s"
				steam := SubStr(identifier, 7)
			if SubStr(identifier, 1, 1) = "d"
				discord := SubStr(identifier, 9)
		}
		t := Stream.Get(player.Get("name"), "")
		pStream := t = "*" ? player.Get("name") : t
		pCharacter := Characters.Get(player.Get("name"), "")
		cIDindex := HasVal(CurrentIDs, player.Get("id"))
		if cIDindex
			CurrentIDs.RemoveAt(cIDindex)
		else
		{
			if HasVal(Favorites, player.Get("name"))
				GuiFavorites.Add(, player.Get("id"), player.Get("name"), pStream, pCharacter, discord, steam)
			else
				GuiPlayers.Add(, player.Get("id"), player.Get("name"), pStream, pCharacter, discord, steam)
		}
	}
	GuiFavorites.ModifyCol
	GuiFavorites.ModifyCol(1, "Sort")
	GuiPlayers.ModifyCol
	GuiPlayers.ModifyCol(1, "Sort")
	FavoritesCount := GuiFavorites.GetCount()
	Loop FavoritesCount
	{
		RowID := GuiFavorites.GetText((FavoritesCount - (A_Index - 1)), 1)
		cIDindex := HasVal(CurrentIDs, RowID)
		if cIDindex > 0
		{
			CurrentIDs.RemoveAt(cIDindex)
			GuiFavorites.Delete((FavoritesCount - (A_Index - 1)))
		}
		else
		{
			pName := GuiFavorites.GetText((FavoritesCount - (A_Index -1)), 2)
			tVal := Stream.Get(pName, "")
			tName := tVal = "*" ? pName : tVal
			if tName != "" && SubStr(tName, 1, 3) != "yt:"
			{
				tPage := ComObject("WinHttp.WinHttpRequest.5.1")
				tPage.Open("POST", "https://gql.twitch.tv/gql", true)
				tPage.SetRequestHeader("client-id", "kimne78kx3ncx6brgo4mv6wki5h1ko")
				tPage.Send("{`"query`": `"query {user(login: \`"" . tName . "\`") {stream {id}}}`", `"variables`": {}}")
				try
				{
					tPage.WaitForResponse()
					tResponse := tPage.ResponseText
				}
				catch
				{
					tError := "response timeout"
				}

				If InStr(tResponse, "null")
					GuiFavorites.Modify((FavoritesCount - (A_Index -1)), "Col3", tName)
				else
					GuiFavorites.Modify((FavoritesCount - (A_Index -1)), "Col3", "🔴 " . tName)
			}
		}
	}
	PlayersCount := GuiPlayers.GetCount()
	Loop PlayersCount
	{
		RowID := GuiPlayers.GetText((PlayersCount - (A_Index - 1)), 1)
		cIDindex := HasVal(CurrentIDs, RowID)
		if cIDindex > 0
		{
			CurrentIDs.RemoveAt(cIDindex)
			GuiPlayers.Delete((PlayersCount - (A_Index - 1)))
		}
		else
		{
			pName := GuiPlayers.GetText((PlayersCount - (A_Index -1)), 2)
			tVal := Stream.Get(pName, "")
			tName := tVal = "*" ? pName : tVal
			if tName != "" && SubStr(tName, 1, 3) != "yt:"
			{
				tPage := ComObject("WinHttp.WinHttpRequest.5.1")
				tPage.Open("POST", "https://gql.twitch.tv/gql", true)
				tPage.SetRequestHeader("client-id", "kimne78kx3ncx6brgo4mv6wki5h1ko")
				tPage.Send("{`"query`": `"query {user(login: \`"" . tName . "\`") {stream {id}}}`", `"variables`": {}}")
				try
				{
					tPage.WaitForResponse()
					tResponse := tPage.ResponseText
				}
				catch
				{
					tError := "response timeout"
				}
				If InStr(tResponse, "null")
					GuiPlayers.Modify((PlayersCount - (A_Index -1)), "Col3", tName)
				else
					GuiPlayers.Modify((PlayersCount - (A_Index -1)), "Col3", "🔴 " . tName)
			}
		}
	}
	GuiRefresh.Opt("-Disabled")
}

AddFavorite(*)
{
	RowNumber := GuiPlayers.GetNext()
	if RowNumber = 0
		Return
	pId := GuiPlayers.GetText(RowNumber, 1)
	pName := GuiPlayers.GetText(RowNumber, 2)
	pStream := GuiPlayers.GetText(RowNumber, 3)
	pCharacter := GuiPlayers.GetText(RowNumber, 4)
	pDiscord := GuiPlayers.GetText(RowNumber, 5)
	pSteam := GuiPlayers.GetText(RowNumber, 6)
	Favorites.Push(pName)
	GuiPlayers.Delete(RowNumber)
	GuiFavorites.Add(, pID, pName, pStream, pCharacter, pDiscord, pSteam)
	SaveVariables()
}

RemoveFavorite(*)
{
	RowNumber := GuiFavorites.GetNext()
	if RowNumber = 0
		Return
	pId := GuiFavorites.GetText(RowNumber, 1)
	pName := GuiFavorites.GetText(RowNumber, 2)
	pStream := GuiFavorites.GetText(RowNumber, 3)
	pCharacter := GuiFavorites.GetText(RowNumber, 4)
	pDiscord := GuiFavorites.GetText(RowNumber, 5)
	pSteam := GuiFavorites.GetText(RowNumber, 6)
	For Index, Value in Favorites
	{
		If Value = pName
		{
			Favorites.RemoveAt(Index)
			break
		}
	}
	GuiFavorites.Delete(RowNumber)
	GuiPlayers.Add(, pID, pName, pStream, pCharacter, pDiscord, pSteam)
	SaveVariables()
}

CopyStream(ActiveList, RowNumber, *)
{
	ActiveRowName := ActiveList.GetText(RowNumber, 2)
	ActiveRowStream := ActiveList.GetText(RowNumber, 3)
	if SubStr(ActiveRowStream, 1, 3) == "🔴 "
		 ActiveRowStream := SubStr(ActiveRowStream, 4)
	A_Clipboard := ActiveRowStream ? ActiveRowStream : ActiveRowName
}

UpdateStream(ActiveList, RowNumber, *)
{
	ActiveRowName := ActiveList.GetText(RowNumber, 2)
	ActiveRowStream := ActiveList.GetText(RowNumber, 3)
	if SubStr(ActiveRowStream, 1, 3) == "🔴 "
		 ActiveRowStream := SubStr(ActiveRowStream, 4)
	prefill := ActiveRowStream ? ActiveRowStream : ActiveRowName
	x := 0
	y := 0
	MainGui.GetPos(&x, &y)
	x += 200
	y += 250
	MainGui.Opt("+OwnDialogs")
	NewStream := InputBox("Enter a new Stream id for " . ActiveRowName, "Stream Name", "X" . x . " Y" . y , prefill)
	if NewStream.Result = "Cancel"
		Return
	Stream[ActiveRowName] := NewStream.Value = ActiveRowName ? "*" : NewStream.Value
	ActiveList.Modify(RowNumber, "Col3", NewStream.Value)
	ActiveList.ModifyCol
	SaveVariables()
}

WatchStream(ActiveList, RowNumber, *)
{
	ActiveRowName := ActiveList.GetText(RowNumber, 2)
	ActiveRowStream := ActiveList.GetText(RowNumber, 3)
	if SubStr(ActiveRowStream, 1, 3) == "🔴 "
		 ActiveRowStream := SubStr(ActiveRowStream, 4)
	url := "https://twitch.tv/" . (ActiveRowStream ? ActiveRowStream : ActiveRowName)
	Run url
}

CopyCharacter(ActiveList, RowNumber, *)
{
	ActiveRowName := ActiveList.GetText(RowNumber, 2)
	ActiveRowCharacter := ActiveList.GetText(RowNumber, 4)
	A_Clipboard := ActiveRowCharacter ? ActiveRowCharacter : ""
}

UpdateCharacter(ActiveList, RowNumber, *)
{
	ActiveRowName := ActiveList.GetText(RowNumber, 2)
	ActiveRowCharacter := ActiveList.GetText(RowNumber, 4)
	prefill := ActiveRowCharacter ? ActiveRowCharacter : ""
	x := 0
	y := 0
	MainGui.GetPos(&x, &y)
	x += 200
	y += 250
	MainGui.Opt("+OwnDialogs")
	NewCharacter := InputBox("Enter a new main character for " . ActiveRowName, "Character Name", "X" . x . " Y" . y , prefill)
	if NewCharacter.Result = "Cancel"
		Return
	Characters[ActiveRowName] := NewCharacter.Value
	ActiveList.Modify(RowNumber, "Col4", NewCharacter.Value)
	ActiveList.ModifyCol
	SaveVariables()
}

CopyDiscord(ActiveList, RowNumber, *)
{
	ActiveRowName := ActiveList.GetText(RowNumber, 2)
	ActiveRowDiscord := ActiveList.GetText(RowNumber, 5)
	A_Clipboard := ActiveRowDiscord ? ActiveRowDiscord : ""
}

CopySteam(ActiveList, RowNumber, *)
{
	ActiveRowName := ActiveList.GetText(RowNumber, 2)
	ActiveRowSteam := ActiveList.GetText(RowNumber, 6)
	A_Clipboard := ActiveRowSteam ? ActiveRowSteam : ""
}

ActiveList_ContextMenu(ActiveList, RowNumber, IsRightClick, X, Y)
{
	StreamMenu.Add("Copy", CopyStream.Bind(ActiveList, RowNumber))
	StreamMenu.Add("Update", UpdateStream.Bind(ActiveList, RowNumber))
	StreamMenu.Add("Watch", WatchStream.Bind(ActiveList, RowNumber))
	ActiveRowStream := ActiveList.GetText(RowNumber, 3)
	if SubStr(ActiveRowStream, 1, 3) != "🔴 "
		StreamMenu.Delete("Watch")
	GuiMenu.Add("Stream", StreamMenu)
	CharacterMenu.Add("Copy", CopyCharacter.Bind(ActiveList, RowNumber))
	CharacterMenu.Add("Update", UpdateCharacter.Bind(ActiveList, RowNumber))
	GuiMenu.Add("Character", CharacterMenu)
	DiscordMenu.Add("Copy", CopyDiscord.Bind(ActiveList, RowNumber))
	GuiMenu.Add("Discord", DiscordMenu)
	SteamMenu.Add("Copy", CopySteam.Bind(ActiveList, RowNumber))
	GuiMenu.Add("Steam", SteamMenu)
	GuiMenu.Show()
}

HasVal(haystack, needle)
{
	if !(IsObject(haystack)) || (haystack.Length = 0)
		return 0
	for index, value in haystack
		if (value = needle)
			return index
	return 0
}

ClearList(ListToClear)
{
    Loop ListToClear.GetCount()
    {
        ListToClear.Delete(1)
    }
}

SaveVariables()
{
	IPsJson := jxon_dump(IPs)
	FavoritesJson := jxon_dump(Favorites)
	StreamJson := jxon_dump(Stream)
	CharactersJson := jxon_dump(Characters)
	IniWrite IPsJson, "settings.ini", "state", "IPs" 
	IniWrite FavoritesJson, "settings.ini", "state", "Favorites" 
	IniWrite StreamJson, "settings.ini", "state", "Stream" 
	IniWrite CharactersJson, "settings.ini", "state", "Characters"
}

LoadVariables()
{
	if FileExist("settings.ini")
	{
		IPsJson := IniRead("settings.ini", "state", "IPs")
		global IPs := jxon_load(&IPsJson)
		FavoritesJson := IniRead("settings.ini", "state", "Favorites")
		global Favorites := jxon_load(&FavoritesJson)
		StreamJson := IniRead("settings.ini", "state", "Stream")
		global Stream := jxon_load(&StreamJson)
		CharactersJson := IniRead("settings.ini", "state", "Characters")
		global Characters := jxon_load(&CharactersJson)
	}
	else
	{
		ip := InputBox("Enter the ip address of a FiveM server ex. 127.0.0.1", "FiveM server")
		if ip.Result = "Cancel"
			ExitApp
		octets := 0
		Loop Parse, ip.Value, "."
			if IsNumber(A_LoopField) && A_LoopField >= 0 && A_LoopField <= 255
				octets++
			else
			{
				MsgBox("Error: Invalid IP address")
				ExitApp
			}
		if octets != 4
		{
			MsgBox("Error: Invalid IP address")
			ExitApp
		}
		IPs.Push(ip.Value)
		IPsJson := jxon_dump(IPs)
		IniWrite IPsJson, "settings.ini", "state", "IPs"
	}
}

ShowWindow(*)
{
	MainGui.Show()
}
