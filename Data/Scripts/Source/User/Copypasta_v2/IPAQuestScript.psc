ScriptName Copypasta_v2:IPAQuestScript extends Quest Conditional

WorkshopParentScript Property WorkshopParent Auto Const
Form Property Verifier Auto Const

Int CurrentFormID = 0 Conditional
;string selection = ""

Event ObjectReference.OnWorkshopObjectPlaced(ObjectReference akSender, ObjectReference akReference)
	GoToState("Inactive")
EndEvent

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
	If (asMenuName == "WorkshopMenu" && !abOpening)
		GotoState("Inactive")
	ElseIf (asMenuName == "PauseMenu" && abOpening)
		MakeCurrentObjectPA()
	EndIf
EndEvent


Auto State Inactive

EndState

State Active
	Event OnBeginState(string asOldState)
		RegisterForMenuOpenCloseEvent("WorkshopMenu")
		RegisterForMenuOpenCloseEvent("PauseMenu")
		RegisterForRemoteEvent(WorkshopParent.CurrentWorkshop.GetRef(), "OnWorkshopObjectPlaced") 
	EndEvent

	Event OnEndState(string asNewState)
		CurrentFormID = 0
		UnregisterForAllEvents()
	EndEvent
EndState

; string Function IntToHex(int num)
;     string[] HexDigits = new string[16]
;     HexDigits[0] = "0"
;     HexDigits[1] = "1"
;     HexDigits[2] = "2"
;     HexDigits[3] = "3"
;     HexDigits[4] = "4"
;     HexDigits[5] = "5"
;     HexDigits[6] = "6"
;     HexDigits[7] = "7"
;     HexDigits[8] = "8"
;     HexDigits[9] = "9"
;     HexDigits[10] = "A"
;     HexDigits[11] = "B"
;     HexDigits[12] = "C"
;     HexDigits[13] = "D"
;     HexDigits[14] = "E"
;     HexDigits[15] = "F"
    
;     string result = ""
;     bool neg = false
;     If (num < 0)
; 	    num += 268435456
; 	    neg = true
;     EndIf
;     int remainder
;     While (num > 0)
;         remainder = num % 16
;         result = HexDigits[remainder] + result
;         num /= 16
;     EndWhile
;     If (neg)
; 	    result = "F" + result
;     EndIf
;     return result
; EndFunction

Function ActivatePA(ObjectReference akRef)
	CurrentFormID = akRef.GetFormID()
;	selection = IntToHex(CurrentFormID)
	GoToState("Active")
EndFunction

Function MakeCurrentObjectPA()
	If (CurrentFormID != 0)
		Form curForm = Game.GetForm(CurrentFormID)
		If (curForm is ObjectReference)
			ObjectReference curRef = curForm as ObjectReference
			If (curRef.GetBaseObject().GetFormID() == Verifier.GetFormID())
				curRef.SetScale(2.0)
				curRef.Disable()
				curRef.SetScale(1.0)
				Utility.Wait(0.1)
				curRef.Enable()
			Else
				ObjectReference copy = curRef.PlaceAtMe(curRef.GetBaseObject(), 1, false, true, false)
				copy.MoveTo(curRef)
				copy.Enable()
				; TODO : make build event be properly sent
				ObjectReference workshop = WorkshopParent.CurrentWorkshop.GetRef()
				copy.SetLinkedRef(workshop, WorkshopParent.WorkshopItemKeyword)
				workshop.OnWorkshopObjectPlaced(copy)
			EndIf
		EndIf
	EndIf
EndFunction
