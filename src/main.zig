const std = @import("std");
const rl = @import("raylib");

fn isKeyDown(comptime keys: []const rl.KeyboardKey) bool {
    inline for (keys) |key| {
        if (rl.IsKeyDown(key)) {
            return true;
        }
    }
    return false;
}

const LEFT_KEYS = &[_]rl.KeyboardKey {
    rl.KeyboardKey.KEY_LEFT,
    rl.KeyboardKey.KEY_A
};

const RIGHT_KEYS = &[_]rl.KeyboardKey {
    rl.KeyboardKey.KEY_RIGHT,
    rl.KeyboardKey.KEY_D
};

const UP_KEYS = &[_]rl.KeyboardKey {
    rl.KeyboardKey.KEY_UP,
    rl.KeyboardKey.KEY_W
};

const DOWN_KEYS = &[_]rl.KeyboardKey {
    rl.KeyboardKey.KEY_DOWN,
    rl.KeyboardKey.KEY_S
};

fn isLeftDown() bool {
    return isKeyDown(LEFT_KEYS);
}

fn isRightDown() bool {
    return isKeyDown(RIGHT_KEYS);
}

fn isUpDown() bool {
    return isKeyDown(UP_KEYS);
}

fn isDownDown() bool {
    return isKeyDown(DOWN_KEYS);
}

const SPEED = 10.0;


const Entity = struct {
    pos: rl.Vector2,
    rot: f32,

    const Self = @This();

    pub fn init() Self {
        return Entity {
            .pos = rl.Vector2 {
                .x = 0.0,
                .y = 0.0,
            },
            .rot = rl.PI / 4.0,
        };
    }

    pub fn move(self: *Self, by: rl.Vector2) void {
        self.pos = self.pos.add(by);
    }

    pub fn draw(self: *Self) void {
        const rect = rl.Rectangle {
            .x = self.pos.x,
            .y = self.pos.y,
            .width = 40,
            .height = 40,
        };
        rl.DrawRectanglePro(rect, rl.Vector2 { .x = 20.0, .y = 20.0 }, self.rot, rl.RED);
    }
};

const World = struct {
    entities: [1024]Entity,
};

pub fn main() void {
    rl.InitWindow(800, 800, "hello world!");
    rl.SetConfigFlags(rl.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = true });
    rl.SetTargetFPS(60);

    defer rl.CloseWindow();

    var entity = Entity.init();

    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        defer rl.EndDrawing();

        var dir = rl.Vector2 { .x = 0, .y = 0 };
        if (isLeftDown()) {
            dir.x -= 1;
        }
        if (isRightDown()) {
            dir.x += 1;
        }
        if (isUpDown()) {
            dir.y -= 1;
        }
        if (isDownDown()) {
            dir.y += 1;
        }

        entity.rot += SPEED;

        rl.ClearBackground(rl.BLACK);
        rl.DrawFPS(10, 10);

        entity.move(dir.scale(SPEED));
        entity.draw();
    }
}
