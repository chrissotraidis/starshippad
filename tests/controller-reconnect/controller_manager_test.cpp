#include "controller/physicaldevice/ConnectedPhysicalDeviceManager.h"

#include <algorithm>
#include <cassert>
#include <cmath>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

namespace {
struct FakeDevice {
    int32_t instanceId;
    std::string name;
    bool isVirtual = false;
    bool heldButton = false;
    int16_t heldAxis = 0;
    bool openFails = false;
};

std::vector<FakeDevice> gDevices;
std::vector<std::unique_ptr<SDL_GameController>> gHandles;
int gCloseCount = 0;

FakeDevice* FindDevice(int32_t instanceId) {
    const auto it = std::find_if(gDevices.begin(), gDevices.end(), [instanceId](const FakeDevice& device) {
        return device.instanceId == instanceId;
    });
    return it == gDevices.end() ? nullptr : &*it;
}

void SetDevices(std::initializer_list<FakeDevice> devices) {
    gDevices.assign(devices);
    for (auto& handle : gHandles) {
        handle->attached = FindDevice(handle->joystick.instanceId) != nullptr;
    }
}

int AssignedPort(Ship::ConnectedPhysicalDeviceManager& manager, int32_t instanceId) {
    for (uint8_t port = 0; port < 4; port++) {
        if (!manager.PortIsIgnoringInstanceId(port, instanceId)) {
            return port;
        }
    }
    return -1;
}

struct InputState {
    bool button = false;
    int16_t axis = 0;
};

InputState ReadPort(Ship::ConnectedPhysicalDeviceManager& manager, uint8_t port) {
    InputState result;
    for (const auto& [instanceId, gamepad] : manager.GetConnectedSDLGamepadsForPort(port)) {
        (void)instanceId;
        result.button = result.button || SDL_GameControllerGetButton(gamepad, 0) != 0;
        const int16_t axis = SDL_GameControllerGetAxis(gamepad, 0);
        if (std::abs(axis) > std::abs(result.axis)) {
            result.axis = axis;
        }
    }
    return result;
}

void TestMissedRemovalAndStableSlots() {
    Ship::ConnectedPhysicalDeviceManager manager;

    SetDevices({ { 100, "Pad A", false, true, 24000 } });
    assert(manager.ReconcileConnectedSDLGamepads("startup"));
    assert(AssignedPort(manager, 100) == 0);
    assert(ReadPort(manager, 0).button);
    assert(ReadPort(manager, 0).axis == 24000);
    const uint64_t connectedGeneration = manager.GetGeneration();

    // No removal handler is called. Polling must detect the detached stale
    // handle, close it, and expose neutral button and axis state immediately.
    SetDevices({});
    const InputState neutral = ReadPort(manager, 0);
    assert(!neutral.button);
    assert(neutral.axis == 0);
    assert(manager.GetGeneration() == connectedGeneration + 1);
    assert(gCloseCount == 1);

    SetDevices({ { 200, "Pad A" } });
    assert(manager.ReconcileConnectedSDLGamepads("foreground"));
    assert(AssignedPort(manager, 200) == 0);

    SetDevices({ { 200, "Pad A" }, { 300, "Pad B" } });
    assert(manager.ReconcileConnectedSDLGamepads("device-added"));
    assert(AssignedPort(manager, 200) == 0);
    assert(AssignedPort(manager, 300) == 1);

    const uint64_t stableGeneration = manager.GetGeneration();
    assert(!manager.ReconcileConnectedSDLGamepads("active-check"));
    assert(manager.GetGeneration() == stableGeneration);
    assert(AssignedPort(manager, 200) == 0);
    assert(AssignedPort(manager, 300) == 1);

    // Player 1 remains stable while Player 2 changes identity and reclaims
    // the next free port after foreground reconciliation.
    SetDevices({ { 200, "Pad A" }, { 400, "Pad C" } });
    assert(manager.ReconcileConnectedSDLGamepads("foreground"));
    assert(AssignedPort(manager, 200) == 0);
    assert(AssignedPort(manager, 400) == 1);
}

void TestVirtualTouchDoesNotDisplacePhysicalPlayerOne() {
    Ship::ConnectedPhysicalDeviceManager manager;

    SetDevices({ { 500, "Virtual Controller", true } });
    assert(manager.ReconcileConnectedSDLGamepads("startup"));
    assert(AssignedPort(manager, 500) == 0);

    // StarshipPad detaches its virtual analog-touch controller asynchronously.
    // A physical controller must still take Player 1 during that brief overlap.
    SetDevices({ { 500, "Virtual Controller", true }, { 600, "Physical Pad" } });
    assert(manager.ReconcileConnectedSDLGamepads("device-added"));
    assert(AssignedPort(manager, 600) == 0);

    SetDevices({ { 600, "Physical Pad" } });
    assert(manager.ReconcileConnectedSDLGamepads("device-removed"));
    assert(AssignedPort(manager, 600) == 0);
}
} // namespace

int SDL_NumJoysticks() {
    return static_cast<int>(gDevices.size());
}

SDL_bool SDL_IsGameController(int deviceIndex) {
    return deviceIndex >= 0 && deviceIndex < SDL_NumJoysticks() ? SDL_TRUE : SDL_FALSE;
}

SDL_JoystickID SDL_JoystickGetDeviceInstanceID(int deviceIndex) {
    return gDevices.at(deviceIndex).instanceId;
}

SDL_bool SDL_JoystickIsVirtual(int deviceIndex) {
    return gDevices.at(deviceIndex).isVirtual ? SDL_TRUE : SDL_FALSE;
}

SDL_GameController* SDL_GameControllerOpen(int deviceIndex) {
    FakeDevice& device = gDevices.at(deviceIndex);
    if (device.openFails) {
        return nullptr;
    }
    auto handle = std::make_unique<SDL_GameController>();
    handle->joystick.instanceId = device.instanceId;
    handle->attached = true;
    handle->closed = false;
    handle->heldButton = device.heldButton;
    handle->heldAxis = device.heldAxis;
    handle->name = device.name.c_str();
    gHandles.push_back(std::move(handle));
    return gHandles.back().get();
}

void SDL_GameControllerClose(SDL_GameController* gamepad) {
    if (gamepad != nullptr && !gamepad->closed) {
        gamepad->closed = true;
        gamepad->attached = false;
        gCloseCount++;
    }
}

SDL_bool SDL_GameControllerGetAttached(SDL_GameController* gamepad) {
    return gamepad != nullptr && gamepad->attached && !gamepad->closed ? SDL_TRUE : SDL_FALSE;
}

SDL_Joystick* SDL_GameControllerGetJoystick(SDL_GameController* gamepad) {
    return gamepad == nullptr ? nullptr : &gamepad->joystick;
}

SDL_JoystickID SDL_JoystickInstanceID(SDL_Joystick* joystick) {
    return joystick == nullptr ? -1 : joystick->instanceId;
}

const char* SDL_GameControllerName(SDL_GameController* gamepad) {
    return gamepad == nullptr ? nullptr : gamepad->name;
}

Uint8 SDL_GameControllerGetButton(SDL_GameController* gamepad, int button) {
    (void)button;
    return gamepad != nullptr && gamepad->heldButton ? 1 : 0;
}

Sint16 SDL_GameControllerGetAxis(SDL_GameController* gamepad, int axis) {
    (void)axis;
    return gamepad == nullptr ? 0 : gamepad->heldAxis;
}

const char* SDL_GetError() {
    return "fake SDL error";
}

int main() {
    TestMissedRemovalAndStableSlots();
    TestVirtualTouchDoesNotDisplacePhysicalPlayerOne();
    std::cout << "controller manager reconnect tests passed\n";
    return 0;
}
