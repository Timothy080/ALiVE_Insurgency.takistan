/*
Author:

	SpyderBlack723


Description:

	Creates and appends SCI_fnc to each function listed.

______________________________________________________*/

class SCI
{
	tag = "SCI";
	class functions
	{
		class civilianInteraction {
			description = "Main handler for civilian interaction";
			file = "SpyderCivInteraction\fn_civilianInteraction.sqf";
			recompile = RECOMPILE;
		};

		class commandHandler {
			description = "Main handler for commands";
			file = "SpyderCivInteraction\fn_commandHandler.sqf";
			recompile = RECOMPILE;
		};
		class questionHandler {
			description = "Retrieves responses for passed question";
			file = "SpyderCivInteraction\fn_questionHandler.sqf";
			recompile = RECOMPILE;
		};

	};
};