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

const QUIT_KEYS = &[_]rl.KeyboardKey {
    rl.KeyboardKey.KEY_Q
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

fn isQuitKeyDown() bool {
    return isKeyDown(QUIT_KEYS);
}

const SPEED = 200.0;

const Transform = struct {
    pos: rl.Vector2,
    rot: f32,

    const Self = @This();

    pub fn init() Self {
        return Transform {
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
};

const Id = usize;

const Drawable = *const fn(world: *World, id: Id) void;

fn drawRectangle(world: *World, id: Id) void {
    const trans = world.transforms[id];
    const rect = rl.Rectangle {
        .x = trans.pos.x,
        .y = trans.pos.y,
        .width = 40,
        .height = 40,
    };
    rl.DrawRectanglePro(rect, rl.Vector2 { .x = 20.0, .y = 20.0 }, trans.rot, rl.RED);
}

const NUM_ENTITIES = 1024;

const Entity = struct {
    transform: usize,
    drawable: usize,
};

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const World = struct {
    id_counter: usize = 0,
    transforms: [NUM_ENTITIES]Transform = undefined,
    drawables: [NUM_ENTITIES]Drawable = undefined,

    players: std.ArrayList(Id) = std.ArrayList(Id).init(allocator),

    const Self = @This();

    pub fn init() Self {
        return Self {};
    }

    fn updatePlayers(self: *Self, dt: f32) !void {
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

        for (self.players.items) |player_id| {
            var transform = self.getTransform(player_id);
            transform.rot += SPEED * dt;
            transform.move(dir.scale(SPEED * dt));
        }
    }

    pub fn update(self: *Self, dt: f32) !void {
        try self.updatePlayers(dt);
    }

    fn drawPlayers(self: *Self) void {
        for (self.players.items) |player_id| {
            self.drawables[player_id](self, player_id);
        }
    }

    pub fn draw(self: *Self) void {
        self.drawPlayers();
    }

    pub fn getTransform(self: *Self, id: Id) *Transform {
        return &self.transforms[id];
    }

    pub fn newPlayer(self: *Self, pos: rl.Vector2) !Id {
        const id = self.id_counter;
        self.id_counter += 1;

        var trans = Transform.init();
        trans.pos = pos;
        self.transforms[id] = trans;
        self.drawables[id] = drawRectangle;

        try self.players.append(id);

        return id;
    }
};

fn shouldQuit() bool {
    return rl.WindowShouldClose() or isQuitKeyDown();
}

pub fn main() !void {
    rl.InitWindow(800, 800, "hello world!");
    rl.SetConfigFlags(rl.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = true });
    rl.SetTargetFPS(60);

    defer rl.CloseWindow();

    var world = World.init();
    _ = try world.newPlayer(rl.Vector2 { .x = 100, .y = 100 });
    _ = try world.newPlayer(rl.Vector2 { .x = 200, .y = 200 });
    _ = try world.newPlayer(rl.Vector2 { .x = 300, .y = 300 });

    while (!shouldQuit()) {
        var dt = rl.GetFrameTime();

        try world.update(dt);

        rl.BeginDrawing();
        rl.ClearBackground(rl.BLACK);
        rl.DrawFPS(10, 10);

        world.draw();

        rl.EndDrawing();
    }
}
