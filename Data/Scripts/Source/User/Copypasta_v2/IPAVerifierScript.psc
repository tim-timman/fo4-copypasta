ScriptName Copypasta_v2:IPAVerifierScript extends ObjectReference

Event OnWorkshopObjectPlaced(ObjectReference akReference)
	Utility.Wait(0.1)
	Game.GetPlayer().AddItem(Game.GetCaps(), 1, True)
	Disable()
	Delete()
EndEvent
