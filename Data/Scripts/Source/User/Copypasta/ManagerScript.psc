ScriptName Copypasta:ManagerScript extends Quest

WorkshopParentScript Property WorkshopParent Auto Const

Event OnQuestInit()
        RegisterForMenuOpenCloseEvent("WorkshopMenu")
EndEvent

Event ObjectReference.OnWorkshopObjectPlaced(ObjectReference akWorkshopRef, ObjectReference akRef)
        UpdateIPA(akRef)
EndEvent

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
        If (asMenuName == "WorkshopMenu")
                HandleWorkshopMenu(abOpening)
        ElseIf (asMenuName == "PauseMenu")
                HandlePauseMenu(abOpening)
        EndIf
EndEvent


ObjectReference workshopRef
Function HandleWorkshopMenu(bool abOpening)
        If (abOpening)
                ; Save the ref to be able to refer back to it when unregistering
                workshopRef = WorkshopParent.CurrentWorkshop.GetRef()
                RegisterForRemoteEvent(workshopRef, "OnWorkshopObjectPlaced")
		RegisterForMenuOpenCloseEvent("PauseMenu")
        Else
                UnregisterForRemoteEvent(workshopRef, "OnWorkshopObjectPlaced")
		UnregisterForMenuOpenCloseEvent("PauseMenu")
        EndIf
EndFunction

int IPA_PLACE_TIMEOUT_ID = 1 Const
bool ipa_place_timeout_expired = true
Function HandlePauseMenu(bool abOpening)
        If (abOpening)
                ; should only be here if in workshop mode
                ; start pause enabled timer
                StartPauseTimer(1.0, IPA_PLACE_TIMEOUT_ID)
                ipa_place_timeout_expired = false
        Else
                If (!ipa_place_timeout_expired)
                        CancelPauseTimer(IPA_PLACE_TIMEOUT_ID)
                        PlaceIPA()
                EndIf
        EndIf
EndFunction

int ipa_id = 0
Function UpdateIPA(ObjectReference akRef)
        Utility.Wait(0.1)
        ObjectReference[] result = akRef.FindAllReferencesOfType(akRef.GetBaseObject(), 50.0)
        int i = 0
        bool successful = false
        While (i < result.length)
                If (result[i] != akRef)
                        ObjectReference tmp = result[i]
                        int id = tmp.GetFormID()
                        ; not 100% conclusive, but probably good enough
                        If (id >= 0xff000000 && tmp.GetLinkedRef(WorkshopParent.WorkshopItemKeyword) == None)
                                ipa_id = id
                                UpdateDebugStuff()
                                successful = true
                                i = result.length ; 'break'
                        EndIf
                EndIf
                i += 1
        EndWhile
        If (!successful)
                ipa_id = 0
                UpdateDebugStuff()
                Debug.Notification("[IPA] Unable to find target")
        EndIf
EndFunction

Function PlaceIPA()
        bool successful = false
        If (ipa_id != 0)
                ObjectReference ipaRef = Game.GetForm(ipa_id) as ObjectReference
                If (ipaRef)
                        ObjectReference copy = ipaRef.PlaceAtMe(ipaRef.GetBaseObject(), 1, false, true, false)
                        If (copy)
                                SetupAsIfWorkshopPlaced(copy)
                                copy.Enable()
                                successful = true
                        EndIf
                EndIf
        EndIf
        If (!successful)
                ipa_id = 0
                UpdateDebugStuff()
                Debug.Notification("[IPA] Unable to place")
        EndIf
EndFunction

Function SetupAsIfWorkshopPlaced(ObjectReference akRef)
        ; @FIX this doesn't work animated/powered objects(?); ex. WorkshopGenerator
        akRef.SetLinkedRef(workshopRef, WorkshopParent.WorkshopItemKeyword)
        akRef.OnWorkshopObjectPlaced(workshopRef)
        workshopRef.OnWorkshopObjectPlaced(akRef)
EndFunction

; ### Timer related stuff ###

Event OnTimer(int aiTimerID)
        If (aiTimerID == IPA_PLACE_TIMEOUT_ID)
                ipa_place_timeout_expired = true
        EndIf
EndEvent

int[] activeTimers
Function WaitTimer(float afInterval, int aiTimerID)
	Utility.WaitMenuMode(afInterval)
	int i = activeTimers.Find(aiTimerID)
	If (i >= 0)
		activeTimers.Remove(i)
                ; only send the event if it hasn't been restarted
                If (activeTimers.Find(aiTimerID) < 0)
		        OnTimer(aiTimerID)
                EndIf
	EndIf
EndFunction

Function StartPauseTimer(float afInterval, int aiTimerID = 0)
	If (activeTimers == None)
		activeTimers = new int[0]
	EndIf
	activeTimers.Add(aiTimerID)
	var[] params = new var[2]
	params[0] = afInterval as float
	params[1] = aiTimerID as int
	CallFunctionNoWait("WaitTimer", params)
EndFunction

Function CancelPauseTimer(int aiTimerID = 0)
	int i = activeTimers.Find(aiTimerID)
	If (i >= 0)
		activeTimers.Remove(i)
	EndIf
EndFunction


; ### Debug stuff ###

string zDebug_ipa_id
Function UpdateDebugStuff() debugonly
        zDebug_ipa_id = IntToHex(ipa_id)
EndFunction

; modified, from author reg2k
string Function IntToHex(int num) debugonly
        string[] HexDigits = new string[16]
        HexDigits[0] = "0"
        HexDigits[1] = "1"
        HexDigits[2] = "2"
        HexDigits[3] = "3"
        HexDigits[4] = "4"
        HexDigits[5] = "5"
        HexDigits[6] = "6"
        HexDigits[7] = "7"
        HexDigits[8] = "8"
        HexDigits[9] = "9"
        HexDigits[10] = "a"
        HexDigits[11] = "b"
        HexDigits[12] = "c"
        HexDigits[13] = "d"
        HexDigits[14] = "e"
        HexDigits[15] = "f"

        string result = ""
        bool neg = false
        int pad_len = 8
        If (num < 0)
	        num += 0x10000000
	        neg = true
                pad_len -= 1
        EndIf
        int remainder
        While (num > 0)
                remainder = num % 16
                result = HexDigits[remainder] + result
                num /= 16
                pad_len -= 1
        EndWhile
        While (pad_len > 0)
                result = "0" + result
                pad_len -= 1
        EndWhile
        If (neg)
	        result = "f" + result
        EndIf
        return "(" + result + ")"
EndFunction
