ScriptName Copypasta_v2:CopypastaExtensionFunctions Native Hidden

Import Game
Import Debug

float Function SelectNumber(float init, float min, float max, float default)
	float val = init
	If (IsPluginInstalled("Copypasta.esp"))
		Message msg = GetFormFromFile(0x8996, "Copypasta.esp") as Message
		If (msg != None)
			bool exit = false
			While (!exit)
				int res = msg.Show(val)
				If (res == 0)
					val += 0.5
				ElseIf (res == 1)
					val -= 0.5
				ElseIf (res == 2)
					val += 1.0
				ElseIf (res == 3)
					val -= 1.0
				ElseIf (res == 4)
					val += 10.0
				ElseIf (res == 5)
					val -= 10.0
				ElseIf (res == 6)
					val = init
				ElseIf (res == 7)
					val = default
				ElseIf (res == 8)
					exit = true
					return val
				Else
					exit = true
					return -999999.0
				EndIf
			EndWhile
		EndIf
	EndIf
	return -999999.0
EndFunction
			