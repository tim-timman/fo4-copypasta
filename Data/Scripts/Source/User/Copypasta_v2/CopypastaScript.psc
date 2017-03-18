ScriptName Copypasta_v2:CopypastaScript extends ObjectReference Conditional

Import Debug

Group InitialSetup
	bool Property ShouldStartHandleSelectionOnGrab = true Auto Const
	{ Should be grabbing the PA also grab the selection of when just built? }
	bool Property ShouldStartActive = true Auto Const
	{ Should the PA start registering for selection directly when built? }
	bool Property ShouldStartGrabSelectionOnGrab = true Auto Const
	{ Should the PA grab selection when grabbed as a default? }
	bool Property ShouldStartAddGroupSelectToSelection = true Auto Const
	{ Should the PA add a group-selection to the selection as a default? }
	bool Property ShouldAddCarriedObjectsToSelection = false Auto Const
	{ Should the PA add carried object to selection when a parent is selected? }
	bool Property ShouldStartUseQuickCopy = true Auto Const
	{ Should the PA use Quick Copy in Copy Mode as a default? }
	float Property AddToSelectionFailsafeDuration = 1.0 Auto Const
	{ If not cancelled within this time, assume something went wrong or the player didn't intend to select it }
	float Property WaitingForGroupSelectDuration = 1.5 Auto Const
	{ If no new selecting has fired within this time, stop waiting }
	float Property WaitBusyFailsafeDuration = 60.0 Auto Const
	{ If not cancelled within this time assume something's gone wrong }
	float Property PauseWaitMenuTimerDuration = 1.0 Auto Const
	{ Time to wait when paused to open the Copypasta menu when grabbed }
	float Property PreventDamageFailsafeDuration = 5.0 Auto Const
	{ The failsafe duration for preventing fall damage }
EndGroup

Group Mutable_Settings
	bool Property ShouldCopy = true Auto Conditional
	{ Should it copy the current selection instead of moving it? }
	bool Property SelectWithPause = false Auto Conditional
	{ Add items to the selection by using by pressing Pause-Unpause instead of grab and cancel }
EndGroup

Group Messages Collapsed
	Message Property Copypasta_MB_RotationMenu Auto Const
	Message Property Copypasta_MB_Menu Auto Const
	Message Property Copypasta_MSG_SelectionGrabbed Auto Const
	Message Property Copypasta_MSG_SelectionPlaced Auto Const
	Message Property Copypasta_MSG_SelectionCopied Auto Const
	Message Property Copypasta_MSG_SelectionCleared Auto Const
	Message Property Copypasta_MSG_SelectionDeleted Auto Const
	Message Property Copypasta_MSG_SelectionFrozen Auto Const
	Message Property Copypasta_MSG_SelectionDefrosted Auto Const
	Message Property Copypasta_MSG_SelectionQuickCopiedAndGrabbed Auto Const
	Message Property Copypasta_MSG_SelectionQuickCopyPlaceReady Auto Const
EndGroup

Group Required_Properties
	Form Property Copypasta_Helper Auto Mandatory Const
	{ A small model with ATTACH_REF_NODE }
	Form Property Copypasta_Carrier Auto Mandatory Const
	{ A small model with ATTACH_REF_NODE }
	Keyword Property Copypasta_HelperLink Auto Mandatory Const
	Keyword Property Copypasta_CarrierLink Auto Mandatory Const
	Keyword Property Copypasta_SelectionLink Auto Mandatory Const
	Keyword Property Copypasta_ConditionalPlayerLink Auto Mandatory Const
	EffectShader Property Copypasta_HighlightShader Auto Mandatory Const
	Formlist Property Copypasta_CannotSelectList Auto Mandatory Const
	{ Formlist of Forms that cannot be selected by the Copypasta }
	Form Property Copypasta_DummyLookAtMarker Auto Mandatory Const
	{ A marker model as a reference to look at for GroupSelection feature }
	Keyword Property Copypasta_SearchKeyword Auto Mandatory Const
EndGroup

Group AutoFill Collapsed
	Keyword Property WorkshopItemKeyword Auto Const Mandatory
	Keyword Property WorkshopStackedItemParentKEYWORD Auto Const Mandatory
	Action Property ActionLand Auto Const Mandatory
	WorkshopParentScript Property WorkshopParent Auto Const Mandatory
EndGroup

; The current (non-self) object grabbed in the workshop
ObjectReference Property CurrentObject Auto Hidden
ObjectReference Property WorkshopRef Auto Hidden

; ------------- Variables -------------

int PauseWaitMenuTimerID = 17
int PreventDamageFailsafeTimerID = 42
int AddToSelectionFailsafeTimerID = 723
int WaitingForGroupSelectTimerID = 272
int WaitBusyFailsafeTimerID = 314
bool hasBeenPaused = false
bool busyBlock = false

;APS referencePos ; <--- Will come into play with recipes

bool listenForSelections Conditional
bool allowHandleSelection Conditional
bool grabSelectionOnGrab Conditional
bool addGroupSelectionsToSelection Conditional
bool addCarriedObjectsToSelection Conditional
bool isSelectionGrabbed = false Conditional
bool isSelectionFrozen = false Conditional
bool isCopiedSelection = false Conditional
bool isSelfGrabbed = false Conditional
bool hasSelection = false Conditional
bool waitingForGroupSelect = false Conditional
bool isRotationLocked = false Conditional
bool useQuickCopy = false Conditional

bool isInWorkshopMode = false
bool settingsMenuActive = false
bool rotationMenuActive = false
bool isInitialized = false

InputEnableLayer Property myLayer Auto Hidden

; ######################### TEMP DEV #######################

; Event OnActivate(ObjectReference akActionRef)
	; If (akActionRef == Game.GetPlayer())
		; ShouldCopy = !ShouldCopy
	; EndIf
; EndEvent

; ##########################################################

Function PrepareWorkshopMode(bool abOpening = true)
	Trace("WorkshopRef = " + WorkshopRef)
	ObjectReference playerRef = Game.GetPlayer()
	If (abOpening)
		TraceSelf(self, "PrepareWorkshopMode", abOpening+" => Registering")
		RegisterForRemoteEvent(WorkshopRef, "OnWorkshopObjectGrabbed")
		RegisterForRemoteEvent(WorkshopRef, "OnWorkshopObjectMoved")
		RegisterForRemoteEvent(WorkshopRef, "OnWorkshopObjectPlaced")
		RegisterForAnimationEvent(playerRef, "JumpUp")
		RegisterForMenuOpenCloseEvent("PauseMenu")
		allowHandleSelection = true
	Else
		TraceSelf(self, "PrepareWorkshopMode", abOpening+" => Unregistering")
		CancelTimer(AddToSelectionFailsafeTimerID)
		CancelTimer(WaitBusyFailsafeTimerID)
		CancelTimer(PauseWaitMenuTimerID)
		CancelTimer(PreventDamageFailsafeTimerID)
		CancelTimer(WaitingForGroupSelectTimerID)
		UnregisterForRemoteEvent(WorkshopRef, "OnWorkshopObjectGrabbed")
		UnregisterForRemoteEvent(WorkshopRef, "OnWorkshopObjectMoved")
		UnregisterForRemoteEvent(WorkshopRef, "OnWorkshopObjectDestroyed")
		UnregisterForRemoteEvent(WorkshopRef, "OnWorkshopObjectPlaced")
		UnregisterForAnimationEvent(playerRef, "JumpUp")
		UnregisterForMenuOpenCloseEvent("PauseMenu")
		ClearSelection()
		isInWorkshopMode = false
		hasBeenPaused = false
		allowHandleSelection = false
		isSelectionGrabbed = false
		isSelectionFrozen = false
		isCopiedSelection = false
		waitingForGroupSelect = false
	EndIf
EndFunction

Function OnGrabbedRefCancelled(ObjectReference akReference)
	If (akReference.GetLinkedRef(Copypasta_SelectionLink) == None || waitingForGroupSelect)
		AddToSelection(akReference)
	Else
		RemoveFromSelection(akReference)
	EndIf
EndFunction

Function OnGrabbedRefMoved(ObjectReference akReference)
	; do nothing
EndFunction

Function OnGrabbedRefPaused(ObjectReference akReference)
	; currently do the same as if cancelled
	TraceSelf(self, "OnGrabbedRefPaused", "Calling OnGrabbedRefCancelled")
	OnGrabbedRefCancelled(akReference)
EndFunction


; Function ShowMenu() ; For version Copypasta_Menu_v2
	; If (Copypasta_MB_Menu)
		; settingsMenuActive = true
		; bool exitMenu = false
		; ObjectReference playerRef = Game.GetPlayer()
		; ObjectReference helper = GetHelper()
		; playerRef.SetLinkedRef(self, Copypasta_ConditionalPlayerLink)
		; While (!exitMenu)
			; int i = Copypasta_MB_Menu.Show()
			; ; If (i == 0)
				; ; listenForSelections = true
				; ; PrepareWorkshopMode(true)
			; If (i == 0) ; Unloack axis
				; UpdateHelperPosition()
			; ElseIf (i == 1) ; Change to Copy Mode
				; ShouldCopy = true
			; ElseIf (i == 2) ; Change to Move Mode
				; ShouldCopy = false
			; ElseIf (i == 3)
				; grabSelectionOnGrab = true
			; ElseIf (i == 4)
				; grabSelectionOnGrab = false
			; ElseIf (i == 5)
				; addCarriedObjectsToSelection = true
			; ElseIf (i == 6)
				; addCarriedObjectsToSelection = false
			; ElseIf (i == 7)
				; addGroupSelectionsToSelection = true
			; ElseIf (i == 8)
				; addGroupSelectionsToSelection = false
			; ElseIf (i == 9) ; Select = PAUSE
				; SelectWithPause = false
			; ElseIf (i == 10) ; Select = CANCEL
				; SelectWithPause = true
			; ElseIf (i == 11) ; Copy setting = REGULAR
				; useQuickCopy = true
			; ElseIf (i == 12) ; Copy setting = QUICK
				; useQuickCopy = false
			; ElseIf (i == 13) ; Place selection
				; PlaceSelection()
			; ElseIf (i == 14) ; Freeze selection
				; FreezeSelection()
			; ElseIf (i == 15) ; Defrost selection
				; UnfreezeSelection()
			; ElseIf (i == 16) ; Clear selection
				; If (isSelectionGrabbed)
					; PlaceSelection()
				; EndIf
				; ClearSelection()
			; ElseIf (i == 17) ; Delete selection
				; DeleteSelection()
			; ElseIf (i == 18) ; Lock axis
				; helper.Disable()
				; helper.SetAngle(90.0, -playerRef.GetAngleZ(), helper.GetAngleZ())
				; helper.Enable()
				; isRotationLocked = true
			; ; ElseIf (i == 18)
				; ; listenForSelections = false
				; ; PrepareWorkshopMode(false)
			; Else
				; exitMenu = true
			; EndIf
		; EndWhile
		; playerRef.SetLinkedRef(None, Copypasta_ConditionalPlayerLink)
		; settingsMenuActive = false
	; EndIf
; EndFunction

Function ShowMenu() ; For Copypasta_MB_Menu_2_1
	If (Copypasta_MB_Menu)
		settingsMenuActive = true
		bool exitMenu = false
		ObjectReference playerRef = Game.GetPlayer()
		ObjectReference helper = GetHelper()
		playerRef.SetLinkedRef(self, Copypasta_ConditionalPlayerLink)
		While (!exitMenu)
			int i = Copypasta_MB_Menu.Show()
			; If (i == 0)
				; listenForSelections = true
				; PrepareWorkshopMode(true)
			If (i == 0) ; Unloack axis
				UpdateHelperPosition()
			ElseIf (i == 1) ; Curent Mode = MOVE
				ShouldCopy = true
			ElseIf (i == 2) ; Curent Mode = COPY
				ShouldCopy = false
			ElseIf (i == 3)
				grabSelectionOnGrab = true
				waitingForGroupSelect = false
			ElseIf (i == 4)
				grabSelectionOnGrab = false
				waitingForGroupSelect = true
			ElseIf (i == 5)
				addCarriedObjectsToSelection = true
			ElseIf (i == 6)
				addCarriedObjectsToSelection = false
			ElseIf (i == 7)
				addGroupSelectionsToSelection = true
			ElseIf (i == 8)
				addGroupSelectionsToSelection = false
				waitingForGroupSelect = false
			ElseIf (i == 9) ; Select = PAUSE
				SelectWithPause = false
			ElseIf (i == 10) ; Select = CANCEL
				SelectWithPause = true
			; ElseIf (i == 11) ; Copy setting = REGULAR
				; useQuickCopy = true
			; ElseIf (i == 12) ; Copy setting = QUICK
				; useQuickCopy = false
			ElseIf (i == 11) ; Place selection
				PlaceSelection()
			ElseIf (i == 12) ; Freeze selection
				FreezeSelection()
			ElseIf (i == 13) ; Defrost selection
				UnfreezeSelection()
			ElseIf (i == 14) ; Clear selection
				If (isSelectionGrabbed)
					PlaceSelection()
				EndIf
				ClearSelection()
			ElseIf (i == 15) ; Delete selection
				DeleteSelection()
			ElseIf (i == 16) ; Lock axis
				helper.Disable()
				helper.SetAngle(90.0, -playerRef.GetAngleZ(), helper.GetAngleZ())
				helper.Enable()
				isRotationLocked = true
			ElseIf (i == 17)
				listenForSelections = true
				PrepareWorkshopMode(true)
			ElseIf (i == 18)
				listenForSelections = false
				PrepareWorkshopMode(false)
			Else
				exitMenu = true
			EndIf
		EndWhile
		playerRef.SetLinkedRef(None, Copypasta_ConditionalPlayerLink)
		settingsMenuActive = false
	EndIf
EndFunction

bool originalRotationSet = false
float originalRotation = 0.0

Function RotationSetup(bool abSetup = true)
	If (abSetup)
		If (!originalRotationSet)
			originalRotation = GetCarrier().GetAngleZ()
			originalRotationSet = true
		EndIf
		If (myLayer == None)
			myLayer = InputEnableLayer.Create()
		EndIf
		myLayer.EnableLooking(false)
		RegisterForAnimationEvent(Game.GetPlayer(), "SyncRight")
	Else
		UnregisterForAnimationEvent(Game.GetPlayer(), "SyncRight")
		UpdateHelperPosition()
		If (myLayer != None)
			myLayer.Delete()
			myLayer = None
		EndIf
	EndIf
EndFunction

Function ShowRotationMenu()
	If (Copypasta_MB_RotationMenu)
		rotationMenuActive = true
		bool exitMenu = false
		ObjectReference playerRef = Game.GetPlayer()
		playerRef.SetLinkedRef(self, Copypasta_ConditionalPlayerLink)
		ObjectReference helper = GetHelper()
		While (!exitMenu)
			int i = Copypasta_MB_RotationMenu.Show()
			If (i == 0) ; X-Axis
				RotationSetup(true)
				helper.Disable()
				helper.SetAngle(90.0, -playerRef.GetAngleZ(), helper.GetAngleZ())
				helper.Enable()
				exitMenu = true
			ElseIf (i == 1) ; Y-Axis
				RotationSetup(true)
				helper.Disable()
				helper.SetAngle(90.0, 90.0-playerRef.GetAngleZ(), helper.GetAngleZ())
				helper.Enable()
				exitMenu = true
			ElseIf (i == 2) ; Z-Axis
				If (!originalRotationSet)
					originalRotation = GetCarrier().GetAngleZ()
					originalRotationSet = true
				EndIf
				RotationSetup(false)
				exitMenu = true
			ElseIf (i == 3)
				; TODO: Reset rotations
				If (originalRotationSet)
					helper.Disable()
					ObjectReference carrier = GetCarrier()
					carrier.SetAngle(0.0, 0.0, originalRotation)
					originalRotationSet = false
					helper.Enable()
					RotationSetup(false)
				EndIf
				exitMenu = true
			ElseIf (i == 4)
				ShowMenu()
			Else
				exitMenu = true
			EndIf
		EndWhile
		playerRef.SetLinkedRef(None, Copypasta_ConditionalPlayerLink)
		rotationMenuActive = false
	EndIf
EndFunction

State Waiting

Function OnPaused()
	GotoState("Busy")
	TraceSelf(self, "OnPaused", "")
	If (isSelfGrabbed)
		If (grabSelectionOnGrab)
			If (isSelectionGrabbed)
				If (ShouldCopy)
					PlaceSelection()
				Else
					ToggleFreezeSelection()
				EndIf
			Else
				If (useQuickCopy && ShouldCopy)
					QuickCopyGrabSelection2()
				Else
					If (ShouldCopy)
						CopySelection()
					EndIf
					QuickGrabSelection()
				EndIf
			EndIf
		Else
			If (waitingForGroupSelect)
				; AddGroupSelectionToSelection()
				; AddGroupSelectionToSelection2()
			EndIf
		EndIf
	Else
		hasBeenPaused = !hasBeenPaused
	EndIf
	GotoState("Waiting")
EndFunction

Event OnWorkshopObjectGrabbed(ObjectReference akReference)
	TraceSelf(self, "OnWorkshopObjectGrabbed", "")
	isSelfGrabbed = true
	;SetLinkedRef(None, WorkshopItemKeyword)
	If (allowHandleSelection)
		Disable()
		Trace("... allowHandleSelection = true")
		GotoState("Busy")
		; referencePos = GetAPS(Self) <= For recipe referencing postiton relative to post (self)
		If (grabSelectionOnGrab)
			If (CountRefsLinkedToMe(Copypasta_SelectionLink) > 0)
				If (useQuickCopy && ShouldCopy)
					Trace("...Quick-Copying and Grabbing Selection")
					QuickCopyGrabSelection2()
				Else
					If (ShouldCopy)
						Trace("...Copying Selection")
						CopySelection()
					EndIf
					Trace("...Grabbing Selection")
					QuickGrabSelection()
				EndIf
			Else
				Trace("...Nothing selected")
			EndIf
		ElseIf (addGroupSelectionsToSelection && !grabSelectionOnGrab)
			waitingForGroupSelect = true
		EndIf
		GotoState("Waiting")
	Else
		; nothing
	EndIf
EndEvent
Event OnLoad()
	; empty
EndEvent

EndState


Event OnWorkshopObjectMoved(ObjectReference akReference)
	If (myLayer != None)
		myLayer.Delete()
		myLayer = None
	EndIf
	StartTimer(WaitBusyFailsafeDuration, WaitBusyFailsafeTimerID)
	While (busyBlock)			
		Utility.Wait(0.5)
	EndWhile
	CancelTimer(WaitBusyFailsafeTimerID)
	TraceSelf(self, "OnWorkshopObjectMoved", "")
	If (allowHandleSelection)
		If (isSelectionGrabbed)
			If (GetLinkedRef(WorkshopItemKeyword) != None)
				PlaceSelection()
			Else
				If (isCopiedSelection && ShouldCopy)
					DeleteSelection()
				Else
					PlaceSelection()
				EndIf
			EndIf
		ElseIf (addGroupSelectionsToSelection && !grabSelectionOnGrab)
			StartTimer(WaitingForGroupSelectDuration, WaitingForGroupSelectTimerID)
		EndIf
	EndIf
	RotationSetup(false)
	;SetLinkedRef(WorkshopRef, WorkshopItemKeyword)
	PreventDamage(true)
	Enable()
	isSelfGrabbed = false
	waitingForGroupSelect = false
	originalRotationSet = false
	GotoState("Waiting")
EndEvent
	
	
State Busy
	Event OnBeginState(string asOldState)
		Trace("---Busy---")
		busyBlock = true
	EndEvent
	Function OnPaused()
		; empty
	EndFunction
	Event OnLoad()
		; empty
	EndEvent
	Event OnWorkshopObjectGrabbed(ObjectReference akReference)
		; empty
	EndEvent
	Event OnEndState(string asOldState)
		Trace("---Not Busy---")
		busyBlock = false
	EndEvent
EndState

Function OnPaused()
	; empty
EndFunction





; ################## Selection #####################

ObjectReference[] Function GetSelection()
	return GetRefsLinkedToMe(Copypasta_SelectionLink)
EndFunction

; [OBSOLETE] - Use QuickGrabSelection())
Function GrabSelection()
	TraceSelf(self, "GrabSelection", "")
	ObjectReference[] selection = GetSelection()
	If (selection.Length <  1)
		return
	EndIf
	ObjectReference carrier = GetCarrier()
	If (carrier.IsDisabled())
		carrier.Enable()
		carrier.WaitFor3DLoad()
	EndIf
	int i = 0
	While (i < selection.Length)
		ObjectReference tmp = selection[i]
		RemoveHighlight(selection[i])
		tmp.SetMotionType(tmp.Motion_Keyframed)
		tmp.AttachTo(carrier)
		i += 1
	EndWhile
	AttachCarrier()
	If (Copypasta_MSG_SelectionGrabbed)
		Copypasta_MSG_SelectionGrabbed.Show()
	EndIf
	isSelectionGrabbed = true
	isSelectionFrozen = false
EndFunction

Function QuickGrabSelection()
	TraceSelf(self, "QuickGrabSelection", "")
	ObjectReference[] selection = GetSelection()
	If (selection.Length <  1)
		return
	EndIf
	ObjectReference carrier = GetCarrier()
	int i = 0
	While (i < selection.Length)
		ObjectReference tmp = selection[i]
		Form tmpBase = tmp.GetBaseObject()
		If (tmpBase as MovableStatic == None || tmpBase as Static || tmpBase as Furniture || tmpBase as Door || tmpBase as Activator || tmpBase as Light || tmpBase as Container || tmpBase as Flora || tmpBase as Terminal)
			; nothing
		Else
			tmp.SetMotionType(2)
		EndIf
		tmp.AttachTo(carrier)
		i += 1
	EndWhile
	AttachCarrier()
	If (Copypasta_MSG_SelectionGrabbed)
		Copypasta_MSG_SelectionGrabbed.Show()
	EndIf
	i = 0
	While (i < selection.Length)
		; ObjectReference tmp = selection[i]
		RemoveHighlight(selection[i])
		i += 1
	EndWhile
	isSelectionGrabbed = true
	isSelectionFrozen = false
EndFunction

Function PlaceSelection()
	TraceSelf(self, "PlaceSelection", "")
	NewCarrier()
	AttachCarrier(false)
	ObjectReference[] selection = GetSelection()
	If (selection.Length <  1)
		return
	EndIf
	Var[] params = new Var[1]
	params[0] = WorkshopRef as ObjectReference
	WorkshopScript workshop = WorkshopRef as WorkshopScript
	int i = 0
	While (i < selection.Length)
		ObjectReference tmp = selection[i]
		Form tmpBase = tmp.GetBaseObject()
		tmp.SetLinkedRef(WorkshopRef, WorkshopItemKeyword)
		tmp.Disable()
		tmp.Enable()
		;tmp.SetMotionType(tmp.Motion_Dynamic, false)
		AddHighlight(tmp)
		
		If (tmpBase as MovableStatic == None && (tmpBase as Static || tmpBase as Furniture || tmpBase as Door || tmpBase as Activator || tmpBase as Light || tmpBase as Container || tmpBase as Flora || tmpBase as Terminal))
			ScriptObject simulWorkshop = tmp.CastAs("ObjectReference")
			If (isCopiedSelection)
				WorkshopParent.BuildObjectPUBLIC(tmp, workshop)
				TraceSelf(self, "PlaceSelection", "Simulate Placed = " + simulWorkshop)
				If (simulWorkshop)
					simulWorkshop.CallFunctionNoWait("OnWorkshopObjectPlaced", params)
				EndIf
			EndIf
			TraceSelf(self, "PlaceSelection", "Simulate Moved = " + simulWorkshop)
			If (simulWorkshop)
				simulWorkshop.CallFunctionNoWait("OnWorkshopObjectMoved", params)
			EndIf
		EndIf
		i += 1
	EndWhile
	If (Copypasta_MSG_SelectionPlaced)
		Copypasta_MSG_SelectionPlaced.Show()
	EndIf
	isSelectionGrabbed = false
	isSelectionFrozen = false
	isCopiedSelection = false
EndFunction

; [OBSOLETE] - Use QuickCopyGrabSelection()
Function CopySelection()
	TraceSelf(self, "CopySelection", "Starting...")
	ObjectReference carrier = GetCarrier()
	ObjectReference[] selection = GetSelection()
	If (selection.Length <  1)
		return
	EndIf
	int i = 0
	While (i < selection.Length)
		ObjectReference tmp = selection[i]
		ObjectReference copy = PlaceAtMe(tmp.GetBaseObject(), 1, false, true, false)
		SetAPS(copy, GetAPS(tmp))
		If (copy.GetBaseObject() as Weapon != None)
			copy.Enable()
			If (copy.WaitFor3DLoad())
				copy.SetMotionType(tmp.Motion_Keyframed)
			EndIf
		Else
			copy.EnableNoWait()
		EndIf
		tmp.SetLinkedRef(None, Copypasta_SelectionLink)
		RemoveHighlight(tmp)
		copy.SetLinkedRef(Self, Copypasta_SelectionLink)
		i += 1
	EndWhile
	If (Copypasta_MSG_SelectionCopied)
		Copypasta_MSG_SelectionCopied.Show()
	EndIf
	isSelectionGrabbed = false
	isCopiedSelection = true
EndFunction

Function QuickCopyGrabSelection()
	TraceSelf(self, "QuickCopyGrabSelection", "Starting...")
	ObjectReference carrier = GetCarrier()
	ObjectReference[] selection = GetSelection()
	ObjectReference[] copiedSelection = new ObjectReference[selection.Length]
	Int[] makeStatic = new Int[0]
	If (selection.Length <  1)
		return
	EndIf
	int i = 0
	While (i < selection.Length)
		ObjectReference tmp = selection[i]
		Form tmpBase = tmp.GetBaseObject()
		ObjectReference copy = PlaceAtMe(tmpBase, 1, false, true, false)
		copiedSelection[i] = copy
		copy.SetScale(tmp.GetScale())
		If (tmpBase as MovableStatic == None && (tmpBase as Static || tmpBase as Furniture || tmpBase as Door || tmpBase as Activator || tmpBase as Light || tmpBase as Container || tmpBase as Flora || tmpBase as Terminal))
			copy.MoveTo(tmp)
			copy.EnableNoWait()
			copy.AttachTo(carrier)
		Else
			makeStatic.Add(i)
		EndIf
		i += 1
	EndWhile
	TraceSelf(self, "QuickCopyGrabSelection", "Everything copied, making dynamic objects static.")
	i = 0
	While (i < makeStatic.Length)
		ObjectReference copy = copiedSelection[makeStatic[i]]
		copy.Enable()
		If (copy.WaitFor3DLoad())
			copy.SetMotionType(2)
			copy.MoveTo(selection[i])
			copy.AttachTo(carrier)
		EndIf
		i += 1
	EndWhile
	
	AttachCarrier()
	
	TraceSelf(self, "QuickCopyGrabSelection", "Grabbed and ready!")
	
	If (Copypasta_MSG_SelectionQuickCopiedAndGrabbed)
		Copypasta_MSG_SelectionQuickCopiedAndGrabbed.Show()
	EndIf
	i = 0
	While (i < selection.Length)
		ObjectReference tmp = selection[i]
		ObjectReference copy = copiedSelection[i]
		tmp.SetLinkedRef(None, Copypasta_SelectionLink)
		copy.SetLinkedRef(Self, Copypasta_SelectionLink)
		copy.AddKeyword(Copypasta_SearchKeyword)
		Copypasta_HighlightShader.Stop(tmp)
		i += 1
	EndWhile
	
	isSelectionGrabbed = true
	isCopiedSelection = true
	
	TraceSelf(self, "QuickCopyGrabSelection", "Done!")
	If (Copypasta_MSG_SelectionQuickCopyPlaceReady)
		Copypasta_MSG_SelectionQuickCopyPlaceReady.Show()
	EndIf
EndFunction

Function QuickCopyGrabSelection2()
	TraceSelf(self, "QuickCopyGrabSelection2", "Starting...")
	ObjectReference carrier = GetCarrier()
	ObjectReference[] selection = GetSelection()
	If (selection.Length < 1)
		return
	EndIf
	ObjectReference[] copiedSelection = GetSelection()
	Int[] makeStatic = new Int[0]
	int i = 0
	While (i < selection.Length)
		ObjectReference tmp = selection[i]
		Form tmpBase = tmp.GetBaseObject()
		ObjectReference copy = PlaceAtMe(tmpBase, 1, false, true, false)
		copiedSelection[i] = copy
		copy.SetScale(tmp.GetScale())
		If (tmpBase as MovableStatic == None && (tmpBase as Static || tmpBase as Furniture || tmpBase as Door || tmpBase as Activator || tmpBase as Light || tmpBase as Container || tmpBase as Flora || tmpBase as Terminal))
			copy.MoveTo(tmp)
			copy.EnableNoWait()
			copy.AttachTo(carrier)
		Else
			If (makeStatic.Length >= 128)
				int j = 0
				While (j < makeStatic.Length)
					ObjectReference cur = copiedSelection[makeStatic[j]]
					copy.Enable()
					If (copy.WaitFor3DLoad())
						copy.SetMotionType(2)
						copy.MoveTo(selection[j])
						copy.AttachTo(carrier)
					EndIf
					j += 1
				EndWhile
				makeStatic = new Int[0]
			EndIf
			makeStatic.Add(i)
		EndIf
		i += 1
	EndWhile
	TraceSelf(self, "QuickCopyGrabSelection2", "Everything copied, making dynamic objects static.")
	i = 0
	While (i < makeStatic.Length)
		ObjectReference copy = copiedSelection[makeStatic[i]]
		copy.Enable()
		If (copy.WaitFor3DLoad())
			copy.SetMotionType(2)
			copy.MoveTo(selection[i])
			copy.AttachTo(carrier)
		EndIf
		i += 1
	EndWhile
	
	AttachCarrier()
	
	TraceSelf(self, "QuickCopyGrabSelection2", "Grabbed and ready!")
	
	If (Copypasta_MSG_SelectionQuickCopiedAndGrabbed)
		Copypasta_MSG_SelectionQuickCopiedAndGrabbed.Show()
	EndIf
	i = 0
	While (i < selection.Length)
		ObjectReference tmp = selection[i]
		ObjectReference copy = copiedSelection[i]
		tmp.SetLinkedRef(None, Copypasta_SelectionLink)
		copy.SetLinkedRef(Self, Copypasta_SelectionLink)
		copy.AddKeyword(Copypasta_SearchKeyword)
		Copypasta_HighlightShader.Stop(tmp)
		i += 1
	EndWhile
	
	isSelectionGrabbed = true
	isCopiedSelection = true
	
	TraceSelf(self, "QuickCopyGrabSelection2", "Done!")
	If (Copypasta_MSG_SelectionQuickCopyPlaceReady)
		Copypasta_MSG_SelectionQuickCopyPlaceReady.Show()
	EndIf
EndFunction

Function DeleteSelection()
	TraceSelf(self, "DeleteSelection", "")
	DeleteCarrier()
	ObjectReference[] selection = GetSelection()
	If (selection.Length <  1)
		return
	EndIf
	int i = 0
	WorkshopScript workshop = WorkshopRef as WorkshopScript
	While (i < selection.Length)
		ObjectReference tmp = selection[i]
		tmp.SetLinkedRef(None, Copypasta_SelectionLink)
		WorkshopParent.RemoveObjectPUBLIC(tmp, workshop)
		tmp.Disable()
		tmp.Delete()
		i += 1
	EndWhile
	If (Copypasta_MSG_SelectionDeleted)
		Copypasta_MSG_SelectionDeleted.Show()
	EndIf
	isSelectionGrabbed = false
	isSelectionFrozen = false
	isCopiedSelection = false
	hasSelection = false
EndFunction

Function ClearSelection()
	TraceSelf(self, "ClearSelection", "")
	DeleteCarrier()
	ObjectReference[] selection = GetSelection()
	If (selection.Length <  1)
		return
	EndIf
	int i = 0
	While (i < selection.Length)
		selection[i].SetLinkedRef(None, Copypasta_SelectionLink)
		RemoveHighlight(selection[i])
		i += 1
	EndWhile
	If (Copypasta_MSG_SelectionCleared)
		Copypasta_MSG_SelectionCleared.Show()
	EndIf
	isSelectionGrabbed = false
	isSelectionFrozen = false
	isCopiedSelection = false
	hasSelection = false
EndFunction

Function FreezeSelection(bool abFreeze = true)
	TraceSelf(self, "FreezeSelection", abFreeze)
	ObjectReference helper = GetHelper()
	ObjectReference carrier = GetCarrier()
	If (abFreeze)
		AttachCarrier(false)
		If (Copypasta_MSG_SelectionFrozen)
			Copypasta_MSG_SelectionFrozen.Show()
		EndIf
		isSelectionFrozen = true
	Else
		AttachCarrier(true)
		If (Copypasta_MSG_SelectionDefrosted)
			Copypasta_MSG_SelectionDefrosted.Show()
		EndIf
		isSelectionFrozen = false
	EndIf
EndFunction

Function UnfreezeSelection()
	FreezeSelection(false)
EndFunction

Function ToggleFreezeSelection()
	FreezeSelection(!isSelectionFrozen)
EndFunction

Function UpdateSelection()
	hasSelection = true
	If (CountRefsLinkedToMe(Copypasta_SelectionLink) < 1)
		hasSelection = false
	EndIf
EndFunction

Function AddArrayToSelection(ObjectReference[] akRefs)
	int i = 0
	While (i < akRefs.Length)
		AddToSelection(akRefs[i])
		i += 1
	EndWhile
EndFunction

Function AddArrayToSelectionAsync(ObjectReference[] akRefs)
	ScriptObject selfScript = self.CastAs("Copypasta_v2:CopypastaScript")
	int i = 0
	While (i < akRefs.Length)
		Var[] params = new Var[2]
		params[0] = akRefs[i] as ObjectReference
		params[1] = false as bool		
		selfScript.CallFunctionNoWait("AddToSelection", params)
		i += 1
	EndWhile
EndFunction	

Function AddToSelection(ObjectReference akReference, bool allowCarrySelectCheck = true)
	If (Copypasta_CannotSelectList.HasForm(akReference.GetBaseObject()) == false) 
		akReference.SetMotionType(2)
		akReference.SetLinkedRef(Self, Copypasta_SelectionLink)
		TraceSelf(self, "OnGrabbedRefCancelled", akReference +" => Selected")
		AddHighlight(akReference)
		If (addCarriedObjectsToSelection && !waitingForGroupSelect && allowCarrySelectCheck)
			TraceSelf(self, "OnGrabbedRefCancelled", akReference +" => Selecting carried objects")
			ObjectReference[] carriedObjects = akReference.GetRefsLinkedToMe(WorkshopStackedItemParentKEYWORD)
			;Trace(carriedObjects)
			int i = 0
			While (i < carriedObjects.Length)
				; Safety check
				ObjectReference[] loopCheck = carriedObjects[i].GetRefsLinkedToMe(WorkshopStackedItemParentKEYWORD)
				int c = loopCheck.Find(akReference)
				;Trace(loopCheck + " : " + c)
				If (c < 0)
					AddToSelection(carriedObjects[i])
				Else
					AddToSelection(carriedObjects[i], false)
				EndIf
				i += 1
			EndWhile
		EndIf
		hasSelection = true
	EndIf
EndFunction

Function RemoveFromSelection(ObjectReference akReference, bool allowCarrySelectCheck = true)
	akReference.SetLinkedRef(None, Copypasta_SelectionLink)
	TraceSelf(self, "OnGrabbedRefCancelled", akReference +" => De-selected")
	RemoveHighlight(akReference)
	If (addCarriedObjectsToSelection && !waitingForGroupSelect && allowCarrySelectCheck)
		TraceSelf(self, "OnGrabbedRefCancelled", akReference +" => De-selecting carried objects")
		ObjectReference[] carriedObjects = akReference.GetRefsLinkedToMe(WorkshopStackedItemParentKEYWORD)
		int i = 0
		While (i < carriedObjects.Length)
			; Safety check
			ObjectReference[] loopCheck = carriedObjects[i].GetRefsLinkedToMe(WorkshopStackedItemParentKEYWORD)
			If (loopCheck.Find(akReference) < 0)
				RemoveFromSelection(carriedObjects[i])
			Else
				RemoveFromSelection(carriedObjects[i], false)
			EndIf
			i += 1
		EndWhile
	EndIf
EndFunction

bool groupSelectionInit = false

Function InitGroupSelection()
	TraceSelf(self, "InitGroupSelection", "")
	If (!groupSelectionInit)
		groupSelectionInit = true
		RegisterForRemoteEvent(WorkshopRef, "OnWorkshopObjectPlaced")
		ObjectReference[] allWorkshopItems = WorkshopRef.GetRefsLinkedToMe(WorkshopItemKeyword)
		int i = 0
		While (i < allWorkshopItems.Length)
			ObjectReference tmp = allWorkshopItems[i]
			If (!(tmp Is Actor))
				tmp.AddKeyword(Copypasta_SearchKeyword)
			EndIf
			i += 1
		EndWhile
	EndIf
EndFunction

Event ObjectReference.OnWorkshopObjectPlaced(ObjectReference akSender, ObjectReference akReference)
	If (!(akReference Is Actor))
		akReference.AddKeyword(Copypasta_SearchKeyword)
	EndIf
EndEvent

Function AddGroupSelectionToSelection()
	TraceSelf(self, "AddGroupSelectionToSelection", "")
	; If (!groupSelectionInit)
		; InitGroupSelection()
	; EndIf
	
	; Attributes
	float afSearchRadius   = 2000.0
	float afMarkerDistance = 200.0
	float afAngleIncrement = 10.0
	float afMovedPadding   = 0.05
	
	Actor aPlayerRef = Game.GetPlayer() as Actor
	; Markers used to turn the player
	ObjectReference initLookMarker = PlaceAtMe(Copypasta_DummyLookAtMarker)
	ObjectReference turnLookMarker = PlaceAtMe(Copypasta_DummyLookAtMarker)
	
	; TODO: This breaks player Activation of stuff when set to true.
	;		Make an implementation of moving the player with either TranslateTo or SnapIntoInteraction
	aPlayerRef.SetPlayerControls(false)
	float afZ = aPlayerRef.GetAngleZ()
	initLookMarker.MoveTo(aPlayerRef, Math.Sin(afZ) * afMarkerDistance, Math.Cos(afZ) * afMarkerDistance, 70.0)
	
	; Find all items to probably check
	;ObjectReference[] itemsToCheck = Self.FindAllReferencesWithKeyword(Copypasta_SearchKeyword, afSearchRadius)
	ObjectReference[] itemsToCheck = WorkshopRef.GetRefsLinkedToMe(WorkshopItemKeyword)
	TraceSelf(self, "AddGroupSelectionToSelection", "Found " + itemsToCheck.Length + " objects to check")
	int runs = Math.Ceiling(itemsToCheck.Length / 128.0) as int
	;Trace("Performing check in " + runs + " runs")
	int i = 0
	While (i < runs)
		int offset = i * 128
		int len = Math.Min(itemsToCheck.Length - offset, 128.0) as int
		float[] xPositions = new float[len]
		int j = 0
		;Trace("--- Run #" + (i+1) + " ---")
		While (j < len)
			int absIndex = j + offset
			ObjectReference tmp = itemsToCheck[absIndex]
			;Trace (tmp)
			;Trace("   Saving Object #" + (j+1) + "[" + (absIndex+1) + "]")
			;If (!(tmp.IsDisabled()))
			If (!tmp.IsDisabled() && !(tmp is Actor))
				xPositions[j] = tmp.GetPositionX()
				;Trace("... Saved")
			Else
				itemsToCheck[absIndex] = None
				;Trace("... Invalid")
			EndIf
			j += 1
		EndWhile
		afZ = aPlayerRef.GetAngleZ() + afAngleIncrement
		turnLookMarker.MoveTo(aPlayerRef, Math.Sin(afZ) * afMarkerDistance, Math.Cos(afZ) * afMarkerDistance, 70.0)
		aPlayerRef.SetLookAt(turnLookMarker, true)
		;Utility.Wait(0.5)
		int k = 0
		While (k < len)
			int absIndex = k + offset
			ObjectReference tmp = itemsToCheck[absIndex]
			If (tmp)
				;Trace("   Checking Object #" + (k+1) + "[" + (absIndex+1) + "]")
				If (Math.Abs(xPositions[k] - tmp.GetPositionX()) < afMovedPadding)
					;Trace("... Not moved")
					itemsToCheck[absIndex] = None
				; Else 
					; Trace("... Found!")
				EndIf
			EndIf
			k += 1
		EndWhile
		i += 1
	EndWhile
	aPlayerRef.SetLookAt(initLookMarker, true)
	Utility.Wait(1.0)
	aPlayerRef.ClearLookAt()
	aPlayerRef.SetPlayerControls(true)
	;int numFound = 0
	int j = 0
	While (j < itemsToCheck.Length)
		If (itemsToCheck[j] != None)
			;Trace("Adding #" + j + " to selection")
			AddToSelection(itemsToCheck[j])
			;numFound += 1
		EndIf
		j += 1
	EndWhile
	itemsToCheck = None
	TraceSelf(self, "AddGroupSelectionToSelection", "Done")
	initLookMarker.Disable()
	initLookMarker.Delete()
	turnLookMarker.Disable()
	turnLookMarker.Delete()
	waitingForGroupSelect = false
EndFunction

Function AddGroupSelectionToSelection2()
	TraceSelf(self, "AddGroupSelectionToSelection2", "")
	If (!groupSelectionInit)
		InitGroupSelection()
	EndIf
	
	Actor aPlayerRef = Game.GetPlayer() as Actor
	aPlayerRef.SetPlayerControls(false)
	
	float afRadius = 2000.0
	ObjectReference[] toAddToSelection = new ObjectReference[0]
	ObjectReference[] itemsToCheck = Self.FindAllReferencesWithKeyword(Copypasta_SearchKeyword, afRadius)
	int runs = Math.Ceiling(itemsToCheck.Length / 128.0)
	TraceSelf(self, "AddGroupSelectionToSelection2", "Checking " + itemsToCheck.Length + " objects in " + runs + " runs.")
	float padding = 1.0
	int i = 0
	While(i < runs)
		Trace("Run #" + (i+1))
		int offset = i * 128
		int len = Math.Min(itemsToCheck.Length - offset, 128.0) as int
		Trace("... Length " + len)
		float[] xPositions = new float[len]
		int j = 0
		While (j < len)
			ObjectReference tmp = itemsToCheck[j + i * 128]
			If (!tmp.IsDisabled())
				Trace("...Storing Item #" + j)
				xPositions[j] = tmp.GetPositionX()
				tmp.Disable()
				tmp.MoveTo(tmp, afXOffset = 5.0)
			EndIf
			j += 1
		EndWhile
		Utility.Wait(0.1)
		int k = 0
		While (k < len)
			ObjectReference tmp = itemsToCheck[k + i * 128]
			If (xPositions[k] != 0.0)
				Trace("...Checking Item #" + k)
				If (Math.Abs(xPositions[k] - tmp.GetPositionX()) > padding)
					tmp.MoveTo(tmp, afXOffset = -5.0)
				Else
					If (toAddToSelection.Length >= 128)
						AddArrayToSelectionAsync(toAddToSelection)
						toAddToSelection = new ObjectReference[0]
					EndIf
					toAddToSelection.Add(tmp)
				EndIf
				tmp.EnableNoWait()
			EndIf
			k += 1
		EndWhile
		i += 1
	EndWhile
	TraceSelf(self, "AddGroupSelectionToSelection2", "Found " + toAddToSelection.Length + " objects in Group-Selection")
	aPlayerRef.ClearLookAt()
	aPlayerRef.SetPlayerControls(true)
	int j = 0
	While (j < toAddToSelection.Length)
		AddToSelection(toAddToSelection[j])
		j += 1
	EndWhile
	waitingForGroupSelect = false
EndFunction

; ===============================================

; ################## Carrier #####################

Function DeleteCarrier()
	TraceSelf(self, "DeleteCarrier", "")
	ObjectReference carrier = GetLinkedRef(Copypasta_CarrierLink)
	If (carrier != None)
		Trace("... Deleting")
		carrier.Delete()
		Self.SetLinkedRef(None, Copypasta_CarrierLink)
	EndIf	
EndFunction

ObjectReference Function GetCarrier()
	If (GetLinkedRef(Copypasta_CarrierLink) == None)
		Return NewCarrier()
	EndIf
	Return GetLinkedRef(Copypasta_CarrierLink)
EndFunction

ObjectReference Function NewCarrier()
	TraceSelf(self, "NewCarrier", "")
	DeleteCarrier()
	ObjectReference	carrier = PlaceAtMe(Copypasta_Carrier, abInitiallyDisabled = true) ;PlaceAtNode("CarrierSpawnNode", Copypasta_Carrier, abInitiallyDisabled = true)
	carrier.SetScale(0.3) ; carrier.SetScale(0.1)
	carrier.EnableNoWait()
	Self.SetLinkedRef(carrier, Copypasta_CarrierLink)
	carrier.WaitFor3DLoad()
	return carrier
EndFunction

Function AttachCarrier(bool abAttach = true)
	ObjectReference carrier = GetCarrier()
	If (abAttach)
		ObjectReference helper = GetHelper()
		If (!carrier.IsDisabled())
			carrier.Disable()
		EndIf
		helper.Disable()
		carrier.MoveTo(GetHelper(), afZOffset = 25.0, abMatchRotation = false) ;carrier.MoveToNode(Self, "CarrierFinishedNode")
		helper.Enable()
		carrier.AttachTo(helper)
		carrier.Enable()
	Else
		carrier.Disable()
		carrier.AttachTo(Self)
	EndIf	
EndFunction

; ====================================================

; ################## Helper #####################

ObjectReference Function PlaceHelper()
	ObjectReference	helper = PlaceAtMe(Copypasta_Helper, abInitiallyDisabled = true) ;PlaceAtNode("HelperNode", Copypasta_Helper, abInitiallyDisabled = true)
	helper.MoveTo(self, afZOffset = 56.0)
	TraceSelf(self, "PlaceHelper", helper)
	helper.SetScale(0.3); helper.SetScale(0.1)
	helper.EnableNoWait()
	Self.SetLinkedRef(helper, Copypasta_HelperLink)
	helper.SetLinkedRef(self, WorkshopStackedItemParentKEYWORD)
	helper.WaitFor3DLoad()
	return helper
EndFunction

ObjectReference Function GetHelper()
	If (GetLinkedRef(Copypasta_HelperLink) == None)
		Return PlaceHelper()
	EndIf
	Return GetLinkedRef(Copypasta_HelperLink)
EndFunction

Function UpdateHelperPosition()
	ObjectReference helper = GetHelper()
	helper.Disable()
	helper.MoveTo(self, afZOffset = 56.0)
	helper.SetAngle(0.0, 0.0, helper.GetAngleZ())
	helper.Enable()
	isRotationLocked = false
EndFunction

Function DeleteHelper()
	ObjectReference	helper = GetLinkedRef(Copypasta_HelperLink)
	TraceSelf(self, "DeleteHelper", helper)
	If (helper)
		SetLinkedRef(None, Copypasta_HelperLink)
		helper.Delete()
	EndIf
EndFunction

; ====================================================

; #################### Prevent Fall Damage ###############


Function PreventDamage(bool prevent = true)
	ObjectReference playerRef = Game.GetPlayer()
	If (prevent)
		RegisterForAnimationEvent(playerRef, "JumpDown")
		StartTimer(PreventDamageFailsafeDuration, PreventDamageFailsafeTimerID)
		;SetGodMode(true)
		(playerRef as Actor).SetProtected(false)
	Else
		CancelTimer(PreventDamageFailsafeTimerID)
		UnregisterForAnimationEvent(playerRef, "JumpDown")
		;SetGodMode(false)
		(playerRef as Actor).SetProtected(false)
	EndIf
	TraceSelf(self, "PreventDamage", prevent)
EndFunction

; ====================================================

; ################### Object Highlighting ###############

Function AddHighlight(ObjectReference akReference)
	Copypasta_HighlightShader.Play(akReference)
EndFunction

Function RemoveHighlight(ObjectReference akReference)
	Copypasta_HighlightShader.Stop(akReference)
EndFunction

; ====================================================
		
; ############ APS (Angle Position Scale) ##############

Struct APS
	float X
	float Y
	float Z
	float aX
	float aY
	float aZ
	float scale
EndStruct

APS Function GetAPS(ObjectReference akReference)
	APS temp = new APS
	temp.X = akReference.GetPositionX()
	temp.Y = akReference.GetPositionY()
	temp.Z = akReference.GetPositionZ()
	temp.aX = akReference.GetAngleX()
	temp.aY = akReference.GetAngleY()
	temp.aZ = akReference.GetAngleZ()
	temp.scale = akReference.GetScale()
	return temp
EndFunction

APS Function GetDiffAPS(APS a1, APS a2)
	APS diff = new APS
	diff.X = a2.X - a1.X
	diff.Y = a2.Y - a1.Y
	diff.Z = a2.Z - a1.Z
	diff.aX = a2.aX - a1.aX
	diff.aY = a2.aY - a1.aY
	diff.aZ = a2.aZ - a1.aZ
	diff.scale = a2.scale - a1.scale
	return diff
EndFunction

Function SetAPS(ObjectReference akReference, APS ap)
	akReference.SetPosition(ap.X, ap.Y, ap.Z)
	akReference.SetAngle(ap.aX, ap.aY, ap.aZ)
	akReference.SetScale(ap.scale)
EndFunction

Function MoveToAPS(ObjectReference akReference, APS ap)
	akReference.SetPosition(ap.X, ap.Y, ap.Z)
	akReference.SetAngle(ap.aX, ap.aY, ap.aZ)
EndFunction

; ===============================================================

Event OnWorkshopObjectPlaced(ObjectReference akReference)
	TraceSelf(self, "OnWorkshopObjectPlaced", "")
	; Check to see if this settlement already has a Copypasta
	ObjectReference[] linkedRefs = akReference.GetRefsLinkedToMe(WorkshopItemKeyword)
	int i = 0
	While (i < linkedRefs.Length)
		If (linkedRefs[i] is Copypasta_v2:CopypastaScript && linkedRefs[i] != self)
			linkedRefs[i].MoveTo(Self)
			(linkedRefs[i] as Copypasta_v2:CopypastaScript).ClearSelection()
			(linkedRefs[i] as Copypasta_v2:CopypastaScript).UpdateHelperPosition()
			self.SetLinkedRef(None, WorkshopItemKeyword)
			self.Disable()
			self.Delete()
			return
		EndIf
		i += 1
	EndWhile
	
	WorkshopRef = akReference
	listenForSelections = ShouldStartActive
	allowHandleSelection = ShouldStartHandleSelectionOnGrab
	grabSelectionOnGrab = ShouldStartGrabSelectionOnGrab
	addGroupSelectionsToSelection = ShouldStartAddGroupSelectToSelection
	addCarriedObjectsToSelection = ShouldAddCarriedObjectsToSelection
	useQuickCopy = ShouldStartUseQuickCopy
	isInWorkshopMode = true
	isInitialized = true
	InitGroupSelection()
	OnLoad()
	If (listenForSelections)
		PrepareWorkshopMode(true)
	EndIf
EndEvent

Event OnWorkshopObjectDestroyed(ObjectReference akReference)
	; Do clean-up, do same as OnUnload
	TraceSelf(self, "OnWorkshopObjectDestroyed", "Calling OnUnload")
	ObjectReference[] refsToReset = akReference.GetRefsLinkedToMe(WorkshopItemKeyword)
	int i = 0
	While (i < refsToReset.Length)
		refsToReset[i].ResetKeyword(Copypasta_SearchKeyword)
		i += 1
	EndWhile
	OnUnload()
EndEvent

Event OnLoad()
	TraceSelf(self, "OnLoad", isInitialized)
	; If (!isSelfGrabbed && isInitialized && !waitingForGroupSelect)
		; TraceSelf(self, "OnLoad", "Registering for WorkshopMenu and PauseMenu")
		; RegisterForMenuOpenCloseEvent("WorkshopMenu")
		; RegisterForMenuOpenCloseEvent("PauseMenu")
		; WorkshopRef = GetLinkedRef(WorkshopItemKeyword)
		; PlaceHelper()
	; EndIf
	TraceSelf(self, "OnLoad", "Registering for WorkshopMenu and PauseMenu")
	If (isInitialized)
		RegisterForMenuOpenCloseEvent("WorkshopMenu")
		WorkshopRef = GetLinkedRef(WorkshopItemKeyword)
		PlaceHelper()
		GotoState("Waiting")
	EndIf
EndEvent

Event OnUnload()
	GotoState("")
	CancelTimer(AddToSelectionFailsafeTimerID)
	CancelTimer(WaitBusyFailsafeTimerID)
	UnregisterForAllEvents()
	ClearSelection()
	CurrentObject = None
	WorkshopRef = None
	DeleteHelper()
	If (myLayer != None)
		myLayer.Delete()
		myLayer = None
	EndIf
EndEvent

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
	If (asMenuName == "WorkshopMenu")
		If (listenForSelections)
			PrepareWorkshopMode(abOpening)
		EndIf
		isInWorkshopMode = abOpening
	ElseIf (listenForSelections)
		If (asMenuName == "PauseMenu")
			If (abOpening && isSelfGrabbed)
				If (grabSelectionOnGrab && GetSelection().Length > 0 || waitingForGroupSelect)
					StartPauseWorkingTimer(PauseWaitMenuTimerDuration, PauseWaitMenuTimerID)
				Else
					ShowMenu()
				EndIf
			ElseIf (!abOpening && !settingsMenuActive && !rotationMenuActive)
				CancelPauseWorkingTimer(PauseWaitMenuTimerID)
				OnPaused()
			EndIf
		EndIf
	EndIf
EndEvent

Event OnTimer(int aiTimerID)
	If (aiTimerID == AddToSelectionFailsafeTimerID)
		If (WorkshopRef != None)
			TraceSelf(self, "OnTimer", "AddToSelectionFailsafeTimer ran out")
			UnregisterForRemoteEvent(WorkshopRef, "OnWorkshopObjectDestroyed")
			If (CurrentObject != None) 
				CurrentObject.SetLinkedRef(WorkshopRef, WorkshopItemKeyword)
			EndIf
		EndIf
		CurrentObject = None
	ElseIf (aiTimerID == WaitBusyFailsafeTimerID)
		TraceSelf(self, "OnTimer", "WaitBusyFailsafeTimerID ran out")
		GotoState("Waiting")
	ElseIf (aiTimerID == PauseWaitMenuTimerID)
		If (Game.IsMovementControlsEnabled())
			ShowMenu()
		Else
			ShowRotationMenu()
		EndIf
	ElseIf (aiTimerID == PreventDamageFailsafeTimerID)
		PreventDamage(false)
	ElseIf (aiTimerID == WaitingForGroupSelectTimerID)
		waitingForGroupSelect = false
		;grabSelectionOnGrab = true
	EndIf
EndEvent

Event ObjectReference.OnWorkshopObjectGrabbed(ObjectReference akSender, ObjectReference akReference)
	If (!Copypasta_CannotSelectList.HasForm(akReference.GetBaseObject()))
		TraceSelf(self, "ObjectReference.OnWorkshopObjectGrabbed", akReference)
		CurrentObject = akReference
		RegisterForRemoteEvent(akSender, "OnWorkshopObjectDestroyed")
		CurrentObject.SetLinkedRef(None, WorkshopItemKeyword) ; to detect Cancel-move
		If (SelectWithPause)
			hasBeenPaused = false
		Else
			StartTimer(AddToSelectionFailsafeDuration, AddToSelectionFailsafeTimerID)
		EndIf
		UpdateSelection()
	EndIf
EndEvent

Event ObjectReference.OnWorkshopObjectMoved(ObjectReference akSender, ObjectReference akReference)
	If (akReference == CurrentObject)
		TraceSelf(self, "ObjectReference.OnWorkshopObjectMoved", akReference)
		CancelTimer(AddToSelectionFailsafeTimerID)
		; were we moved or cancelled
		If (SelectWithPause && hasBeenPaused)
			OnGrabbedRefPaused(akReference)
		EndIf
		If (CurrentObject.GetLinkedRef(WorkshopItemKeyword) == None)
			; Cancelled
			CurrentObject.SetLinkedRef(WorkshopRef, WorkshopItemKeyword)
			If (!SelectWithPause)
				OnGrabbedRefCancelled(akReference)
			EndIf
		Else
			OnGrabbedRefMoved(akReference)
		EndIf
		CurrentObject = None
		UpdateSelection()
	ElseIf (!Copypasta_CannotSelectList.HasForm(akReference.GetBaseObject()))
		If (addGroupSelectionsToSelection && !grabSelectionOnGrab && waitingForGroupSelect)
			StartTimer(WaitingForGroupSelectDuration, WaitingForGroupSelectTimerID)
			OnGrabbedRefCancelled(akReference)
		EndIf
	EndIf
EndEvent

Event ObjectReference.OnWorkshopObjectDestroyed(ObjectReference akSender, ObjectReference akReference)
	If (akReference == CurrentObject)
		TraceSelf(self, "ObjectReference.OnWorkshopObjectDestroyed", akReference)
		CancelTimer(AddToSelectionFailsafeTimerID)
		UnregisterForRemoteEvent(akSender, "OnWorkshopObjectDestroyed")
		CurrentObject = None
		UpdateSelection()
	EndIf
EndEvent

Event OnAnimationEvent(ObjectReference akSource, string asEventName)
	If (akSource == Game.GetPlayer())
		If (asEventName == "JumpUp")
			If (isSelfGrabbed)
				If (Self.IsDisabled())
					Self.Enable()
				Else
					Self.Disable()
					If (!ShouldCopy && !isSelectionFrozen)
						AttachCarrier(true)
					EndIf
				EndIf
				(akSource as Actor).PlayIdleAction(ActionLand)
			EndIf
		ElseIf (asEventName == "JumpDown")
			PreventDamage(false)
		ElseIf (asEventName == "SyncRight")
			RotationSetup(false)
		EndIf
	EndIf
EndEvent

; ############### Special pause working timer ##################

Int[] currentTimers

Function WaitTimer(float afInterval, int aiTimerID)
	TraceSelf(self, "WaitTimer", aiTimerID)
	Utility.WaitMenuMode(afInterval)
	int i = currentTimers.Find(aiTimerID)
	If (i != -1)
		currentTimers.Remove(i)
		OnTimer(aiTimerID)
	EndIf
EndFunction

Function StartPauseWorkingTimer(float afInterval, int aiTimerID = 0, bool leaveAlone = false)
	TraceSelf(self, "StartPauseWorkingTimer", aiTimerID)
	ScriptObject selfScript = self.CastAs("Copypasta_v2:CopypastaScript")
	If (selfScript)
		If (currentTimers == None)
			currentTimers = new Int[0]
		EndIf
		currentTimers.Add(aiTimerID)
		Var[] params = new Var[2]
		params[0] = afInterval as float
		params[1] = aiTimerID as int
		CallFunctionNoWait("WaitTimer", params)
	EndIf
EndFunction

Function CancelPauseWorkingTimer(int aiTimerID = 0)
	TraceSelf(self, "CancelPauseWorkingTimer", aiTimerID)
	int i = currentTimers.Find(aiTimerID)
	If (i != -1)
		currentTimers.Remove(i)
	EndIf
EndFunction
