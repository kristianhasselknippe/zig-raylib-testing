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

pub fn main() void {
    rl.InitWindow(800, 800, "hello world!");
    rl.SetConfigFlags(rl.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = true });
    rl.SetTargetFPS(60);

    defer rl.CloseWindow();

    var pos = rl.Vector2 { .x = 0, .y = 0 };

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

        rl.ClearBackground(rl.BLACK);
        rl.DrawFPS(10, 10);

        pos = pos.add(dir.normalize().scale(SPEED));
        rl.DrawText("hello world!", @intFromFloat(pos.x), @intFromFloat(pos.y), 20, rl.YELLOW);
    }
}
