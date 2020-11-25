#include "script_component.hpp"
/*
 * Author: Salbei
 * Starts removing trenches after a given time
 *
 * Arguments:
 * 0: Trench <OBJECT>
 * 1: Timeout To Decay <NUMBER>
 * 2: Decay Time <NUMBER>
 *
 * Return Value:
 * NONE
 *
 * Example:
 * [TrenchObj, 7200, 1800] call grad_trenches_functions_fnc_decayPFH;
 *
 * Public: No
 */

params ["_trench", ["_timeoutToDecay", 7200], ["_decayTime", 1800]];

if !(isServer) exitWith {};
if (isNull _trench) exitWith {};

if (isNil QGVAR(decayArray)) then {
	GVAR(decayArray) = [[_trench, _timeoutToDecay, _decayTime]];
} else {
	GVAR(decayArray) pushBack [_trench, _timeoutToDecay, _decayTime];
};

if (isNil QGVAR(decayPFH)) then {
	GVAR(decayPFH) = [{

		if (GVAR(decayArray) isEqualTo []) exitWith {
			[GVAR(decayPFH)] call CBA_fnc_removePerframeHandler;
			GVAR(decayPFH) = nil;
		};

		private _newArray = [];

		{
			_x params ["_trench", "_timeoutToDecay", "_decayTime"];

			if !(isNull "_trench") then {
				if (_timeoutToDecay <= 10) then {
					_timeoutToDecay = 0;
					if (_decayTime <= 10) then {
						_decayTime = 0;
					} else {
						_decayTime = _decayTime - 10;

						private _progress = _trench getVariable ["ace_trenches_progress", 0];
						private _digTime = missionNamespace getVariable [getText (configFile >> "CfgVehicles" >> (typeOf _trench) >>"ace_trenches_diggingDuration"), 20];
						
						_progress = _progress - (100/_digTime) * 100;
						if (_progress <= 0) then {
							deleteVehicle _trench;
						} else {
							_trench setVariable ["ace_trenches_progress", _progress];

							private _removeTime = missionNamespace getVariable [getText (configFile >> "CfgVehicles" >> (typeOf _trench) >>"ace_trenches_diggingDuration"), 20];
							private _placeData = _trench getVariable ["ace_trenches_placeData", [[], []]];
							_placeData params ["", "_vecDirAndUp"];

							private _pos = (getPosWorld _trench);
							private _posDiff = (_trench getVariable [QGVAR(diggingSteps), (([configFile >> "CfgVehicles" >> typeOf _trench >> QGVAR(offset), "NUMBER", 2] call CBA_fnc_getConfigEntry)/(_removeTime*10))]) * 1;
						
							_pos set [2, ((_pos select 2) - _posDiff)];
							_trench setPosWorld _pos;
							_trench setVectorDirAndUp _vecDirAndUp;

							_newArray pushBack [_trench, _timeoutToDecay, _decayTime];
						};
					};
				} else {
					_timeoutToDecay = _timeoutToDecay - 10;
				};
			};
		}forEach GVAR(decayArray);

		GVAR(decayArray) = _newArray;
	}, [], 10] call CBA_fnc_addPerFrameHandler;
};