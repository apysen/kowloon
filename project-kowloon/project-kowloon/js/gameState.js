// Centralized game state. Quest-relevant state lives here and nowhere else.

export const QuestStage = {
    START: 0,
    MEDICINE_RECEIVED: 1,
    REACHED_LAU: 2,
    LAU_PHOTO: 3,
    CATWALK_BLOCKED: 4,
    MET_CHAN: 5,
    SEARCHING_FOR_SON: 6,
    FOUND_SON: 7,
    HELPED_NG: 8,
    FABRIC_MOVED: 9,
    MEDICINE_DELIVERED: 10,
    RETURNED_HOME: 11,
    COMPLETE: 12
};

export const StageNames = Object.fromEntries(
    Object.entries(QuestStage).map(([k, v]) => [v, k])
);

export const DirectionNames = ["NORTH", "WEST", "SOUTH", "EAST"];

export const GameState = {
    chapter: 0,
    stage: QuestStage.START,
    objective: "",
    hint: "",

    cameraDirection: 0,
    hasRotated: false,

    controlsLocked: false,

    flags: {
        receivedCamera: false,
        photographedLau: false,
        metChan: false,
        foundChanSon: false,
        helpedNg: false,
        fabricMoved: false,
        deliveredMedicine: false,
        returnedHome: false,
        rooftopVisited: false,
        roofDoorOpen: false,
        pigeonFound: false
    },

    scrapbook: [],
    dialogueHistory: [],

    timings: {},
    startTime: 0,
    debug: false
};

// Several systems can lock movement at once (dialogue, rotation, camera mode,
// climbing). Movement is allowed only when nothing holds a lock.
const locks = new Set();

export function lock(reason) {
    locks.add(reason);
    GameState.controlsLocked = true;
}

export function unlock(reason) {
    locks.delete(reason);
    GameState.controlsLocked = locks.size > 0;
}

export function isLocked(reason) {
    return reason ? locks.has(reason) : locks.size > 0;
}

export function lockReasons() {
    return [...locks];
}

// Playtest timing marks (section 84). First occurrence only.
export function markTiming(name) {
    if (name in GameState.timings) return;
    GameState.timings[name] =
        (performance.now() - GameState.startTime) / 1000;
}

// Tiny event bus so systems can react without importing each other.
const listeners = {};

export function on(event, fn) {
    (listeners[event] ||= []).push(fn);
}

export function emit(event, payload) {
    (listeners[event] || []).forEach(fn => fn(payload));
}
