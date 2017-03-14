ScriptName Copypasta_v2:CopypastaHelperScript extends ObjectReference

Keyword Property Copypasta_HelperLink Auto Mandatory
float Property SelfGrabMenuTimeout = 2.0 Auto

Keyword Property WorkshopStackedItemParentKeyword Auto Mandatory

int SelfGrabMenuTimoutTimerID = 17

Function ShowMenu()
	Copypasta_v2:CopypastaScript copypastaRef = GetCopypasta()
	If (copypastaRef)
		copypastaRef.ShowMenu()
	EndIf
EndFunction

Copypasta_v2:CopypastaScript Function GetCopypasta()
	ObjectReference[] copypastaLink = GetRefsLinkedToMe(Copypasta_HelperLink)
	If (copypastaLink.Length > 0)
		copypastaLink[0].MoveTo(self, afZOffset = -56.0)
		copypastaLink[0].Disable()
		copypastaLink[0].Enable()
		return copypastaLink[0] as Copypasta_v2:CopypastaScript
	Else
		return None
	EndIf
EndFunction
	
Event OnWorkshopObjectDestroyed(ObjectReference akReference)
	Copypasta_v2:CopypastaScript copypastaRef = GetCopypasta()
	If (copypastaRef)
		Self.Enable()
		Self.SetLinkedRef(copypastaRef, WorkshopStackedItemParentKeyword)
		ShowMenu()
	EndIf
	selfGrabbed = false
	CancelTimer(SelfGrabMenuTimoutTimerID)
EndEvent

bool selfGrabbed

Event OnWorkshopObjectGrabbed(ObjectReference akReference)
	selfGrabbed = true
	StartTimer(SelfGrabMenuTimeout, SelfGrabMenuTimoutTimerID)
EndEvent

Event OnWorkshopObjectMoved(ObjectReference akReference)
	CancelTimer(SelfGrabMenuTimoutTimerID)
	If (selfGrabbed)
		ShowMenu()
	EndIf
	selfGrabbed = false
EndEvent

Event OnTimer(int aiTimerID)
	If (aiTimerID == SelfGrabMenuTimoutTimerID)
		selfGrabbed = false
	EndIf
EndEvent