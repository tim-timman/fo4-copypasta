ScriptName Copypasta_v2:HotfixerObjectScript extends ObjectReference

import Utility

Message Property Copypasta_MB_HotfixMenu Auto Const
Message Property Copypasta_MB_HotfixApplied Auto Const
Message Property Copypasta_MB_HotfixFailed Auto Const
String Property Copypasta_HotfixScriptName = "Copypasta_v2:HotfixScript" Auto Const
Keyword Property Copypasta_ConditionalPlayerLink Auto Const

bool Op_0 = true Conditional
bool Op_1 = false Conditional
bool Op_2 = false Conditional
bool Op_3 = false Conditional
bool Op_4 = false Conditional
bool Op_5 = false Conditional
bool Op_6 = false Conditional
bool Op_7 = false Conditional
bool Op_8 = false Conditional
bool Op_9 = false Conditional
bool Op_a = false Conditional
bool Op_b = false Conditional
bool Op_c = false Conditional
bool Op_d = false Conditional
bool Op_e = false Conditional
bool Op_f = false Conditional
bool Op_Prev = false Conditional
bool Op_Next = false Conditional

Function ApplyHotfix(string asHotfixName)
	If (CallGlobalFunction(Copypasta_HotfixScriptName, asHotfixName, new Var[0]) as bool)
		Copypasta_MB_HotfixApplied.Show()
	Else	
		Copypasta_MB_HotfixFailed.Show()
	EndIf
EndFunction

Function ShowMenu()
	If (Copypasta_MB_HotfixMenu)
		ObjectReference playerRef = Game.GetPlayer()
		playerRef.SetLinkedRef(self, Copypasta_ConditionalPlayerLink)
		bool exit = false
		While (!exit || !Game.IsPluginInstalled("Copypasta.esp"))
			int res = Copypasta_MB_HotfixMenu.Show()
			
			;### RestorePlayerActivation()
			If (res == 0)
				ApplyHotfix("RestorePlayerActivation")
			;### <function>
			ElseIf (res == 1)
				; CallGlobalFunctionNoWait(Copypasta_HotfixScriptName, "DoNothing", new Var[0])
			;### <function>
			ElseIf (res == 2)
				; CallGlobalFunctionNoWait(Copypasta_HotfixScriptName, "DoNothing", new Var[0])
			;### <function>
			ElseIf (res == 3)
				; CallGlobalFunctionNoWait(Copypasta_HotfixScriptName, "DoNothing", new Var[0])
			;### <function>
			ElseIf (res == 4)
				; CallGlobalFunctionNoWait(Copypasta_HotfixScriptName, "DoNothing", new Var[0])
			;### <function>
			ElseIf (res == 5)
				; CallGlobalFunctionNoWait(Copypasta_HotfixScriptName, "DoNothing", new Var[0])
			;### <function>
			ElseIf (res == 6)
				; CallGlobalFunctionNoWait(Copypasta_HotfixScriptName, "DoNothing", new Var[0])
			;### <function>
			ElseIf (res == 7)
				; CallGlobalFunctionNoWait(Copypasta_HotfixScriptName, "DoNothing", new Var[0])
			;### <function>
			ElseIf (res == 8)
				; CallGlobalFunctionNoWait(Copypasta_HotfixScriptName, "DoNothing", new Var[0])
			;### <function>
			ElseIf (res == 9)
				; CallGlobalFunctionNoWait(Copypasta_HotfixScriptName, "DoNothing", new Var[0])
			;### <function>
			ElseIf (res == 10)
				; CallGlobalFunctionNoWait(Copypasta_HotfixScriptName, "DoNothing", new Var[0])
			;### <function>
			ElseIf (res == 11)
				; CallGlobalFunctionNoWait(Copypasta_HotfixScriptName, "DoNothing", new Var[0])
			;### <function>
			ElseIf (res == 12)
				; CallGlobalFunctionNoWait(Copypasta_HotfixScriptName, "DoNothing", new Var[0])
			;### <function>
			ElseIf (res == 13)
				; CallGlobalFunctionNoWait(Copypasta_HotfixScriptName, "DoNothing", new Var[0])
			;### <function>
			ElseIf (res == 14)
				; CallGlobalFunctionNoWait(Copypasta_HotfixScriptName, "DoNothing", new Var[0])
			;### <function>
			ElseIf (res == 15)
				; CallGlobalFunctionNoWait(Copypasta_HotfixScriptName, "DoNothing", new Var[0])
			;%%% Show Prev Menu
			ElseIf (res == 16)
				; TODO: Implement Show Prev Menu
			;%%% Show Next Menu
			ElseIf (res == 17)
				; TODO: Implement Show Next Menu
			Else
				exit = true
			EndIf
		EndWhile
		playerRef.SetLinkedRef(None, Copypasta_ConditionalPlayerLink)
	EndIf
	Utility.Wait(1.0)
	Disable()
	Delete()
EndFunction

Event OnInit()
	RegisterForAnimationEvent(Game.GetPlayer(), "JumpUp")
	StartTimer(1.0, 0)
EndEvent

Event OnTimer(int aiTimerID)
	If (aiTimerID == 0)
		UnregisterForAllEvents()
		Disable()
		Delete()
	EndIf
EndEvent

Event OnAnimationEvent(ObjectReference akSource, string asEventName)
	Debug.Trace(asEventName)
	If (asEventName == "JumpUp")
		CancelTimer(0)
		UnregisterForAllEvents()
		Utility.Wait(1.0)
		ShowMenu()
	EndIf
EndEvent
