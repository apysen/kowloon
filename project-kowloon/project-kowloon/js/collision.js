// Simple top-down collision (section 28).
// Walkable space is the union of floor rectangles at the player's level.
// Obstacles are axis-aligned boxes that can switch on and off
// (perspective blockers, the wet fabric, furniture, NPCs).

export const floors = [];     // { x0, x1, z0, z1, y, name }
export const obstacles = [];  // { x0, x1, z0, z1, y, active(), name }

export function addFloor(x0, x1, z0, z1, y, name = "") {
    const f = {
        x0: Math.min(x0, x1), x1: Math.max(x0, x1),
        z0: Math.min(z0, z1), z1: Math.max(z0, z1),
        y, name
    };
    floors.push(f);
    return f;
}

export function addObstacle(x0, x1, z0, z1, y, opts = {}) {
    const o = {
        x0: Math.min(x0, x1), x1: Math.max(x0, x1),
        z0: Math.min(z0, z1), z1: Math.max(z0, z1),
        y,
        name: opts.name || "",
        active: opts.active || (() => true)
    };
    obstacles.push(o);
    return o;
}

const LEVEL_TOLERANCE = 1.0;

function pointOnFloor(x, z, y) {
    for (const f of floors) {
        if (Math.abs(f.y - y) > LEVEL_TOLERANCE) continue;
        if (x >= f.x0 && x <= f.x1 && z >= f.z0 && z <= f.z1) return f;
    }
    return null;
}

export function floorAt(x, z, y) {
    return pointOnFloor(x, z, y);
}

export function circleHitsObstacle(x, z, y, r, ignore = null) {
    for (const o of obstacles) {
        if (o === ignore) continue;
        if (Math.abs(o.y - y) > LEVEL_TOLERANCE) continue;
        if (!o.active()) continue;
        const cx = Math.max(o.x0, Math.min(x, o.x1));
        const cz = Math.max(o.z0, Math.min(z, o.z1));
        const dx = x - cx, dz = z - cz;
        if (dx * dx + dz * dz < r * r) return o;
    }
    return null;
}

// The player's footprint (a square of half-size r) must be fully on floors,
// and the circle must not touch an active obstacle.
export function canStand(x, z, y, r) {
    const pts = [
        [x - r, z - r], [x + r, z - r],
        [x - r, z + r], [x + r, z + r], [x, z]
    ];
    for (const [px, pz] of pts) {
        if (!pointOnFloor(px, pz, y)) return false;
    }
    return !circleHitsObstacle(x, z, y, r);
}

// Axis-separated move so the player slides along walls.
export function resolveMove(pos, dx, dz, r) {
    let moved = false;
    if (dx !== 0 && canStand(pos.x + dx, pos.z, pos.y, r)) {
        pos.x += dx; moved = true;
    }
    if (dz !== 0 && canStand(pos.x, pos.z + dz, pos.y, r)) {
        pos.z += dz; moved = true;
    }
    return moved;
}
