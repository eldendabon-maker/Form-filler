#Requires AutoHotkey v2.0
#SingleInstance Force

; ===== YOUR FIXED DETAILS (edit these) =====
profile := Map(
    "First name", "fn",
    "Last name",  "ln",
    "Phone",      "00",
    "Email",      "df",
    "Address",    "sd"
)

for label, value in profile {
    if Trim(value) = "" {
        MsgBox label " is empty in the script. Fix it and run again."
        ExitApp
    }
}

; ===== LOAD SITES (column 1 = url, column 2 = message) =====
dataFile := A_ScriptDir "\answers.tsv"
if !FileExist(dataFile) {
    MsgBox "answers.tsv not found in " A_ScriptDir
    ExitApp
}

sites := []
isHeader := true
for line in StrSplit(FileRead(dataFile, "UTF-8"), "`n", "`r") {
    if isHeader {
        isHeader := false
        continue
    }
    if Trim(line) = ""
        continue
    cells := StrSplit(line, "`t")
    msg := cells.Length >= 2 ? StrReplace(Trim(cells[2]), "[BR]", "`r`n") : ""
    sites.Push(Map("url", Trim(cells[1]), "msg", msg))
}
if sites.Length = 0 {
    MsgBox "No sites found in answers.tsv (only the header row?)."
    ExitApp
}

idx := 1
fillMode := false

ShowTip(text) {
    ToolTip text
    SetTimer () => ToolTip(), -2500
}

PasteText(value, label) {
    if Trim(value) = "" {
        MsgBox label " is EMPTY. Nothing was pasted.", "Empty value", 48
        return
    }
    saved := ClipboardAll()
    A_Clipboard := value
    if !ClipWait(1) {
        MsgBox "Clipboard did not update. Nothing was pasted."
        return
    }
    Send "^v"
    Sleep 150
    A_Clipboard := saved
    shown := StrLen(value) > 50 ? SubStr(value, 1, 50) "..." : value
    ShowTip(label ": " shown)
}

OpenSite() {
    url := sites[idx]["url"]
    if !RegExMatch(url, "i)^https?://")
        url := "https://" url
    Run url
    ShowTip("Site " idx " of " sites.Length ": " sites[idx]["url"])
}

MoveSite(step) {
    global idx
    newIdx := idx + step
    if newIdx < 1 {
        ShowTip("Already at the first site.")
        return
    }
    if newIdx > sites.Length {
        ShowTip("No more sites.")
        return
    }
    idx := newIdx
    OpenSite()
}

; ===== TOGGLE =====
F8:: {
    global fillMode
    fillMode := !fillMode
    ShowTip(fillMode ? "FILL MODE ON (number keys paste)" : "FILL MODE OFF (numbers type normally)")
}

; ===== NUMBER KEYS (only active in fill mode) =====
#HotIf fillMode
1:: PasteText(profile["First name"], "First name")
2:: PasteText(profile["Last name"],  "Last name")
3:: PasteText(profile["Phone"],      "Phone")
4:: PasteText(profile["Email"],      "Email")
5:: PasteText(profile["Address"],    "Address")
6:: PasteText(sites[idx]["msg"], "Message (site " idx ")")

7:: MoveSite(-1)                        ; previous site
8:: MoveSite(1)                         ; next site

9:: ShowTip("Site " idx " of " sites.Length ": " sites[idx]["url"])   ; show current site only

0:: OpenSite()                          ; reopen the current site

-:: {                                   ; jump to a site number
    global idx
    ib := InputBox("Go to site number (1-" sites.Length "):", "Jump to site")
    if ib.Result != "OK"
        return
    n := Trim(ib.Value)
    if !IsInteger(n) || n < 1 || n > sites.Length {
        MsgBox "Enter a number from 1 to " sites.Length "."
        return
    }
    idx := Integer(n)
    OpenSite()
}
#HotIf