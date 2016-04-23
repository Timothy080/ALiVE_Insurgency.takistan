//////////////////////////////////////////////////////////////////
// Function file for Armed Assault
// Created by: TODO: Author Name
//////////////////////////////////////////////////////////////////

_unit = _this select 0;
_marker = _this select 1;

_marker setMarkerColor "ColorRed";

while{alive _unit}do{
  _marker setMarkerPos (getPos _unit);
  _marker setMarkerDir (getDir _unit);
  sleep 5;
};