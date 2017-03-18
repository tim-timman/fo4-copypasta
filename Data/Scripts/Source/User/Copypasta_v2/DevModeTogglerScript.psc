ScriptName Copypasta_v2:DevModeTogglerScript extends ObjectReference

Float Property DevModeAccessTimeout = 2.0 Auto Const
GlobalVariable Property Copypasta_DevActive Auto Const
Message Property Copypasta_MSG_DevModeEnabled Auto Const
Message Property Copypasta_MSG_DevModeDisabled Auto Const

int devModeAccessTimerID = 14

int activationCount = 0

Event OnActivate(ObjectReference akReference)
	If (akReference == Game.GetPlayer())
		activationCount += 1
		If (Copypasta_DevActive.GetValueInt() == 0)
			If (activationCount >= 7)
				Copypasta_MSG_DevModeEnabled.Show()
				Copypasta_DevActive.SetValueInt(1)
				activationCount = 0
				CancelTimer(devModeAccessTimerID)
			Else
				StartTimer(DevModeAccessTimeout, devModeAccessTimerID)
			EndIf
		Else
			If (activationCount >= 3)
				Copypasta_MSG_DevModeDisabled.Show()
				Copypasta_DevActive.SetValueInt(0)
				activationCount = 0
				CancelTimer(devModeAccessTimerID)
			Else
				StartTimer(DevModeAccessTimeout, devModeAccessTimerID)
			EndIf
		EndIf
	EndIf	
EndEvent

Event OnTimer(int aiTimerID)
	If (aiTimerID == devModeAccessTimerID)
		activationCount = 0
	EndIf
EndEvent
