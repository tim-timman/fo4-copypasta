ScriptName Copypasta_v2:ImmediatePAScript extends ObjectReference
; reloadscript "Copypasta_v2:ImmediatePAScript"

Form Property Copypasta_Highlighter Auto
Form Property Copypasta_Helper Auto
Form Property Copypasta_Carrier Auto
FormList Property Copypasta_IPACannotSelectList Auto
Keyword Property Copypasta_SearchKeyword Auto
Keyword Property Copypasta_GroupSelectionLink Auto
Keyword Property WorkshopItemKeyword Auto
Keyword Property WorkshopStackedItemParentKEYWORD Auto

Message Property Copypasta_MSG_SelectionGrabbed Auto

Float Property WaitForPADuration = 0.3 Auto
Float Property HighlightAllowSpawnDuration = 1.5 Auto
Float Property HighlightPersistDuration = 2.5 Auto
Float Property SimulatedGroupSelectFactor = 2.5 Auto

Int HighlightSpawnTimerID = 22
Int HighlightPersistTimerID = 33
Int PATimerID = 44

bool shouldPA = false
bool shouldSpawnHighlight = false
bool highlightGrabbed = false
bool unselectableGrabbed = false

Struct PAS
	float X
	float Y
	float Z
	float aX
	float aY
	float aZ
	;float scale
	ObjectReference ref
	ObjectReference relTo
EndStruct

Struct HHC ; Highighter, Helper, Carrier
	ObjectReference ref
	ObjectReference highlighter
	ObjectReference helper
	ObjectReference carrier
EndStruct

PAS[] refsToPA

ObjectReference curGrabbedRef

HHC adv ; advanced options

Event OnInit()
	If (!WorkshopItemKeyword)
		WorkshopItemKeyword = Game.GetFormFromFile(0x54BA6, "Fallout4.esm") as Keyword
	EndIf
	If (!WorkshopStackedItemParentKEYWORD)
		WorkshopStackedItemParentKEYWORD = Game.GetFormFromFile(0x1C5EDD, "Fallout4.esm") as Keyword
	EndIf
	refsToPA = new PAS[0]
EndEvent

Event OnWorkshopObjectPlaced(ObjectReference akReference)
	RegisterForRemoteEvent(akReference, "OnWorkshopObjectGrabbed")
	RegisterForRemoteEvent(akReference, "OnWorkshopObjectMoved")
	RegisterForRemoteEvent(akReference, "OnWorkshopObjectDestroyed")
	RegisterForMenuOpenCloseEvent("PauseMenu")
	InitHCC(akReference)
EndEvent

Event OnWorkshopObjectDestroyed(ObjectReference akReference)
	refsToPA.Clear()
	curGrabbedRef = None
	ClearHHC()
	UnregisterForAllEvents()
EndEvent

Event ObjectReference.OnWorkshopObjectGrabbed(ObjectReference akSender, ObjectReference akReference)
	If (!Copypasta_IPACannotSelectList.HasForm(akReference.GetBaseObject()))
		HHC hhc = GetHHC()
		If (akReference == hhc.highlighter)
			highlightGrabbed = true
			shouldSpawnHighlight = false
			CancelTimer(HighlightPersistTimerID)
			CancelTimer(HighlightSpawnTimerID)
			If (!hasGroupSelection)
				ObjectReference[] att = SimulateGroupSelect(hhc.ref, SimulatedGroupSelectFactor).GetRefsLinkedToMe(Copypasta_GroupSelectionLink)
				Debug.Notification("Group-Select Done! " + att.Length + " found.")
				
				If (att.Length > 0)
					NewHHCarrier()
					int i = 0
					While (i < att.Length)
						If (hhc.carrier)
							Debug.Trace("Attaching " + att[i])
							att[i].AttachTo(hhc.carrier)
						EndIf
						i += 1
					EndWhile
					AttachHHCarrier()
				EndIf
				Debug.Notification("Attaching Done!")
				Copypasta_MSG_SelectionGrabbed.Show()
			EndIf
			Utility.Wait(0.1)
			hhc.highlighter.Disable() ; Change to safer function
		Else
			shouldSpawnHighlight = true
			StartTimer(HighlightAllowSpawnDuration, HighlightSpawnTimerID)
		EndIf
		akReference.SetLinkedRef(akReference, WorkshopItemKeyword)
		curGrabbedRef = akReference
	Else
		unselectableGrabbed = true
	EndIf
EndEvent

Event ObjectReference.OnWorkshopObjectMoved(ObjectReference akSender, ObjectReference ref)
	If (!Copypasta_IPACannotSelectList.HasForm(ref.GetBaseObject()))
		HHC hhc = GetHHC()
		Debug.Trace(ref + " moved")
		If (ref == hhc.highlighter && curGrabbedRef == hhc.highlighter)
			highlightGrabbed = false
			curGrabbedRef = None
			hhc.highlighter.Enable()
			StartTimer(HighlightPersistDuration, HighlightPersistTimerID)
			; do advanced Copypasta stuff
		Else
			If (curGrabbedRef != None && !highlightGrabbed)
				If (shouldPA)
					If (ref != curGrabbedRef)
						SaveRelativePAS(ref, curGrabbedRef)
						StartTimer(WaitForPADuration, PATimerID)
					; ElseIf (akReference.GetLinkedRef(WorkshopItemKeyword) == akReference)
						; akReference.SetLinkedRef(akSender, WorkshopItemKeyword)
						; StartTimer(WaitForPADuration, PATimerID)
					; Else
						; refsToPA.Clear()
						; shouldPA = false
					Else
						ref.SetLinkedRef(akSender, WorkshopItemKeyword)
						StartTimer(WaitForPADuration, PATimerID)
					EndIf
				Else
					If (ref.GetLinkedRef(WorkshopItemKeyword) == ref)
						ref.SetLinkedRef(akSender, WorkshopItemKeyword)
						If (shouldSpawnHighlight)
							MoveHHCTo(ref)
							StartTimer(HighlightPersistDuration, HighlightPersistTimerID)
						EndIf
					EndIf
					refsToPA.Clear()
				EndIf
			EndIf
		EndIf
		; shouldPA = false
		; curGrabbedRef = None
	Else
		unselectableGrabbed = false
	EndIf
EndEvent

Event ObjectReference.OnWorkshopObjectDestroyed(ObjectReference akSender, ObjectReference akReference)
	If (akReference == curGrabbedRef)
		curGrabbedRef = None
		refsToPA.Clear()
	EndIf
	shouldSpawnHighlight = false
	highlightGrabbed = false
	shouldPA = false
	unselectableGrabbed = false
EndEvent

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
	If (!unselectableGrabbed)
		If (asMenuName == "PauseMenu" && !abOpening)
			If (!shouldPA)
				shouldPA = true
				shouldSpawnHighlight = false
				SavePAS(curGrabbedRef)
				Debug.Notification("PA Activated!")
			Else
				shouldPA = false
				refsToPA.Clear()
				Debug.Notification("PA Aborted!")
			EndIf
		EndIf
	EndIf
EndEvent

Event OnTimer(int aiTimerID)
	If (aiTimerID == PATimerID)
		Debug.Trace("PATimer")
		EngagePA()
	ElseIf (aiTimerID == HighlightSpawnTimerID)
		Debug.Trace("HighlightSpawnTimer")
		shouldSpawnHighlight = false
	ElseIf (aiTimerID == HighlightPersistTimerID)
		Debug.Trace("HighlightPersistTimer")
		If (!highlightGrabbed)
			ClearGroupSelect()
			HideHHC()
		EndIf
	EndIf
EndEvent

; ##### PAS Functions #####

Function SavePAS(ObjectReference ref)
	PAS pas = new PAS
	pas.X = ref.GetPositionX()
	pas.Y = ref.GetPositionY()
	pas.Z = ref.GetPositionZ()
	pas.aX = ref.GetAngleX()
	pas.aY = ref.GetAngleY()
	pas.aZ = ref.GetAngleZ()
	;pas.scale = ref.GetScale()
	pas.ref = ref
	Debug.Trace("PAS saved!")
	refsToPA.Insert(pas, 0)
EndFunction

Function SaveRelativePAS(ObjectReference ref, ObjectReference relTo)
	PAS pas = new PAS
	pas.X = ref.GetPositionX() - relTo.GetPositionX()
	pas.Y = ref.GetPositionY() - relTo.GetPositionY()
	pas.Z = ref.GetPositionZ() - relTo.GetPositionZ()
	pas.aX = ref.GetAngleX()
	pas.aY = ref.GetAngleY()
	pas.aZ = ref.GetAngleZ()
	;pas.scale = ref.GetScale()
	pas.ref = ref
	pas.relTo = relTo
	Debug.Trace("Relative PAS saved!")
	refsToPA.Add(pas)
EndFunction

Function RestorePAS(PAS pas)
	If (pas.ref)
		pas.ref.Disable()
		If (pas.relTo)
			pas.ref.MoveTo(pas.relTo, pas.X, pas.Y, pas.Z, false)
		Else
			pas.ref.SetPosition(pas.X, pas.Y, pas.Z)
		EndIf
		pas.ref.SetAngle(pas.aX, pas.aY, pas.aZ)
		pas.ref.Enable()
		;pas.ref.SetMotionType(2)
		;pas.ref.SetScale(pas.scale)
		;pas.ref.Disable()
		;pas.ref.Enable()
		Debug.Trace("PAS restored!")
	EndIf
EndFunction

Function EngagePA()
	Debug.Trace("Engaging PA!")
	int i = refsToPA.Length - 1
	If (i > 0)
		RestorePAS(refsToPA[0])
		refsToPA.Remove(0, 1)
		i -= 1
	EndIf	
	While (i >= 0)
		RestorePAS(refsToPA[i])
		refsToPA.Remove(i, 1)
		i -= 1
	EndWhile
	shouldPA = false
	curGrabbedRef = None
EndFunction

; -------------------------------

; ##### Simulated Group-Select Functions #####

bool simGroupInit = false
bool hasGroupSelection = false

ObjectReference Function SimulateGroupSelect(ObjectReference akInitiator, float afMargin = 2.5, bool abAccurate = false)
	If (!simGroupInit)
		ObjectReference curWorkshop = (Game.GetFormFromFile(0x2058E, "Fallout4.esm") as WorkshopParentScript).CurrentWorkshop.GetReference()
		RegisterForRemoteEvent(curWorkshop, "OnWorkshopObjectPlaced")
		ObjectReference[] tmp = curWorkshop.GetRefsLinkedToMe(WorkshopItemKeyword)
		int i = 0
		While (i < tmp.Length)
			If (!Copypasta_IPACannotSelectList.HasForm(tmp[i].GetBaseObject()))
				tmp[i].AddKeyword(Copypasta_SearchKeyword)
			EndIf
			i += 1
		EndWhile
		tmp.Clear()
		tmp = None
		simGroupInit = true
	EndIf
	If (akInitiator)
		If (abAccurate)
			; TODO: base on orientation and separate width, height, length
		Else
			HHC tmp = GetHHC()
			If (FindNearbyRefs(tmp.highlighter, akInitiator, afMargin, abAccurate))
				hasGroupSelection = true
			EndIf
			return tmp.highlighter
		EndIf
	EndIf
	return None
EndFunction

Function ClearGroupSelect(ObjectReference akReference = None)
	If (akReference == None)
		HHC tmp = GetHHC()
		akReference = tmp.highlighter
	EndIf
	ObjectReference[] sel = akReference.GetRefsLinkedToMe(Copypasta_GroupSelectionLink)
	int i = 0
	While (i < sel.Length)
		sel[i].SetLinkedRef(None, Copypasta_GroupSelectionLink)
		i += 1
	EndWhile
	hasGroupSelection = false
EndFunction
	
Event ObjectReference.OnWorkshopObjectPlaced(ObjectReference akSender, ObjectReference akReference)
	If (!Copypasta_IPACannotSelectList.HasForm(akReference.GetBaseObject()))
		akReference.AddKeyword(Copypasta_SearchKeyword)
	EndIf
EndEvent

bool Function FindNearbyRefs(ObjectReference akInitiator, ObjectReference curRef, float afMargin, bool abAccurate)
	bool refsFound = false
	ObjectReference[] tmp
	If (abAccurate)
		;Accturate stuff
	Else
		ObjectReference c = curRef
		float radius = (Math.Max(Math.Max(Math.Max(c.GetLength(), c.GetHeight()), c.GetWidth()) * c.GetScale(), 50.0) / 2.0) * afMargin
		tmp = c.FindAllReferencesWithKeyword(Copypasta_SearchKeyword, radius)
		Debug.Trace(tmp.Length + " found with search radius " + radius)
		int i = 0
		While (i < tmp.Length)
			ObjectReference t = tmp[i]
			If (t.GetLinkedRef(Copypasta_GroupSelectionLink) != akInitiator && !t.IsDisabled() && !Copypasta_IPACannotSelectList.HasForm(t.GetBaseObject()))
				refsFound = true
				t.SetLinkedRef(akInitiator, Copypasta_GroupSelectionLink)
				FindNearbyRefs(akInitiator, t, afMargin, abAccurate)
			EndIf
			i += 1
		EndWhile
		tmp.Clear()
		tmp = None
	EndIf
	return refsFound
EndFunction

; --------------------------------

; ##### HHC Functions #####

Function InitHCC(ObjectReference akReference)
	HHC hhc = new HHC
	hhc.highlighter = PlaceAtMe(Copypasta_Highlighter, abInitiallyDisabled = true, abDeleteWhenAble = false)
	hhc.helper = PlaceAtMe(Copypasta_Helper, abInitiallyDisabled = true)
	hhc.helper.SetLinkedRef(hhc.highlighter, WorkshopStackedItemParentKEYWORD)
	hhc.helper.SetScale(0.2)
	hhc.carrier = None
	hhc.ref = None
	adv = hhc
EndFunction

HHC Function GetHHC()
	If (!adv)
		return None
	EndIf
	return adv
EndFunction

Function MoveHHCTo(ObjectReference ref)
	HHC hhc = GetHHC()
	ClearGroupSelect(hhc.highlighter)
	hhc.ref = ref
	hhc.highlighter.Disable()
	hhc.helper.Disable()
	If (hhc.carrier)
		hhc.carrier.Disable()
		hhc.carrier.Delete()
		hhc.carrier = None
	EndIf
	hhc.highlighter.MoveTo(ref, afZOffset = ref.GetHeight() / 2)
	hhc.helper.MoveTo(ref, abMatchRotation = false)
	If (hhc.helper.GetLinkedRef(WorkshopStackedItemParentKEYWORD) != hhc.highlighter)
		hhc.helper.SetLinkedRef(hhc.highlighter, WorkshopStackedItemParentKEYWORD)
	EndIf
	float size = (Math.Max(Math.Max(ref.GetLength(), ref.GetHeight()), ref.GetWidth()) * ref.GetScale()) / 50
	hhc.highlighter.SetScale(size)
	hhc.highlighter.Enable()
	hhc.helper.Enable()
EndFunction	

Function NewHHCarrier()
	HHC hhc = GetHHC()
	If (hhc.carrier)
		hhc.carrier.Disable()
		hhc.carrier.Delete()
		hhc.carrier = None
	EndIf
	hhc.carrier = PlaceAtMe(Copypasta_Carrier, abInitiallyDisabled = true)
	hhc.carrier.SetScale(0.3)
	hhc.carrier.Enable()
	hhc.carrier.WaitFor3DLoad()
EndFunction	

Function AttachHHCarrier()
	HHC hhc = GetHHC()
	If (!hhc.carrier.IsDisabled())
		hhc.carrier.Disable()
	EndIf
	hhc.helper.Disable()
	hhc.carrier.MoveTo(hhc.helper)
	hhc.helper.Enable()
	hhc.carrier.AttachTo(hhc.helper)
	hhc.carrier.Enable()
	hhc.carrier.WaitFor3DLoad()
EndFunction	

Function HideHHC()
	HHC hhc = GetHHC()
	hhc.ref = None
	hhc.highlighter.Disable()
	hhc.helper.Disable()
	If (hhc.carrier)
		hhc.carrier.Disable()
		hhc.carrier.Delete()
		hhc.carrier = None
	EndIf
EndFunction	

Function ClearHHC()
	If (adv)
		adv.ref = None
		If (adv.highlighter)
			adv.highlighter.Disable()
			adv.highlighter.Delete()
			adv.highlighter = None
		EndIf
		If (adv.helper)
			adv.helper.Disable()
			adv.helper.Delete()
			adv.helper = None
		EndIf
		If (adv.carrier)
			adv.carrier.Disable()
			adv.carrier.Delete()
			adv.carrier = None
		EndIf
		adv = None
	EndIf
EndFunction	

; ----------------------------------