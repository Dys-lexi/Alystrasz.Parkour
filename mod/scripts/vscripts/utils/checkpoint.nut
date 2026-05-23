// global function PK_SpawnCheckpoints
global function initcheckpoints

/**
 * This uses the global checkpoints list to create the actual checkpoint entities.
 * Checkpoints entities will be created starting from the second entity, the first
 * one being a start trigger (does not need the checkpoint visual); last entry will
 * also not be spawned as a checkpoint, but as a finish trigger.
 **/


void function initcheckpoints(){

	AddCallback_OnClientConnected( spawncheckpointsforplayerwhatcouldgowrong )
	// AddCallback_OnPlayerDisconnected(removetheircheckpoints)
	
}

void function spawncheckpointsforplayerwhatcouldgowrong(entity player){
	thread threadedspawncheckpoints(player)
	Chat_ServerPrivateMessage(player,"[38;5;189mParkour got updated! here are some cool things",false,false)
	Chat_ServerPrivateMessage(player,"[38;5;219mlistroutes[110m/[38;5;219mlr[110m - list routes on current map",false,false)
	Chat_ServerPrivateMessage(player,"[38;5;219mchangeroute[110m/[38;5;219mcr[110m - change your current active route",false,false)
	Chat_ServerPrivateMessage(player,"[38;5;219mreload[110m - reload the current active map",false,false)
	Chat_ServerPrivateMessage(player,"[38;5;219msave[110m/[38;5;219msa[110m - save a custom start spot",false,false)
	Chat_ServerPrivateMessage(player,"[38;5;219mreset[110m/[38;5;219mre[110m - reset your custom start spot",false,false)
	

	
}
// void function removetheircheckpoints(entity player){
// 	PK_checkpointEntities[player] <- [] 
// }


void function threadedspawncheckpoints(entity player){
	player.EndSignal( "OnDestroy" ) // I'm pretttty sure this is only fired if you leave, but not 100
	if (!fetchedall){
		print("wqidmwqidmwqidw")
	GetEnt( "worldspawn" ).WaitSignal("Pkloadedconfig")}
	selectedrouteforplayers[player] <- returnroutes()[0]
	while (true) {
		
		

		waitthread PK_SpawnCheckpointsforeach(player,PK_checkpoints[selectedrouteforplayers[player]], whyoneartharecheckpointsnotstoredwiththerestorsomethingandthenthatwiththemap[selectedrouteforplayers[player]].startMins, whyoneartharecheckpointsnotstoredwiththerestorsomethingandthenthatwiththemap[selectedrouteforplayers[player]].startMaxs, whyoneartharecheckpointsnotstoredwiththerestorsomethingandthenthatwiththemap[selectedrouteforplayers[player]].endMins, whyoneartharecheckpointsnotstoredwiththerestorsomethingandthenthatwiththemap[selectedrouteforplayers[player]].endMaxs)
		array<entity> props = SpawnEntities(player,whyoneartharecheckpointsnotstoredwiththerestorsomethingandthenthatwiththemap[selectedrouteforplayers[player]].entities)
		array<entity> ziplines = SpawnZiplines(player,whyoneartharecheckpointsnotstoredwiththerestorsomethingandthenthatwiththemap[selectedrouteforplayers[player]].ziplines)
		// print("wqodwq,fwqf")
		entity marvin = PK_SpawnAmbientMarvin(player,robots[selectedrouteforplayers[player]].origin, robots[selectedrouteforplayers[player]].angles, robots[selectedrouteforplayers[player]].talkableRadius, robots[selectedrouteforplayers[player]].animation)
		player.WaitSignal("Iwanttochangearoute")
		waitthread PK_OnPlayerConnectedbutnotreal(player)
		// printt("hereeee")
		marvin.Destroy()
		foreach(checkpoint in PK_checkpointEntities[player]){
			checkpoint.Destroy()
		}

		foreach(checkpoint in props){
			checkpoint.Destroy()
		}

		foreach(checkpoint in ziplines){
			checkpoint.Destroy()
		}
	}



}

array<entity> function SpawnZiplines(entity player, array coordinates )
{
	array<entity> zips
	foreach (c in coordinates)
	{
        array zipline = expect array(c)
        array startCoordinates = expect array(zipline[0])
        array endCoordinates = expect array(zipline[1])
		
		zips.extend ( CreateZiplinew( player, PK_ArrayToFloatVector(startCoordinates), PK_ArrayToFloatVector(endCoordinates) ))
		
	}
	return zips
}

array<entity> function CreateZiplinew(entity player, vector startPos, vector endPos )
{
	string startpointName = UniqueString( "rope_startpoint" )
	string endpointName = UniqueString( "rope_endpoint" )
	array <entity> weee
	entity rope_start = CreateEntity( "move_rope" )
	SetTargetName( rope_start, startpointName )
	rope_start.kv.NextKey = endpointName
	rope_start.kv.MoveSpeed = 64
					rope_start.SetOwner( player )
			rope_start.kv.VisibilityFlags = ENTITY_VISIBLE_TO_OWNER
	rope_start.kv.Slack = 25
	rope_start.kv.Subdiv = "2"
	rope_start.kv.Width = "2"
	rope_start.kv.Type = "0"
	rope_start.kv.TextureScale = "1"
	rope_start.kv.RopeMaterial = "cable/zipline.vmt"
	rope_start.kv.PositionInterpolator = 2
	rope_start.kv.Zipline = "1"
	rope_start.kv.ZiplineAutoDetachDistance = "150"
	rope_start.kv.ZiplineSagEnable = "0"
	rope_start.kv.ZiplineSagHeight = "50"
	rope_start.SetOrigin( startPos )
	weee.append(rope_start)
	entity rope_end = CreateEntity( "keyframe_rope" )
	SetTargetName( rope_end, endpointName )
	rope_end.kv.MoveSpeed = 64
	rope_end.kv.Slack = 25
	rope_end.kv.Subdiv = "2"
	rope_end.kv.Width = "2"
					rope_end.SetOwner( player )
			rope_end.kv.VisibilityFlags = ENTITY_VISIBLE_TO_OWNER
	rope_end.kv.Type = "0"
	rope_end.kv.TextureScale = "1"
	rope_end.kv.RopeMaterial = "cable/zipline.vmt"
	rope_end.kv.PositionInterpolator = 2
	rope_end.kv.Zipline = "1"
	rope_end.kv.ZiplineAutoDetachDistance = "150"
	rope_end.kv.ZiplineSagEnable = "0"
	rope_end.kv.ZiplineSagHeight = "50"
	rope_end.SetOrigin( endPos )

	DispatchSpawn( rope_start )
	DispatchSpawn( rope_end )
	weee.append(rope_end)
	return weee
}

array<entity> function SpawnEntities(entity player,array<MapEntity> entities)
{
		array<entity> created
        foreach(obj in entities)
        {
            entity prop = CreateEntity( "prop_script" )
            prop.SetValueForModelKey( StringToAsset( obj.model_name ) )
            prop.SetOrigin( obj.coordinates )
            prop.SetAngles( obj.angles )
				prop.SetOwner( player )
			// prop.kv.VisibilityFlags = ENTITY_VISIBLE_TO_OWNER
            prop.kv.modelscale = obj.scale
			prop.kv.solid = SOLID_VPHYSICS
			// prop.kv.CollisionGroup = TRACE_COLLISION_GROUP_NONE
            prop.kv.fadedist = -1
            prop.kv.renderamt = 255
            prop.kv.rendercolor = "255 255 255"
            // prop.kv.solid = 6
            ToggleNPCPathsForEntity( prop, false )
            prop.SetAIObstacle( true )
            prop.SetTakeDamageType( DAMAGE_NO )
            prop.SetScriptPropFlags( SPF_BLOCKS_AI_NAVIGATION | SPF_CUSTOM_SCRIPT_3 )
            prop.AllowMantle()
            DispatchSpawn( prop )

            if ( obj.hidden )
            {
                prop.Hide()
            }
			created.append(prop)
        }
		return created
    
}

void function PK_SpawnCheckpointsforeach(entity targetplayer, array <vector> checkpoints, vector startMins, vector startMaxs, vector endMins, vector endMaxs)
{
	int checkpointsCount = checkpoints.len()-1
	array<entity> PK_checkpointEntitiesoutput

	foreach (int index, vector checkpoint in checkpoints)
	{
		if (index == 0)
		{
			thread SpawnStartTrigger(PK_checkpointEntitiesoutput, checkpoints,targetplayer, startMins, startMaxs )
		}
		else if (index == checkpoints.len()-1)
		{
			PK_checkpointEntitiesoutput.append( SpawnEndTrigger(checkpoints, targetplayer,checkpoint, endMins, endMaxs ) )
		}
		else
		{
			entity checkpoint = CreateCheckpoint(targetplayer,checkpoint, void function (entity player): (index, checkpointsCount,PK_checkpointEntitiesoutput) {
				PK_PlayerStats pStats = PK_localStats[player.GetPlayerName()]

				// Only update player info if their currentCheckpoint index is the previous one!
				if (pStats.isRunning && !pStats.isResetting && pStats.currentCheckpoint == index-1)
				{
					if (PK_checkpointEntitiesoutput.len()  > index){
						// discordlogs`endmessage("I tried to be pretty and pink")
					PK_checkpointEntitiesoutput[index].kv.rendercolor = nextcheckpoint // Ig if the compelted don't need next to be red
					PK_checkpointEntitiesoutput[index-1].kv.rendercolor = completedcheckpoint
					}
					// pStats.checkpointPassages.append( player.GetOrigin() )	// Saves player location+angles when checkpoint is reached
					// pStats.checkpointAngles.append( player.GetAngles() )
					pStats.currentCheckpoint = index						// Updates player's last reached checkpoint
					Remote_CallFunction_NonReplay( 							// Send player's client next checkpoint location, for it to be RUI displayed
						player,
						"ServerCallback_PK_UpdateNextCheckpointMarker",
						PK_checkpointEntitiesoutput[index].GetEncodedEHandle(),
						index,
						checkpointsCount
					)
					EmitSoundOnEntityOnlyToPlayer( player, player, "Burn_Card_Map_Hack_Radar_Pulse_V1_1P" )
				}
			})
			PK_checkpointEntitiesoutput.append( checkpoint )
		}
	}
	PK_checkpointEntities[targetplayer] <- PK_checkpointEntitiesoutput
}
// void function PK_SpawnCheckpoints( vector startMins, vector startMaxs, vector endMins, vector endMaxs )
// {
// 	int checkpointsCount = PK_checkpoints.len()-1

// 	foreach (int index, vector checkpoint in PK_checkpoints)
// 	{
// 		if (index == 0)
// 		{
// 			thread SpawnStartTrigger( startMins, startMaxs )
// 		}
// 		else if (index == PK_checkpoints.len()-1)
// 		{
// 			PK_checkpointEntities.append( SpawnEndTrigger( checkpoint, endMins, endMaxs ) )
// 		}
// 		else
// 		{
// 			entity checkpoint = CreateCheckpoint(checkpoint, void function (entity player): (index, checkpointsCount) {
// 				PK_PlayerStats pStats = PK_localStats[player.GetPlayerName()]

// 				// Only update player info if their currentCheckpoint index is the previous one!
// 				if (pStats.isRunning && !pStats.isResetting && pStats.currentCheckpoint == index-1)
// 				{
// 					pStats.checkpointPassages.append( player.GetOrigin() )	// Saves player location+angles when checkpoint is reached
// 					pStats.checkpointAngles.append( player.GetAngles() )
// 					pStats.currentCheckpoint = index						// Updates player's last reached checkpoint
// 					Remote_CallFunction_NonReplay( 							// Send player's client next checkpoint location, for it to be RUI displayed
// 						player,
// 						"ServerCallback_PK_UpdateNextCheckpointMarker",
// 						PK_checkpointEntities[index].GetEncodedEHandle(),
// 						index,
// 						checkpointsCount
// 					)
// 					EmitSoundOnEntityOnlyToPlayer( player, player, "Burn_Card_Map_Hack_Radar_Pulse_V1_1P" )
// 				}
// 			})
// 			PK_checkpointEntities.append( checkpoint )
// 		}
// 	}
// }



/**
 * This method spawns a checkpoint on the map, which by default has a green bubble model.
 * The second argument is a callback that is summoned each time a player enters the
 * current checkpoint.
 **/
entity function CreateCheckpoint(entity targetplayer, vector origin, void functionref(entity) callback, float size = 0.5, string color = "0 155 0")
{
	printt("I created a checkpoint!"+targetplayer.GetPlayerName())
	targetplayer.EndSignal( "OnDestroy" )
	targetplayer.EndSignal( "Iwanttochangearoute" )
    // Spawn bubble
    entity point = CreateEntity( "prop_dynamic" )
    point.SetValueForModelKey($"models/fx/xo_emp_field.mdl")
    point.kv.rendercolor = defaultcolourforecheclptoitns
    point.kv.modelscale = size
    point.SetOrigin( origin )
	point.SetOwner( targetplayer )
	point.kv.VisibilityFlags = ENTITY_VISIBLE_TO_OWNER
    DispatchSpawn( point )

    // Spawn trigger
    entity trigger = CreateTriggerRadiusMultiple( origin, 140, [], TRIG_FLAG_PLAYERONLY, 80, -80)
    AddCallback_ScriptTriggerEnter( trigger, void function (entity trigger, entity player): (callback,targetplayer) {
		if (player == targetplayer){
        callback(player)}
    })

	// Debugging
    float cylinderHeight = 160.0
    DebugDrawCylinder( <origin.x, origin.y, origin.z + cylinderHeight>, <90, 0, 0>, 140.0, cylinderHeight, 0, 255, 0, true, 10000.0 )

    return point

}


/**
 * This method spawns the starting trigger.
 * This trigger checks if colliding players are currently doing a parkour run, and starts
 * one if it's not the case.
 **/
void function SpawnStartTrigger(array<entity> whyonearthisitlikethisomgthisisthecheckpointentarraytho,array<vector> checkpoints, entity player, vector volumeMins, vector volumeMaxs )
{
	player.EndSignal( "OnDestroy" )
	player.EndSignal( "Iwanttochangearoute" )
	int checkpointsCount = checkpoints.len()-1

	// Debugging
	DebugDrawBox( <0,0,0>, volumeMins, volumeMaxs, 255, 0, 0, 10, 10000.0 )

	while (GetGameState() <= eGameState.SuddenDeath)
	{
		
			if ( !IsValid( player ) ) {
				continue
			}

			string playerName = player.GetPlayerName()

			if (PointIsWithinBounds( player.GetOrigin(), volumeMins, volumeMaxs ))
			{
				if (!PK_localStats[playerName].justFinished && !PK_localStats[playerName].isRunning && !PK_localStats[playerName].isResetting)
				{
										PK_checkpointEntities[player][0].kv.rendercolor = nextcheckpoint // Ig if the compelted don't need next to be red


					PK_localStats[playerName].startTime = Time()
					PK_localStats[playerName].isRunning = true
					Remote_CallFunction_NonReplay( player, "ServerCallback_PK_UpdateNextCheckpointMarker", whyonearthisitlikethisomgthisisthecheckpointentarraytho[0].GetEncodedEHandle(), 0, checkpointsCount )
					EmitSoundOnEntityOnlyToPlayer( player, player, "training_scr_gaunlet_start" )
					PK_AddPlayerParkourStat( player, ePlayerParkourStatType.Starts )
				}
			}
		
		WaitFrame()
	}
}

/**
 * This method spawns the end trigger, which ends parkour runs.
 * The `origin` argument vector is used to create an invisible entity, which is actually
 * used client-side to mark the last place players must go to.
 **/
entity function SpawnEndTrigger(array<vector> checkpoints,entity player, vector origin, vector volumeMins, vector volumeMaxs )
{
	entity point = CreateEntity( "prop_dynamic" )
    point.SetOrigin( origin )
	point.SetValueForModelKey($"models/fx/xo_emp_field.mdl")
	point.kv.modelscale = 0.3
    point.Hide()
    DispatchSpawn( point )
    thread FinishTriggerThink(checkpoints,player,volumeMins, volumeMaxs)

	// Debugging
	DebugDrawBox( origin, volumeMins - origin, volumeMaxs - origin, 255, 255, 0, 10, 10000.0 )
	DebugDrawSphere( origin, 25.0, 255, 255, 0, true, 10000.0 )

    return point
}

/**
 * End trigger logic.
 * Checks if colliding players can finish a parkour run (= if they currently are running
 * and last verified checkpoint was the last one), and save their run time if need be.
 * It also resets player stats, for them to be able to start a new parkour run.
 **/
void function FinishTriggerThink(array<vector> checkpoints,entity player, vector volumeMins, vector volumeMaxs)
{
	player.EndSignal( "OnDestroy" )
	player.EndSignal( "Iwanttochangearoute" )
    while (GetGameState() <= eGameState.SuddenDeath)
	{
	
			if ( !IsValid( player ) ) {
				continue
			}

			string playerName = player.GetPlayerName()

			if (PointIsWithinBounds( player.GetOrigin(), volumeMins, volumeMaxs ))
			{
                PK_PlayerStats playerStats = PK_localStats[playerName]
				if (playerStats.isRunning && playerStats.currentCheckpoint == checkpoints.len()-2) {
                    float duration = Time() - playerStats.startTime

					thread PreventPlayerToImmediatelyStartAgain(playerStats)
                    playerStats.isRunning = false
                    playerStats.currentCheckpoint = 0
					// playerStats.checkpointPassages = [PK_startOrigin]
                    // playerStats.checkpointAngles = [PK_startAngles]
					foreach (checkpoint in PK_checkpointEntities[player]){
						checkpoint.kv.rendercolor = defaultcolourforecheclptoitns
					}

                    bool isBestTime = duration < playerStats.bestTime
                    if (isBestTime)
                    {
                        playerStats.bestTime = duration
						EmitSoundOnEntityOnlyToPlayer( player, player, "training_scr_gaunlet_high_score" )
                    } else {
						EmitSoundOnEntityOnlyToPlayer( player, player, "training_scr_gaunlet_end" )
					}

                    Remote_CallFunction_NonReplay( player, "ServerCallback_PK_StopRun", duration, isBestTime )
					ResetPlayerCooldowns(player)

					// Score update
					PK_StoreNewLeaderboardEntry( player, duration )
					PK_AddPlayerParkourStat(player, ePlayerParkourStatType.Finishes)
				}
			}
		
		WaitFrame()
	}
}

/**
 * Raises a flag preventing player to start a new run.
 * This is useful on maps that share the same trigger for starting and finish lines, for
 * players not to start a new run instantly after ending one.
 **/
void function PreventPlayerToImmediatelyStartAgain(PK_PlayerStats playerStats)
{
	playerStats.justFinished = true
	wait 1
	playerStats.justFinished = false
}