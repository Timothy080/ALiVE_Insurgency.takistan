//-- Only run on server
if (!isServer) exitWith {};

params ["_unit"];

if !(_unit isKindOf "Man") exitWith {};

if (side _unit == civilian) then {
	//-- Add interact action
	[[[_unit],{
		if (hasInterface) then {
			params ["_unit"];
			_unit addAction ["Interact", "['openMenu', [_this select 0]] call SCI_fnc_civilianInteraction", "", 50, true, false, "", "alive _target"];
		};
	}],"BIS_fnc_spawn",true] call BIS_fnc_MP;
};