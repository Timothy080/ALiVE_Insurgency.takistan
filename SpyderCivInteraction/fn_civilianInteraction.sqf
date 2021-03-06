/* ----------------------------------------------------------------------------
Function: SCI_fnc_civilianInterraction

Description:
Main handler for civilian interraction

Parameters:
String - Operation
Array - Arguments

Returns:
Any - Result of the operation

Examples:
(begin example)
[_operation, _arguments] call SCI_fnc_civilianInterraction;
["init",["WEST","LOP_ISTS"]] call SCI_fnc_civilianInterraction; //-- Initialize civilian interraction
_civData = ["getCivInfo",[_civ]] call SCI_fnc_civilianInterraction; //-- Get data of civilian
(end)

See Also:
- nil

Author: SpyderBlack723

Peer Reviewed:
nil
---------------------------------------------------------------------------- */

params [
	["_operation", ""],
	["_arguments", []]
];
private ["_result"];

//-- Define function shortcuts
#define MAINCLASS SCI_fnc_civilianInteraction
#define COMMAND_HANDLER SCI_fnc_commandHandler
#define QUESTION_HANDLER SCI_fnc_questionHandler

//-- Define control ID's
#define SCI_Dialog "Spyder_CivilianInteraction"
#define SCI_CivName 9236
#define SCI_Detain 92311
#define SCI_QuestionList 9234
#define SCI_QuestionControl (findDisplay 923 displayCtrl 9234)
#define SCI_ResponseList (findDisplay 923 displayCtrl 9239)
#define SCI_INVENTORYCONTROLS [9240,9241,9243,9244]
#define SCI_SEARCHBUTTON 9242
#define SCI_GEARLIST 9244
#define SCI_GEARLISTCONTROL (findDisplay 923 displayCtrl 9244)
#define SCI_CONFISCATEBUTTON 9245

switch (_operation) do {

	//-- Create logic on all localities
	case "init": {
		_arguments params ["_sideFriendly","_factionEnemy"];
		if (isNil "SCI_Logic") then {

			SCI_Logic = [] call ALIVE_fnc_hashCreate;


			//-- Convert side and factions to string if they are not already
			{
				if !(typeName _x == "STRING") then {_x = str _x};
			} forEach [_sideFriendly,_factionEnemy];

			//-- Initialize settings
			_sideEnemy = _factionEnemy call ALiVE_fnc_factionSide;
			[SCI_Logic, "PlayerSide", _sideFriendly] call ALiVE_fnc_hashSet;
			[SCI_Logic, "InsurgentSide", _sideEnemy] call ALiVE_fnc_hashSet;
			[SCI_Logic, "InsurgentFaction", _factionEnemy] call ALiVE_fnc_hashSet;

		};
	};
	
	//-- On load
	case "openMenu": {
		_arguments params ["_civ"];

		//-- Exit if civ is armed
		if ((primaryWeapon _civ != "") or (handgunWeapon _civ != "")) exitWith {};

		//-- Close dialog if it happened to open twice
		if (!isNull findDisplay 923) exitWith {};

		//-- Stop civilian
		[[[_civ],{(_this select 0) disableAI "MOVE"}],"BIS_fnc_spawn",_civ,false,true] call BIS_fnc_MP;

		//-- Remove data from handler -- Just in case something doesn't delete upon closing
		[SCI_Logic, "CurrentCivData", nil] call ALiVE_fnc_hashSet;
		[SCI_Logic, "CurrentCivilian", nil] call ALiVE_fnc_hashSet;
		[SCI_Logic, "Items", nil] call ALiVE_fnc_hashSet;

		//-- Hash civilian to logic (must be done early so commandHandler has an object to use)
		[SCI_Logic, "CurrentCivilian", _civ] call ALiVE_fnc_hashSet;				//-- Unit object

		//-- Open dialog
		CreateDialog SCI_Dialog;
		ctrlSetText [SCI_CivName, name _civ];
		if (_civ getVariable "detained") then {
			ctrlSetText [SCI_Detain, "Release"];
		};
		["toggleSearchMenu"] call SCI_fnc_civilianInteraction;
		ctrlShow [SCI_CONFISCATEBUTTON, false];

		//-- Display loading
		lbAdd [SCI_QuestionList, "Loading . . ."];

		//-- Retrieve data
		["getCivInfo",[player,_civ]] remoteExecCall ["SCI_fnc_civilianInteraction",2];
	};

	//-- Load data
	case "loadData": {
		//-- Exit if the menu has been closed
		if (isNull findDisplay 923) exitWith {};

		_arguments params ["_objectiveInstallations","_objectiveActions","_civInfo","_hostileCivInfo"];

		//-- Create hash
		_civData = [] call ALIVE_fnc_hashCreate;
		_civ = [SCI_Logic,"CurrentCivilian"] call ALiVE_fnc_hashGet;
		_answersGiven = _civ getVariable ["AnswersGiven", []];

		//-- Hash data to logic
		[_civData, "Installations", _objectiveInstallations] call ALiVE_fnc_hashSet;		//-- [_factory,_HQ,_depot,_roadblocks]
		[_civData, "Actions", _objectiveActions] call ALiVE_fnc_hashSet;			//-- [_ambush,_sabotage,_ied,_suicide]
		[_civData, "CivInfo", _civInfo] call ALiVE_fnc_hashSet;				//-- [_homePos, _individualHostility, _townHostility]
		[_civData, "HostileCivInfo", _hostileCivInfo] call ALiVE_fnc_hashSet;			//-- [_civ,_homePos,_activeCommands]
		[_civData, "AnswersGiven", _answersGiven] call ALiVE_fnc_hashSet;			//-- Default []
		[_civData, "Asked", 0] call ALiVE_fnc_hashSet;					//-- Default - 0
		[SCI_Logic, "CurrentCivData", _civData] call ALiVE_fnc_hashSet;

		//-- Build question list
		lbClear SCI_QuestionList;
		lbAdd [SCI_QuestionList, "Where do you live?"];lbSetData [SCI_QuestionList, 0, "Home"];
		lbAdd [SCI_QuestionList, "What town you do live in"];lbSetData [SCI_QuestionList, 1, "Town"];
		lbAdd [SCI_QuestionList, "Have you seen any IED's lately?"];lbSetData [SCI_QuestionList, 2, "IEDs"];
		lbAdd [SCI_QuestionList, "Have you seen any insurgent activity lately?"];lbSetData [SCI_QuestionList, 3, "Insurgents"];
		lbAdd [SCI_QuestionList, "Do you know the location of any insurgent hideouts?"];lbSetData [SCI_QuestionList, 4, "Hideouts"];
		lbAdd [SCI_QuestionList, "Have you seen any strange behavior lately?"];lbSetData [SCI_QuestionList, 5, "StrangeBehavior"];
		lbAdd [SCI_QuestionList, "Do you support us?"];lbSetData [SCI_QuestionList, 6, "Opinion"];
		lbAdd [SCI_QuestionList, "What is the opinion of our forces in this area?"];lbSetData [SCI_QuestionList, 7, "TownOpinion"];

		//-- Add threats? Can raise or lower civilian's posture level based on random chance and civ's current hostility

		SCI_QuestionControl ctrlAddEventHandler ["LBSelChanged","
			_index = lbCurSel 9234;
			_question = lbData [9234, _index];
			[_question] call SCI_fnc_questionHandler;
		"];

	};

	//-- Unload
	case "closeMenu": {

		//-- Close menu
		closeDialog 0;

		//-- Un-stop civilian
		_civ = [SCI_Logic, "CurrentCivilian"] call ALiVE_fnc_hashGet;
		[[[_civ],{(_this select 0) enableAI "MOVE"}],"BIS_fnc_spawn",_civ,false,true] call BIS_fnc_MP;

		//-- Remove data from handler
		[SCI_Logic, "CurrentCivData", nil] call ALiVE_fnc_hashSet;
		[SCI_Logic, "CurrentCivilian", nil] call ALiVE_fnc_hashSet;
		[SCI_Logic, "Items", nil] call ALiVE_fnc_hashSet;
	};

	case "getObjectiveInstallations": {
		_arguments params ["_opcom","_objective"];

		_factory = [_opcom,"convertObject",[_objective,"factory"] call ALiVE_fnc_HashGet] call ALiVE_fnc_OPCOM;
		_HQ = [_opcom,"convertObject",[_objective,"HQ"] call ALiVE_fnc_HashGet] call ALiVE_fnc_OPCOM;
		_depot = [_opcom,"convertObject",[_objective,"depot"] call ALiVE_fnc_HashGet] call ALiVE_fnc_OPCOM;
		_roadblocks = [_opcom,"convertObject",[_objective,"roadblocks"] call ALiVE_fnc_HashGet] call ALiVE_fnc_OPCOM;

		_result = [_factory,_HQ,_depot,_roadblocks];
	};

	case "getObjectiveActions": {
		_arguments params ["_opcom","_objective"];

		_ambush = [_opcom,"convertObject",[_objective,"ambush"] call ALiVE_fnc_HashGet] call ALiVE_fnc_OPCOM;
		_sabotage = [_opcom,"convertObject",[_objective,"sabotage"] call ALiVE_fnc_HashGet] call ALiVE_fnc_OPCOM;
		_ied = [_opcom,"convertObject",[_objective,"ied"] call ALiVE_fnc_HashGet] call ALiVE_fnc_OPCOM;
		_suicide = [_opcom,"convertObject",[_objective,"suicide"] call ALiVE_fnc_HashGet] call ALiVE_fnc_OPCOM;

		_result = [_ambush,_sabotage,_ied,_suicide];
	};

	case "getCivInfo": {
		_arguments params ["_player","_civ"];
		private ["_opcom","_nearestObjective","_clusterID","_agentProfile","_hostileCivInfo"];
		
		_civPos = getPos _civ;
		_playerSide = [SCI_Logic, "PlayerSide"] call ALiVE_fnc_hashGet;
		_insurgentFaction = [SCI_Logic, "InsurgentFaction"] call ALiVE_fnc_hashGet;
			
		//-- Get nearest objective properties
		{
			if (_insurgentFaction in ([_x, "factions"] call ALiVE_fnc_hashGet)) then {
				_opcom = _x;
				_objectives = ([_x, "objectives"] call ALiVE_fnc_hashGet);
				_objectives = [_objectives,[_civPos],{_Input0 distance2D ([_x, "center"] call CBA_fnc_HashGet)},"ASCEND"] call BIS_fnc_sortBy;
				_nearestObjective = _objectives select 0;
			};
		} forEach OPCOM_instances;

		if (!isNil "_opcom") then {
			_objectiveInstallations = ["getObjectiveInstallations", [_opcom,_nearestObjective]] call SCI_fnc_civilianInteraction;
			_objectiveActions = ["getObjectiveActions", [_opcom,_nearestObjective]] call SCI_fnc_civilianInteraction;
		} else {
			_objectiveInstallations = [[],[],[],[]];
			_objectiveActions = [[],[],[],[]];
		};
			
		//-- Get civilian info
		_civInfo = [];
		_civID = _civ getVariable ["agentID", ""];
			
		if (_civID != "") then {
			_civProfile = [ALIVE_agentHandler, "getAgent", _civID] call ALIVE_fnc_agentHandler;
			_clusterID = _civProfile select 2 select 9;
			_cluster = [ALIVE_clusterHandler, "getCluster", _clusterID] call ALIVE_fnc_clusterHandler;
			_homePos = (_civProfile select 2) select 10;
			_individualHostility = (_civProfile select 2) select 12;
			_townHostility = [_cluster, "posture"] call ALIVE_fnc_hashGet;	//_townHostility = (_cluster select 2) select 9; (Different)
			_civInfo pushBack [_homePos, _individualHostility, _townHostility];
		};
		
		//-- Get nearby hostile civilian
		_hostileCivInfo = [];
		_insurgentCommands = ["alive_fnc_cc_suicide","alive_fnc_cc_suicidetarget","alive_fnc_cc_rogue","alive_fnc_cc_roguetarget","alive_fnc_cc_sabotage","alive_fnc_cc_getweapons"];
		_agentsByCluster = [ALIVE_agentHandler, "agentsByCluster"] call ALIVE_fnc_hashGet;
		_nearCivs = [_agentsByCluster, _clusterID] call ALIVE_fnc_hashGet;
		
		//-- {_x getVariable "ALiVE_insurgent"} would work as well but this method simulates a more community - focused base of knowledge
		for "_i" from 0 to ((count (_nearCivs select 1)) - 1) do {
			_agentID = (_nearCivs select 1) select _i;
			_agentProfile = [_nearCivs, _agentID] call ALiVE_fnc_hashGet;
				
			if ([_agentProfile,"active"] call ALIVE_fnc_hashGet) then {
				if ([_agentProfile, "type"] call ALiVE_fnc_hashGet == "agent") then {
					_activeCommands = [_agentProfile,"activeCommands",[]] call ALIVE_fnc_hashGet;

					if ({toLower (_x select 0) in _insurgentCommands} count _activeCommands > 0) then {
						_unit = [_agentProfile,"unit"] call ALIVE_fnc_hashGet;

						if (name _civ != name _unit) then {
							_homePos = (_agentProfile select 2) select 10;
							_hostileCivInfo pushBack [_unit,_homePos,_activeCommands];
						};
					};
				};
			};
		};
		if (count _hostileCivInfo > 0) then {_hostileCivInfo = _hostileCivInfo call BIS_fnc_selectRandom};
		
		_civData = [_objectiveInstallations, _objectiveActions, _civInfo,_hostileCivInfo];

		//-- Send data to client
		["loadData",_civData] remoteExecCall ["SCI_fnc_civilianInteraction",_player];
	};

	case "UpdateHostility": {
		//-- Change local civilian hostility
		private ["_townHostilityValue"];
		_arguments params ["_civ","_value"];
		if (count _arguments > 2) then {_townHostilityValue = _arguments select 2};		

		if (isNil "_townHostilityValue") then {
			if (isNil {[SCI_Logic, "CurrentCivData"] call ALiVE_fnc_hashGet}) exitWith {};

			_civData = [SCI_Logic, "CurrentCivData"] call ALiVE_fnc_hashGet;
			_civInfo = ([_civData, "CivInfo", _civInfo] call ALiVE_fnc_hashGet) select 0;
			_civInfo params ["_homePos","_individualHostility","_townHostility"];

			_individualHostility = _individualHostility + _value;
			_townHostilityValue = floor random 4;
			_townHostility = _townHostility + _townHostilityValue;
			[_civData, "CivInfo", [[_homePos, _individualHostility, _townHostility]]] call ALiVE_fnc_hashSet;
			[SCI_Logic, "CurrentCivData", _civData] call ALiVE_fnc_hashSet;
		};

		//-- Change civilian posture globally
		if (isNil "_townHostilityValue") exitWith {["UpdateHostility", [_civ,_value,_townHostilityValue]] remoteExecCall ["SCI_fnc_civilianInteraction",2]};

		_civID = _civ getVariable ["agentID", ""];
		if (_civID != "") then {
			_civProfile = [ALIVE_agentHandler, "getAgent", _civID] call ALIVE_fnc_agentHandler;
			_clusterID = _civProfile select 2 select 9;

			//-- Set town hostility
			_cluster = [ALIVE_clusterHandler, "getCluster", _clusterID] call ALIVE_fnc_clusterHandler;
			_clusterHostility = [_cluster, "posture"] call ALIVE_fnc_hashGet;
			[_cluster, "posture", (_clusterHostility + _townHostilityValue)] call ALIVE_fnc_hashSet;

			//-- Set individual hostility
			_hostility = (_civProfile select 2) select 12;
			_hostility = _hostility + _value;
			[_civProfile, "posture", _hostility] call ALiVE_fnc_hashSet;
		};
		
	};

	case "isIrritated": {
		_arguments params ["_hostile","_asked","_civ"];

		//-- Raise hostility if civilian is irritated
		if !(_hostile) then {
			if (floor random 100 < (3 * _asked)) then {
				["UpdateHostility", [_civ, 10]] call MAINCLASS;
				if (floor random 70 < (_asked * 5)) then {
					_response1 = format [" *%1 grows visibly annoyed*", name _civ];
					_response2 = format [" *%1 appears uninterested in the conversation*", name _civ];
					_response3 = " Please leave me alone now.";
					_response4 = " I do not want to talk to you anymore.";
					_response5 = " Can I go now?";
					_response = [_response1, _response2, _response3, _response4, _response5] call BIS_fnc_selectRandom;
					SCI_ResponseList ctrlSetText ((ctrlText SCI_ResponseList) + _response);
				};
			};
		} else {
			if (floor random 100 < (8 * _asked)) then {
				["UpdateHostility", [_civ, 10]] call MAINCLASS;
				if (floor random 70 < (_asked * 5)) then {
					_response1 = format [" *%1 looks anxious*", name _civ];
					_response2 = format [" *%1 looks distracted*", name _civ];
					_response3 = " Are you done yet?";
					_response4 = " You ask too many questions.";
					_response5 = " You need to leave now.";
					_response = [_response1, _response2, _response3,_response4, _response5] call BIS_fnc_selectRandom;
					SCI_ResponseList ctrlSetText ((ctrlText SCI_ResponseList) + _response);
				};
			};
		};
	};

	case "toggleSearchMenu": {
		private ["_enable"];
		if (ctrlVisible 9240) then {_enable = false} else {_enable = true};

		ctrlShow [SCI_SEARCHBUTTON, !_enable];

		{
			ctrlShow [_x, _enable];
		} forEach SCI_INVENTORYCONTROLS;

		if (_enable) then {
			["displayGear"] call MAINCLASS;
			SCI_GEARLISTCONTROL ctrlAddEventHandler ["LBSelChanged","['onGearSwitch'] call SCI_fnc_civilianInteraction"];
		} else {
			ctrlShow [SCI_CONFISCATEBUTTON, false];
		};
	};

	case "displayGear": {
		private ["_configPath"];
		_civ = [SCI_Logic, "CurrentCivilian"] call ALiVE_fnc_hashGet;
		lbClear SCI_GEARLIST;
		_itemClassnames = [];

		{
			_item = _x;

			//-- Get config path
			_configPath = configfile >> "CfgWeapons" >> _item;
			if !(isClass _configPath) then {_configPath = configfile >> "CfgMagazines" >> _item};
			if !(isClass _configPath) then {_configPath = configfile >> "CfgVehicles" >> _item};
			if !(isClass _configPath) then {_configPath = configfile >> "CfgGlasses" >> _item};

			//-- Get item info
			if (isClass _configPath) then {
				_itemName = getText (_configPath >> "displayName");
				_itemPic = getText (_configPath >> "picture");
				_configName = configName _configPath;
				lbAdd [SCI_GEARLIST, _itemName];
				lbSetPicture [SCI_GEARLIST, _forEachIndex, _itemPic];
				//lbSetData [SCI_GEARLIST, _forEachIndex, _configName];	Why the hell does this not work
				_itemClassnames pushBack _configName;
			};
		} forEach (items _civ + weapons _civ + vestItems _civ);
		[SCI_Logic, "Items", _itemClassnames] call ALiVE_fnc_hashSet;

		["onGearSwitch"] call MAINCLASS;
	};

	case "confiscate": {
		_index = lbCurSel SCI_GEARLIST;
		_item = ([SCI_Logic, "Items"] call ALiVE_fnc_hashGet) select _index;
		_civ = [SCI_Logic, "CurrentCivilian"] call ALiVE_fnc_hashGet;

		if (player canAddItemToBackpack _item) exitWith {
			player addItemToBackpack _item;
			_civ removeWeapon _item;_civ removeMagazine _item;_civ removeItem _item;
			["displayGear"] call MAINCLASS;
			ctrlShow [SCI_CONFISCATEBUTTON, false];
		};

		if (player canAddItemToVest _item) exitWith {
			player addItemToVest _item;
			_civ removeWeapon _item;_civ removeMagazine _item;_civ removeItem _item;
			["displayGear"] call MAINCLASS;
			ctrlShow [SCI_CONFISCATEBUTTON, false];
		};

		if (player canAddItemToUniform _item) exitWith {
			player addItemToUniform _item;
			_civ removeWeapon _item;_civ removeMagazine _item;_civ removeItem _item;
			["displayGear"] call MAINCLASS;
			ctrlShow [SCI_CONFISCATEBUTTON, false];
		};

		hint "There is no room for this item in your inventory";
	};

	case "onGearSwitch": {
		_index = lbCurSel SCI_GEARLIST;

		if (_index == -1) then {
			ctrlShow [SCI_CONFISCATEBUTTON, false];
		} else {
			ctrlShow [SCI_CONFISCATEBUTTON, true];
		};
	};

	case "getActivePlan": {
		_activeCommand = _arguments;

		switch (toLower _activeCommand) do {
			case "alive_fnc_cc_suicide": {
				_activePlan1 = "carrying out a suicide bombing";
				_activePlan2 = "strapping himself with explosives";
				_activePlan3 = "planning a bombing";
				_activePlan4 = "getting ready to bomb your forces";
				_activePlan5 = "about to bomb your forces";
				_result = [_activePlan1,_activePlan2,_activePlan3,_activePlan4,_activePlan5] call BIS_fnc_selectRandom;
			};
			case "alive_fnc_cc_suicidetarget": {
				_activePlan1 = "planning on carrying out a suicide bombing";
				_activePlan2 = "strapping himself with explosives";
				_activePlan3 = "planning a bombing";
				_activePlan4 = "getting ready to bomb your forces";
				_activePlan5 = "about to bomb your forces";
				_result = [_activePlan1,_activePlan2,_activePlan3,_activePlan4,_activePlan5] call BIS_fnc_selectRandom;
			};
			case "alive_fnc_cc_rogue": {
				_activePlan1 = "storing a weapon in his house";
				_activePlan2 = "stockpiling weapons";
				_activePlan3 = "planning on shooting a patrol";
				_activePlan4 = "looking for patrols to shoot at";
				_activePlan5 = "paid to shoot at your forces";
				_result = [_activePlan1,_activePlan2,_activePlan3,_activePlan4,_activePlan5] call BIS_fnc_selectRandom;
			};
			case "alive_fnc_cc_roguetarget": {
				_activePlan1 = "storing a weapon in his house";
				_activePlan2 = "stockpiling weapons";
				_activePlan3 = "planning on shooting a patrol";
				_activePlan4 = "looking for somebody to shoot at";
				_activePlan5 = "paid to shoot at your forces";
				_result = [_activePlan1,_activePlan2,_activePlan3,_activePlan4,_activePlan5] call BIS_fnc_selectRandom;
			};
			case "alive_fnc_cc_sabotage": {
				_activePlan1 = "planning on sabotaging a building";
				_activePlan2 = "blowing up a building";
				_activePlan3 = "planting explosives nearby";
				_activePlan4 = "getting ready to plant explosives";
				_activePlan5 = "paid to shoot at your forces";
				_result = [_activePlan1,_activePlan2,_activePlan3,_activePlan4,_activePlan5] call BIS_fnc_selectRandom;
			};
			case "alive_fnc_cc_getweapons": {
				_activePlan1 = "retrieving weapons from a nearby weapons depot";
				_activePlan2 = "planning on joining the insurgents";
				_activePlan3 = "getting ready to go to a nearby insurgent recruitment center";
				_activePlan4 = "getting ready to retrieve weapons from a cache";
				_activePlan5 = "paid to attack your forces";
				_activePlan6 = "forced to join the insurgents";
				_activePlan7 = "preparing to attack your forces";
				_result = [_activePlan1,_activePlan2,_activePlan3,_activePlan4,_activePlan5] call BIS_fnc_selectRandom;
			};
		};
	};
};

//-- Return result if any exists
if (!isNil "_result") then {_result} else {nil};