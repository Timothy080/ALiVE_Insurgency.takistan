//0 = this execVM "Scripts\makeAdminBox.sqf";
_this addAction [   "<t color='#ff1111'>Virtual Ammobox</t>",   "VAS\open.sqf"];
_this addAction [   "<t color='#ff1111'>Virtual Arsenal</t>",   {["Open",true] call BIS_fnc_arsenal;}];
_this addAction [   "<t color='#ff1111'>Loadout Editor (LEA)</t>",   "userconfig\LEA\loadout.sqf"];