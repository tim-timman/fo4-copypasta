ScriptName Copypasta_v2:HotfixScript Hidden

Function RestorePlayerActivation() Global
	; Airplane seat form
	Form seat = Game.GetFormFromFile(0x149E92,"Fallout4.esm")
	
	ObjectReference  playerRef = Game.GetPlayer()
	Actor aPlayerRef = playerRef as Actor
	aPlayerRef.SetPlayerControls(false)
	
	ObjectReference seatRef = playerRef.PlaceAtMe(seat)
	seatRef.SetAngle(0.0, 0.0, 0.0)
	If (seatRef.WaitFor3DLoad())
		seatRef.Activate(playerRef)
	EndIf
	Utility.Wait(1.0)
	seatRef.Disable()
	Utility.Wait(1.0)
	seatRef.Delete()
EndFunction
