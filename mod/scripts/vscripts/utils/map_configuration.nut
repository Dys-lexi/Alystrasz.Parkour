global function PK_InitializeMapConfiguration
global function DebugPK_GetEntity
global function pullsavespot
global function returnroutes
/**
 * This global object holds parkour API information needed to interact
 * with it, namely its address, secret token, current event and current
 * map identifiers.
 *
 * These information are used by the world leaderboard to fetch scores,
 * for instance.
 **/
global struct PK_Credentials {
    string eventId = ""
    string mapId = ""
    string routeId = ""
    string endpoint
    string secret
    array<string> maps = []
}


global table<string, table<string, table<string, vector> > > pk_savespots

global PK_Credentials PK_credentials

/**
 * This global object stores serialized coordinates of in-game entities
 * such as leaderboards, that must be sent to players when they connect
 * (hence the string type, since they're passed to clients using
 * `ServerToClientStringCommand` calls).
 **/
global struct PK_MapConfiguration {
    bool finishedFetchingData = false
    entity startIndicator
    string startLineStr
    string finishLineStr
    string localLeaderboardStr
    string worldLeaderboardStr
    string routeNameStr
}
// global PK_MapConfiguration PK_MapConfiguration

global struct PK_MapConfigurationb {
    bool finishedFetchingData = false
    entity startIndicator
    string startLineStr
    string finishLineStr
    string localLeaderboardStr
    string worldLeaderboardStr
    string routeNameStr
}

global table<entity,string> selectedrouteforplayers

global table<string,PK_MapConfigurationb> routes
global bool fetchedall = false

global struct MapEntity {
    string model_name
    float scale
    vector coordinates
    vector angles
    bool hidden
}

/**
 * This object stores start and finish triggers plus ziplines coordinates.
 * Those are used to spawn related entities after map configuration fetching
 * is done.
 **/
global struct RouteData {
    vector startMins
    vector startMaxs
    vector endMins
    vector endMaxs
    array ziplines
    array<MapEntity> entities
    entity lastSpawnedProp
}

global table<string, RouteData> whyoneartharecheckpointsnotstoredwiththerestorsomethingandthenthatwiththemap

/**
 * This object stores information needed to spawn a helping robot on the map.
 **/
global struct robot{
    vector origin
    vector angles
    int talkableRadius
    string animation
} ;

global table<string,robot> robots

/**
 * Get the map configuration, applies it to the game level and send UI elements
 * (start/finish indicators, leaderboards) coordinates to clients.
 *
 * Map configuration can be fetched from two sources: Parkour API or local file.
 **/
void function reloadmapw(){
    ServerCommand("reload")
}

bool function reloadmap(entity player, array<string> args) {
    delaythread (5) reloadmapw()
    Chat_ServerBroadcast("reloading map in 5s",false)
    return true
}
void function loadsavespots(){
    if (!NSDoesFileExist("savespots.json")){
        return
    }
    void functionref( string ) onFileLoad = void function ( string result )
    {
        table data = DecodeJSON(result)

        // Check if current map has save data
        if (!(GetMapName() in data)) {
            return
        }

        table mapRoutes = expect table(data[GetMapName()])

        foreach (routeName, routeData in mapRoutes) {
            string route = expect string(routeName)
            array players = expect array(routeData)

            if (!(route in pk_savespots)) {
                pk_savespots[route] <- {}
            }

            foreach (player in players) {
                table playerdata = expect table(player)
                string uid = expect string(playerdata["uid"])
                array posArray = expect array(playerdata["pos"])
                array angleArray = expect array(playerdata["angle"])

                pk_savespots[route][uid] <- {
                    pos = PK_ArrayToFloatVector(posArray),
                    angle = PK_ArrayToFloatVector(angleArray)
                }
            }
        }
    }
    
    NSLoadFile("savespots.json", onFileLoad)
}
void function saveplayerspot(entity player,bool deletee = false){
    string selectedRoute = selectedrouteforplayers[player]

    // Initialize route table if it doesn't exist
    if (!(selectedRoute in pk_savespots)) {
        pk_savespots[selectedRoute] <- {}
    }

    pk_savespots[selectedRoute][player.GetUID()] <- {pos=<player.GetOrigin().x,player.GetOrigin().y,player.GetOrigin().z + 5>,angle=player.CameraAngles()}
    if (deletee){
        delete pk_savespots[selectedRoute][player.GetUID()]
    }

    void functionref( string ) onFileLoad = void function ( string result )
    {
        table data

        // Handle empty or non-existent file
        if (result == "") {
            data = {}
        } else {
            data = DecodeJSON(result)
        }

        // Create route-based structure for current map
        table routesData = {}

        foreach (routeName, routePlayers in pk_savespots) {
            array playerArray = []
            foreach (uid, spotData in routePlayers) {
                table playerSpot = {
                    uid = uid,
                    pos = [spotData["pos"].x, spotData["pos"].y, spotData["pos"].z],
                    angle = [spotData["angle"].x, spotData["angle"].y, spotData["angle"].z]
                }
                playerArray.append(playerSpot)
            }
            routesData[routeName] <- playerArray
        }

        data[GetMapName()] <- routesData
        NSSaveFile("savespots.json",EncodeJSON(data))
    }

    if (!NSDoesFileExist("savespots.json")) {
        NSSaveFile("savespots.json", "{}")
    }

    NSLoadFile("savespots.json", onFileLoad)

}

bool function savespotwrapper(entity player, array<string> args){
    saveplayerspot(player)
    Chat_ServerPrivateMessage(player,"saving this spot",false,false)
    return true
}
bool function resetplayerspotwrapper(entity player, array<string> args){
    saveplayerspot(player,true)
    Chat_ServerPrivateMessage(player,"removing save spot",false,false)
    
    return true
}

table <string, vector> function pullsavespot(entity player){
    string selectedRoute = selectedrouteforplayers[player]

    if (selectedRoute in pk_savespots && player.GetUID() in pk_savespots[selectedRoute]){
        return pk_savespots[selectedRoute][player.GetUID()]
    }

    return {pos=PK_startOrigin[selectedRoute],angle=PK_startAngles[selectedRoute]}
}

bool function changeroute(entity player, array<string> args){
    // Remote_CallFunction_NonReplay(player, "ServerCallback_PK_ResetRun")

    if (!args.len() || !routematchstuff(args[0]).len()){
        
        thread waitabit(player,true)
        return true
    }
    selectedrouteforplayers[player] = routematchstuff(args[0])[0]
    player.Signal("Iwanttochangearoute")
    OnPlayerReset(player)
    // foreach (checkpoint in PK_checkpointEntities[player]){
	// 					checkpoint.kv.defaultcolourforecheclptoitns = defaultcolourforecheclptoitns
	// 				}
    return true
}


array <string> function routematchstuff(string playername){ //returns all players that have a partial playername match
	array<string> matchedplayers = [];
    array<string> players = returnroutes()
    foreach (string player in players)
        {
            
            
  
                if (player.tolower().find(playername.tolower()) != null)
                {
                    matchedplayers.append(player)

                }
            
        }
	return matchedplayers
}

void function waitabit(entity player, bool waitmore = false){
    WaitFrame()
    if (waitmore){
        Chat_ServerPrivateMessage(player,"[38;5;203mcannot find route, do `[38;5;219m!cr routename[38;5;203m` below are routes:",false,false)
    }
    table <string,int> routecounts
    foreach (key, value in selectedrouteforplayers){
        if (!(value in routecounts)){
            routecounts[value] <- 0
        }
        routecounts[value] += 1
    }
    foreach (route in returnroutes()){
        string constructer = "[38;5;189m"+route
        if (selectedrouteforplayers[player] == route){
            constructer += " [38;5;219m(current)"
        }
        if (route in routecounts){
        constructer += " [38;5;249m("+routecounts[route] + " playing)"}
        else{
            constructer += " [38;5;249m("+"none" + " playing)"
        }
        Chat_ServerPrivateMessage(player,constructer,false,false)
    }
}

bool function listroutes(entity player, array<string> args){
    thread waitabit(player)
    
    return true
}
void function PK_InitializeMapConfiguration()
{
    RegisterSignal("Iwanttochangearoute")
    
    RegisterSignal( "Pkloadedconfig" )
    thread loadsavespots()
        PK_credentials.endpoint = GetConVarString("parkour_api_endpoint")
    PK_credentials.secret = GetConVarString("parkour_api_secret")
    KcommandArr.append(new_KCommandStruct(["listroutes","lr"], false,  listroutes, 0, "list routes"))
    KcommandArr.append(new_KCommandStruct(["changeroute","cr"], false,  changeroute, 0, "change your route"))
    KcommandArr.append(new_KCommandStruct(["reload"], false,  reloadmap, 0, "reload the current map"))
    KcommandArr.append(new_KCommandStruct(["reset","re"], false,  resetplayerspotwrapper, 0, "reset your custom save spot"))
    KcommandArr.append(new_KCommandStruct(["save","sa"], false,  savespotwrapper, 0, "save a custom save spot"))
    // Load map configuration either from local file or distant API
    array<string> realmaps
    bool useLocal = GetConVarInt("parkour_use_local_config") == 1
    // void functionref( string ) onFileLoad = void function ( string result ) : (realmaps)
    // {
    //     table data = DecodeJSON(result)
    //     array maps = expect array(data["throw maps here that when server goes to, it uses local config"])
        
    //     foreach (map in maps){
            
    //         // addsomemoremaps(expect string(map))
    //         printt("WOAG MAP"+expect string(map))
    //         realmaps.append(expect string(map)+"")
    //     }
    // }
    
    // NSLoadFile("shoulduselocalmapsonthesemaps.json", onFileLoad)
    // while (realmaps.len() == 0){
    //     WaitFrame()
    // }
    if (useLocal || realmaps.contains(GetMapName())) {
        printt("I GOT HERE")
        print("Loading map configuration from local file.")
        InitializeMapConfigurationFromFile()
    } else {
        print("Loading map configuration from API.")
        thread InitializeMapConfigurationFromAPI()
    }
    // while(PK_mapConfiguration.finishedFetchingData == false) {
    //     WaitFrame()
    // }
    GetEnt( "worldspawn" ).WaitSignal("Pkloadedconfig")
PK_has_api_access = true
    // Set up world
	// PK_SpawnCheckpoints( file.startMins, file.startMaxs, file.endMins, file.endMaxs )
    // foreach (routeName, routeData in whyoneartharecheckpointsnotstoredwiththerestorsomethingandthenthatwiththemap) {
    //     SpawnZiplines( routeData.ziplines )
    // }
    // SpawnEntities()
    // PK_SpawnAmbientMarvin( robot.origin, robot.angles, robot.talkableRadius, robot.animation )

    // Start map vote thread
    PK_MapVote()

    // Init players
    /*
    foreach(player in GetPlayerArray())
    {
        if ( !IsValid( player ) ) {
			continue
		}
        PK_OnPlayerConnected(player)
    }*/
}

array<string> routesw

array<string> function returnroutes(){
    return routesw
}

void function LoadParkourMapConfigurationnotstupid(table data){
    foreach (routename,value in data){
        string routeNameStr = expect string(routename)
        routes[routeNameStr] <- LoadParkourMapConfigurationnotstupidw(expect table(value), routeNameStr)
        routesw.append(routeNameStr)

    }
    fetchedall = true
    GetEnt( "worldspawn" ).Signal("Pkloadedconfig")
}
/**
 * This method loads all needed information from input table into memory, to spawn
 * current level's layout (start/finish lines, leaderboards, checkpoints, ziplines
 * etc).
 *
 * It also serializes some coordinates (namely start/finish lines and leaderboards
 * coordinates) to prepare sending them to clients, since clients need those
 * coordinates to spawn world RUIs.
 **/
PK_MapConfigurationb function LoadParkourMapConfigurationnotstupidw(table data, string routeName)
{
    PK_MapConfigurationb PK_mapConfiguratione
    // try {

        PK_checkpoints[routeName] <- []
        PK_leaderboard[routeName] <- []
        PK_worldLeaderboard[routeName] <- []
        RouteData routeData
        robot realrobot
        routeData.ziplines = []
        routeData.entities = []
        whyoneartharecheckpointsnotstoredwiththerestorsomethingandthenthatwiththemap[routeName] <- routeData


        array fCheckpoints = expect array(data["checkpoints"])
        foreach( checkpoint in fCheckpoints ) {
            PK_checkpoints[routeName].push( PK_ArrayToFloatVector(expect array(checkpoint)) )
        }
        table startData = expect table(data["start"])
        vector start = PK_ArrayToFloatVector( expect array(startData["origin"]) )
        PK_startOrigin[routeName] <- start
        PK_checkpoints[routeName].insert( 0, start )
        vector angles = PK_ArrayToIntVector( expect array(startData["angles"]) )
        PK_startAngles[routeName] <- angles
        table endData = expect table(data["end"])
        vector end = PK_ArrayToFloatVector( expect array(endData["origin"]) )
        PK_checkpoints[routeName].append( end )

        // Start/finish lines
        // Start
        table startLineData = expect table(data["start_line"])
        ParkourLine startLine = PK_BuildParkourLine(startLineData)
        whyoneartharecheckpointsnotstoredwiththerestorsomethingandthenthatwiththemap[routeName].startMins = startLine.triggerMins
        whyoneartharecheckpointsnotstoredwiththerestorsomethingandthenthatwiththemap[routeName].startMaxs = startLine.triggerMaxs
        // End
        table finishLineData = expect table(data["finish_line"])
        ParkourLine endLine = PK_BuildParkourLine(finishLineData)
        whyoneartharecheckpointsnotstoredwiththerestorsomethingandthenthatwiththemap[routeName].endMins = endLine.triggerMins
        whyoneartharecheckpointsnotstoredwiththerestorsomethingandthenthatwiththemap[routeName].endMaxs = endLine.triggerMaxs
        // Leaderboards
        table leaderboardsData = expect table(data["leaderboards"])
        table localLeaderboardData = expect table(leaderboardsData["local"])
        table worldLeaderboardData = expect table(leaderboardsData["world"])

        // Serialized
        PK_mapConfiguratione.startLineStr = EncodeJSON(startLineData)
        PK_mapConfiguratione.finishLineStr = EncodeJSON(finishLineData)
        PK_mapConfiguratione.localLeaderboardStr = EncodeJSON(localLeaderboardData)
        PK_mapConfiguratione.worldLeaderboardStr = EncodeJSON(worldLeaderboardData)

        // Serialize route name
        string routeName2 = expect string(data["name"])
        table routeNameData = expect table(data["route_name"])
        routeNameData["name"] <- routeName2
        PK_mapConfiguratione.routeNameStr = EncodeJSON(routeNameData)

        // Robot
        table robotData = expect table(data["robot"])
        realrobot.origin = PK_ArrayToFloatVector( expect array(robotData["origin"]) )
        realrobot.angles = PK_ArrayToIntVector( expect array(robotData["angles"]) )
        realrobot.talkableRadius = expect int(robotData["talkable_radius"])
        realrobot.animation = expect string(robotData["animation"])
        robots[routeName] <- realrobot

        // Start indicator
        table startIndicator = expect table(data["indicator"])
        vector startIndicatorOrigin = PK_ArrayToFloatVector( expect array(startIndicator["coordinates"]) )
        int startIndicatorRadius = expect int(startIndicator["trigger_radius"])
        PK_mapConfiguratione.startIndicator = SetUpStartIndicator( startIndicatorOrigin, startIndicatorRadius )

        // Store object references
        whyoneartharecheckpointsnotstoredwiththerestorsomethingandthenthatwiththemap[routeName].ziplines = expect array(data["ziplines"])
        array entities = expect array(data["entities"])
        foreach(ent in entities)
        {
            MapEntity me
            table raw_ent = expect table(ent)
            me.model_name = expect string(raw_ent.model_name)
            me.scale = expect float(raw_ent.scale)
            me.coordinates = PK_ArrayToFloatVector( expect array(raw_ent.coordinates) )
            me.angles = PK_ArrayToFloatVector( expect array(raw_ent.angles) )

            me.hidden = false
            if ( "hidden" in raw_ent && expect bool(raw_ent["hidden"]) == true )
            {
                me.hidden = true
            }

            PrecacheModel( StringToAsset( me.model_name ) )
            whyoneartharecheckpointsnotstoredwiththerestorsomethingandthenthatwiththemap[routeName].entities.append(me)
        }

        // Apply perks
        table perks = expect table(data["perks"]);
        PK_ApplyPerks( routeName,perks )

        PK_mapConfiguratione.finishedFetchingData = true
    // } catch (err) {
        
    //     print("Error while loading map configuration: " + err)
    //     return PK_mapConfiguratione
    // }
    return PK_mapConfiguratione
}


entity function SetUpStartIndicator( vector origin, int triggerRadius )
{
    // Entity used to show indicator's location
    entity point = CreateEntity( "prop_dynamic" )
    point.SetOrigin( origin )
    point.SetValueForModelKey($"models/fx/xo_emp_field.mdl")
    point.kv.modelscale = 1
    point.Hide()
    DispatchSpawn( point )
    

    // Only showing indicator when player is far from its origin
    entity trigger = CreateTriggerRadiusMultiple( origin, triggerRadius.tofloat(), [], TRIG_FLAG_PLAYERONLY)
    AddCallback_ScriptTriggerEnter( trigger, void function (entity trigger, entity player) {
        string playerName = player.GetPlayerName()
        if ( !PK_localStats[playerName].isRunning && !PK_localStats[playerName].isResetting ) {
            Remote_CallFunction_NonReplay( player, "ServerCallback_PK_ToggleStartIndicatorDisplay", false )
        }
    })
    AddCallback_ScriptTriggerLeave( trigger, void function (entity trigger, entity player) {
        string playerName = player.GetPlayerName()
        if ( !PK_localStats[playerName].isRunning && !PK_localStats[playerName].isResetting && IsAlive(player) ) {
            Remote_CallFunction_NonReplay( player, "ServerCallback_PK_ToggleStartIndicatorDisplay", true )
        }
    })

    // Debugging
    // Height is indicative here, as `trigger` has infinite height
    float cylinderHeight = 800.0
    DebugDrawCylinder( <origin.x, origin.y, origin.z - cylinderHeight>, <90, 0, 0>, triggerRadius.tofloat(), -2*cylinderHeight, 80, 80, 255, true, 10000.0 )
    DebugDrawSphere( origin, 25.0, 80, 80, 255, true, 10000.0 )
    return point
}


/**
 * Spawns ziplines on the map (pretty self-explanatory, right?).
 **/
void function SpawnZiplines( array coordinates )
{
	foreach (c in coordinates)
	{
        array zipline = expect array(c)
        array startCoordinates = expect array(zipline[0])
        array endCoordinates = expect array(zipline[1])
		CreateZipline( PK_ArrayToFloatVector(startCoordinates), PK_ArrayToFloatVector(endCoordinates) )
	}
}

/**
 * Spawns stuff on the map (thanks Zanieon for that!).
 **/


entity function DebugPK_GetEntity()
{
    // Return last spawned prop from first route
    if (routesw.len() > 0) {
        return whyoneartharecheckpointsnotstoredwiththerestorsomethingandthenthatwiththemap[routesw[0]].lastSpawnedProp
    }
    return null
}


/*
 ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗     ███████╗███████╗████████╗ ██████╗██╗  ██╗██╗███╗   ██╗ ██████╗
██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝     ██╔════╝██╔════╝╚══██╔══╝██╔════╝██║  ██║██║████╗  ██║██╔════╝
██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗    █████╗  █████╗     ██║   ██║     ███████║██║██╔██╗ ██║██║  ███╗
██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║    ██╔══╝  ██╔══╝     ██║   ██║     ██╔══██║██║██║╚██╗██║██║   ██║
╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝    ██║     ███████╗   ██║   ╚██████╗██║  ██║██║██║ ╚████║╚██████╔╝
 ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝     ╚═╝     ╚══════╝   ╚═╝    ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝
*/

/*
 ██╗██╗     ██╗      ██████╗  ██████╗ █████╗ ██╗          ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗
███║╚██╗    ██║     ██╔═══██╗██╔════╝██╔══██╗██║         ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝
╚██║ ██║    ██║     ██║   ██║██║     ███████║██║         ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗
 ██║ ██║    ██║     ██║   ██║██║     ██╔══██║██║         ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║
 ██║██╔╝    ███████╗╚██████╔╝╚██████╗██║  ██║███████╗    ╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝
 ╚═╝╚═╝     ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝
*/

/**
 * Loads map configuration from a local configuration file.
 *
 * The expected configuration file name is [MAPNAME]_configuration.json (e.g.
 * map_thaw_configuration.json) and should be located in the mod's files
 * directory (i.e. R2Northstar/save_data/Alystrasz.Parkour/FILE.json).
 *
 * If invoked on a map where there is no configuration file, said file will
 * be created, and an error will be thrown telling the developer to fill it
 * with a valid map configuration.
 **/
void function InitializeMapConfigurationFromFile()
{
    string fileName = format("%s_configuration.json", GetMapName())
    if (!NSDoesFileExist(fileName)) {
        NSSaveFile(fileName, "")
        throw format("No configuration file found for map \"%s\", please fill the configuration file (%s).", GetMapName(), fileName)
    }

    void functionref( string ) onFileLoad = void function ( string result )
    {
        table data = DecodeJSON(result)
        LoadParkourMapConfigurationnotstupid( data )
        GetEnt( "worldspawn" ).Signal("Pkloadedconfig")
        fetchedall = true
    }
    NSLoadFile(fileName, onFileLoad)
}


/*
██████╗ ██╗     ██████╗ ██╗███████╗████████╗ █████╗ ███╗   ██╗████████╗     ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗
╚════██╗╚██╗    ██╔══██╗██║██╔════╝╚══██╔══╝██╔══██╗████╗  ██║╚══██╔══╝    ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝
 █████╔╝ ██║    ██║  ██║██║███████╗   ██║   ███████║██╔██╗ ██║   ██║       ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗
██╔═══╝  ██║    ██║  ██║██║╚════██║   ██║   ██╔══██║██║╚██╗██║   ██║       ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║
███████╗██╔╝    ██████╔╝██║███████║   ██║   ██║  ██║██║ ╚████║   ██║       ╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝
╚══════╝╚═╝     ╚═════╝ ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝        ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝
*/

/**
 * Loads map configuration from Parkour API.
 *
 * This involves retrieving the current event, then the map configuration
 * associated to the current map (including perks and level layout).
 **/
void function InitializeMapConfigurationFromAPI()
{
    // Initialize credentials

    // thread FindEventIdentifier()
    // while (PK_credentials.eventId == "") {
    //     WaitFrame()
    // }
    // thread FindMapIdentifier()
    // while (PK_credentials.mapId == "") {
    //     WaitFrame()
    // }
    thread fetchmapconfigsfromapibutnotstupid()
    // thread FetchMapConfigurationsFromAPI()
}



/**
 * This method fetches the `events` resource of the Parkour API to find the identifier
 * of the current event, based on its start and end timestamps.
 *
 * Once corresponding event has been found, this will register said event identifier
 * locally, for it to be used in future HTTP requests to retrieve map information.
 *
 * If no corresponding event is found, no further HTTP request will occur during the
 * current match.
 **/
void function FindEventIdentifier()
{
    HttpRequest request
    request.method = HttpRequestMethod.GET
    request.url = format("%s/v1/events", PK_credentials.endpoint)
    table<string, array<string> > headers
    headers[ "authentication" ] <- [PK_credentials.secret]
    request.headers = headers

    void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response )
    {
        string inputStr = "{\"data\":" + response.body + "}"
        table data = DecodeJSON(inputStr)
        array events = expect array(data["data"])

        // Looking for an event whose dates match server current time.
        foreach (eValue in events) {
            table event = expect table(eValue)
            int start = expect int(event["start"])
            int end = expect int(event["end"])
            int currentTime = GetUnixTimestamp();

            if (currentTime >= start && currentTime <= end) {
                PK_credentials.eventId = expect string(event["id"])
                print("==> Parkour event found!")
                return;
            }
        }

        print("No parkour event is available at the moment.")
        PK_has_api_access = false
    }

    void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure )
    {
        print("Something went wrong while fetching events from parkour API.")
        print("=> " + failure.errorCode)
        print("=> " + failure.errorMessage)
        PK_has_api_access = false
    }

    NSHttpRequest( request, onSuccess, onFailure )
}


/**
 * This method fetches the `maps` resource of the Parkour API to find information
 * about the current match: where to save new scores, which settings (weapons/ability
 * set) to apply to all players...
 *
 * Once corresponding map has been found, this will register said map identifier
 * locally, for it to be used in future HTTP requests, apply required changes to
 * current match, and start fetching scores from distant API every few seconds.
 *
 * If no corresponding map is found, no further HTTP request will occur during the
 * current match.
 **/
void function FindMapIdentifier()
{
    HttpRequest request
    request.method = HttpRequestMethod.GET
    request.url = format("%s/v1/events/%s/maps", PK_credentials.endpoint, PK_credentials.eventId)
    table<string, array<string> > headers
    headers[ "authentication" ] <- [PK_credentials.secret]
    request.headers = headers

    void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response )
    {
        string inputStr = "{\"data\":" + response.body + "}"
        table data = DecodeJSON(inputStr)
        array maps = expect array(data["data"])

        // Store map names for later usage (map polling)
        foreach (value in maps) {
            table map = expect table(value)
            string map_name = expect string(map["map_name"])
            PK_credentials.maps.append( map_name )
        }

        // Looking for a map whose name matches current map's name.
        string mapName = GetMapName()
        foreach (value in maps) {
            table map = expect table(value)
            string map_name = expect string(map["map_name"])
            if ( map_name.find( mapName ) != null ) {
                print("==> Parkour map found!")
                PK_credentials.mapId = expect string(map["id"])
                PK_has_api_access = true
                return;
            }
        }

        print("No map matches the event id and current map.")
        PK_has_api_access = false
    }

    void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure )
    {
        print("Something went wrong while fetching maps from parkour API.")
        print("=> " + failure.errorCode)
        print("=> " + failure.errorMessage)
        PK_has_api_access = false
    }

    NSHttpRequest( request, onSuccess, onFailure )
}


void function fetchmapconfigsfromapibutnotstupid(){
    HttpRequest request
    request.method = HttpRequestMethod.GET
    request.url = format("%s/v1/maps/%s/routes", PK_credentials.endpoint, GetMapName())
    table<string, array<string> > headers
    headers[ "authentication" ] <- [PK_credentials.secret]
    request.headers = headers

    void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response )
    {
        print("==> Parkour map configurations retrieved!")

        string inputStr = "{\"data\":" + response.body + "}"
        table data = DecodeJSON(inputStr)
        table configurations = expect table(data["data"])

        // // todo: round-robin over configurations
        // table configuration = expect table(configurations[0])
        // PK_credentials.routeId = expect string(configuration["id"])

        LoadParkourMapConfigurationnotstupid(configurations)
        thread PK_WorldLeaderboard_StartPeriodicFetching()
    }

    void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure )
    {
        print("Something went wrong while fetching map configuration from parkour API.")
        print("=> " + failure.errorCode)
        print("=> " + failure.errorMessage)
        PK_has_api_access = false
    }

    NSHttpRequest( request, onSuccess, onFailure )
}

/**
 * This method fetches the `routes` resource of the Parkour API to retrieve the map
 * configuration for the current match: where to spawn leaderboards and start/finish
 * lines, what are the checkpoints coordinates etc.
 *
 * Once fetched, said map configuration is applied to create current level layout.
 *
 * If HTTP call fails, no further HTTP request will occur during the current match.
 **/
void function FetchMapConfigurationsFromAPI()
{
    HttpRequest request
    request.method = HttpRequestMethod.GET
    request.url = format("%s/v1/maps/%s/routes", PK_credentials.endpoint, PK_credentials.mapId)
    table<string, array<string> > headers
    headers[ "authentication" ] <- [PK_credentials.secret]
    request.headers = headers

    void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response )
    {
        print("==> Parkour map configurations retrieved!")

        string inputStr = "{\"data\":" + response.body + "}"
        table data = DecodeJSON(inputStr)
        array configurations = expect array(data["data"])

        // todo: round-robin over configurations
        table configuration = expect table(configurations[0])
        PK_credentials.routeId = expect string(configuration["id"])

        LoadParkourMapConfigurationnotstupid(configuration)
        thread PK_WorldLeaderboard_StartPeriodicFetching()
    }

    void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure )
    {
        print("Something went wrong while fetching map configuration from parkour API.")
        print("=> " + failure.errorCode)
        print("=> " + failure.errorMessage)
        PK_has_api_access = false
    }

    NSHttpRequest( request, onSuccess, onFailure )
}
