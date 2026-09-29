import { QuestStage as S } from "../gameState.js";

// Objectives remind; they never solve (section 35). No distances, no markers.
export const Objectives = {
    [S.START]: { objective: "", hint: "" },
    [S.MEDICINE_RECEIVED]: {
        objective: "Bring Grandfather's medicine to Mrs. Wong.",
        hint: "Grandfather said to follow the blue pipe."
    },
    [S.REACHED_LAU]: {
        objective: "Mr. Lau wants a photograph.",
        hint: "Press C to raise the camera."
    },
    [S.LAU_PHOTO]: {
        objective: "Find a way upstairs.",
        hint: "“When you reach Lau's place, go up.”"
    },
    [S.CATWALK_BLOCKED]: {
        objective: "Someone's washing is blocking the catwalk.",
        hint: "It's still dripping. Whoever hung it lives close by."
    },
    [S.MET_CHAN]: {
        objective: "Find Mrs. Chan's son.",
        hint: "“He's probably gone up to the roof again.”"
    },
    [S.SEARCHING_FOR_SON]: {
        objective: "Find Mrs. Chan's son.",
        hint: "“He's probably gone up to the roof again.”"
    },
    [S.FOUND_SON]: {
        objective: "One of Mr. Ng's pigeons won't come down.",
        hint: "“She won't come down unless she can see the way.”"
    },
    [S.HELPED_NG]: {
        objective: "Take Mr. Ng's photograph.",
        hint: "“Get the birds in it.”"
    },
    [S.FABRIC_MOVED]: {
        objective: "Bring Grandfather's medicine to Mrs. Wong.",
        hint: "The Chan boy went to fetch the washing."
    },
    [S.MEDICINE_DELIVERED]: {
        objective: "Return home.",
        hint: ""
    },
    [S.RETURNED_HOME]: { objective: "", hint: "" },
    [S.COMPLETE]: { objective: "", hint: "" }
};

// Linear narrative, spatial freedom (section 58): flags follow the stage.
export function flagsForStage(stage) {
    return {
        receivedCamera: stage >= S.MEDICINE_RECEIVED,
        photographedLau: stage >= S.LAU_PHOTO,
        metChan: stage >= S.MET_CHAN,
        foundChanSon: stage >= S.FOUND_SON,
        helpedNg: stage >= S.HELPED_NG,
        deliveredMedicine: stage >= S.MEDICINE_DELIVERED,
        returnedHome: stage >= S.RETURNED_HOME,
        roofDoorOpen: stage >= S.FABRIC_MOVED
    };
}

// Scrapbook contents implied by a stage (used when jumping stages in debug).
export function scrapbookForStage(stage) {
    const list = [];
    if (stage >= S.LAU_PHOTO) list.push("lau");
    if (stage >= S.FABRIC_MOVED) list.push("ng");
    return list;
}

// Debug teleport points (section 71).
export const TeleportPoints = {
    1: { name: "Apartment", pos: [-8.5, 0, 2] },
    2: { name: "Dentist", pos: [3, 0, -10.5] },
    3: { name: "Mrs. Chan", pos: [-1, 5, -12] },
    4: { name: "Airshaft", pos: [-5, 5, -17.4] },
    5: { name: "Rooftop", pos: [-5, 13, -14.5] },
    6: { name: "Mrs. Wong", pos: [25.5, 5, -12] }
};
