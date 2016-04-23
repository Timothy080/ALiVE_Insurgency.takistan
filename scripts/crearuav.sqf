//--Funcion UAV por M4RT14L--//
///////////////////////////////

if (isNil "vant") then 
{
 
_terminal = _this select 0;
_operador = _this select 1;
_accion = _this select 2;

		_title = "<t size='1.2' color='#68a7b7' shadow='1'>HEADQUARTERS</t><br/>";
        _text = format["%1<t>UAV on the way, ETA 10m. Only its allowed one UAV in AO. If you request new UAV you lose current</t>",_title];
		
        ["openSideSmall",0.4] call ALIVE_fnc_displayMenu;
        ["setSideSmallText",_text] call ALIVE_fnc_displayMenu;
		
		tablet say3D "RadioAmbient2";
		
sleep 600;		
//sleep 1800;

		_title = "<t size='1.2' color='#68a7b7' shadow='1'>HEADQUARTERS</t><br/>";
        _text = format["%1<t>UAV on AO, synchronize your terminal.</t>",_title];
		
        ["openSideSmall",0.4] call ALIVE_fnc_displayMenu;
        ["setSideSmallText",_text] call ALIVE_fnc_displayMenu;

		vant = [getPos UAV1, 1500, "B_UAV_02_F", WEST] call BIS_fnc_spawnVehicle;
		createVehicleCrew (vant select 0);
		
		tablet say3D "RadioAmbient3";

sleep 6000;

		_title = "<t size='1.2' color='#68a7b7' shadow='1'>HEADQUARTERS</t><br/>";
        _text = format["%1<t>UAV out of fuel, return to base. Request new UAV when you required.</t>",_title];
		
        ["openSideSmall",0.4] call ALIVE_fnc_displayMenu;
        ["setSideSmallText",_text] call ALIVE_fnc_displayMenu;
		
		tablet say3D "RadioAmbient4";

} else 	
{
		
		_title = "<t size='1.2' color='#68a7b7' shadow='1'>HEADQUARTERS</t><br/>";
        _text = format["%1<t>No more than one UAV in AO are allowed</t>",_title];
		
        ["openSideSmall",0.4] call ALIVE_fnc_displayMenu;
        ["setSideSmallText",_text] call ALIVE_fnc_displayMenu;
		
};

if (true)exitWith {};