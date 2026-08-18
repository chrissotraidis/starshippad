#pragma once

#include <cstdint>

using Uint8 = uint8_t;
using Sint16 = int16_t;
using SDL_JoystickID = int32_t;

enum SDL_bool { SDL_FALSE = 0, SDL_TRUE = 1 };

struct SDL_Joystick {
    SDL_JoystickID instanceId;
};

struct SDL_GameController {
    SDL_Joystick joystick;
    bool attached;
    bool closed;
    bool heldButton;
    Sint16 heldAxis;
    const char* name;
};

int SDL_NumJoysticks();
SDL_bool SDL_IsGameController(int deviceIndex);
SDL_JoystickID SDL_JoystickGetDeviceInstanceID(int deviceIndex);
SDL_bool SDL_JoystickIsVirtual(int deviceIndex);
SDL_GameController* SDL_GameControllerOpen(int deviceIndex);
void SDL_GameControllerClose(SDL_GameController* gamepad);
SDL_bool SDL_GameControllerGetAttached(SDL_GameController* gamepad);
SDL_Joystick* SDL_GameControllerGetJoystick(SDL_GameController* gamepad);
SDL_JoystickID SDL_JoystickInstanceID(SDL_Joystick* joystick);
const char* SDL_GameControllerName(SDL_GameController* gamepad);
Uint8 SDL_GameControllerGetButton(SDL_GameController* gamepad, int button);
Sint16 SDL_GameControllerGetAxis(SDL_GameController* gamepad, int axis);
const char* SDL_GetError();
