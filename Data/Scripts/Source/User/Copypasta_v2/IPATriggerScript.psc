ScriptName Copypasta_v2:IPATriggerScript extends ObjectReference

Copypasta_v2:IPAQuestScript Property ImmediatePAQuest Auto Const

Event OnWorkshopObjectPlaced(ObjectReference akReference)
	Trigger()
EndEvent

Function Trigger()
	ImmediatePAQuest.ActivatePA(self)
	Utility.Wait(0.1)
	Game.GetPlayer().AddItem(Game.GetCaps(), 1, True)
	Disable()
	Delete()
EndFunction	
