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

const ZOOM_IN_KEYS = &[_]rl.KeyboardKey {
    rl.KeyboardKey.KEY_I
};

const ZOOM_OUT_KEYS = &[_]rl.KeyboardKey {
    rl.KeyboardKey.KEY_O
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

fn isZoomInDown() bool {
    return isKeyDown(ZOOM_IN_KEYS);
}

fn isZoomOutDown() bool {
    return isKeyDown(ZOOM_OUT_KEYS);
}

const SPEED = 200.0;

const Transform = struct {
    pos: rl.Vector2,
    rot: f32,
    scale: f32,

    const Self = @This();

    pub fn init() Self {
        return Transform {
            .pos = rl.Vector2 {
                .x = 0.0,
                .y = 0.0,
            },
            .rot = rl.PI / 4.0,
            .scale = 1.0,
        };
    }

    pub fn move(self: *Self, by: rl.Vector2) void {
        self.pos = self.pos.add(by);
    }
};

const Id = usize;

const Drawable = *const fn(world: *World, id: Id) void;
const Updater = *const fn(world: *World, id: Id, dt: f32) void;

fn drawRectangle(world: *World, id: Id) void {
    const trans = world.getTransform(id);
    const rect = rl.Rectangle {
        .x = trans.pos.x,
        .y = trans.pos.y,
        .width = 40,
        .height = 40,
    };
    rl.DrawRectanglePro(rect, rl.Vector2 { .x = 20.0, .y = 20.0 }, trans.rot, rl.GREEN);
}

fn drawCircle(world: *World, id: Id) void {
    const trans = world.getTransform(id);
    rl.DrawCircle(@intFromFloat(trans.pos.x), @intFromFloat(trans.pos.y), 30, rl.RED);
}

const ColorStart = rl.RED;
const ColorEnd = rl.BLUE;

fn drawMandelbrot(world: *World, id: Id) void {
    const trans = world.getTransform(id);

    const w = 200;
    const h = 200;

    const scale = trans.scale;

    for (0..h) |y| {
        for (0..w) |x| {
            var cR: f32 = ((((@as(f32, @floatFromInt(x)) + trans.pos.x) / @as(f32, @floatFromInt(w))) * 2.0) - 1.0) * scale;
            var cI: f32 = ((((@as(f32, @floatFromInt(y)) + trans.pos.y) / @as(f32, @floatFromInt(h))) * 2.0) - 1.0) * scale;
            var valueR: f32 = 0;
            var valueI: f32 = 0;
            var iteration: usize = 0;
            for (0..10) |i| {
                var newValueR = valueR * valueR - valueI * valueI;
                var newValueI = 2.0 * valueR * valueI;

                valueR = newValueR + cR;
                valueI = newValueI + cI;

                var absValue = valueR * valueR + valueI * valueI;
                if (absValue > 4.0) {
                    iteration = i;
                    var pixelColor = ColorStart.lerp(ColorEnd, @as(f32, @floatFromInt(iteration)) / 10.0);
                    rl.DrawPixel(
                        @as(i32, @intCast(x)),
                        @as(i32, @intCast(y)),
                        pixelColor
                    );
                    break;
                }
            }
        }
    }
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
    updaters: [NUM_ENTITIES]Updater = undefined,

    players: std.ArrayList(Id) = std.ArrayList(Id).init(allocator),
    enemies: std.ArrayList(Id) = std.ArrayList(Id).init(allocator),
    other: std.ArrayList(Id) = std.ArrayList(Id).init(allocator),

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

    fn updateOthers(self: *Self, dt: f32) !void {
        var dir = rl.Vector2 { .x = 0, .y = 0 };
        var zoom: f32 = 1;
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
        if (isZoomInDown()) {
            zoom = 1.1;
        }
        if (isZoomOutDown()) {
            zoom = 0.9;
        }

        for (self.other.items) |other_id| {
            var transform = self.getTransform(other_id);
            transform.move(dir.scale(SPEED * dt));
            transform.scale *= zoom;
        }
    }

    pub fn update(self: *Self, dt: f32) !void {
        try self.updatePlayers(dt);
        try self.updateOthers(dt);
    }

    fn drawPlayers(self: *Self) void {
        for (self.players.items) |player_id| {
            self.drawables[player_id](self, player_id);
        }
    }

    fn drawEnemies(self: *Self) void {
        for (self.enemies.items) |enemy_id| {
            self.drawables[enemy_id](self, enemy_id);
        }
    }

    fn drawOther(self: *Self) void {
        for (self.other.items) |other_id| {
            self.drawables[other_id](self, other_id);
        }
    }

    pub fn draw(self: *Self) void {
        self.drawPlayers();
        self.drawEnemies();
        self.drawOther();
    }

    pub fn getTransform(self: *Self, id: Id) *Transform {
        return &self.transforms[id];
    }

    fn nextId(self: *Self) Id {
        self.id_counter += 1;
        return self.id_counter - 1;
    }

    fn newEntity(self: *Self, pos: rl.Vector2, drawFunc: Drawable) Id {
        const id = self.nextId();

        var trans = Transform.init();
        trans.pos = pos;
        self.transforms[id] = trans;
        self.drawables[id] = drawFunc;

        return id;
    }

    pub fn newPlayer(self: *Self, pos: rl.Vector2) !Id {
        var id = self.newEntity(pos, drawRectangle);
        try self.players.append(id);
        return id;
    }

    pub fn newEnemy(self: *Self, pos: rl.Vector2) !Id {
        var id = self.newEntity(pos, drawCircle);
        try self.enemies.append(id);
        return id;
    }

    pub fn newMandelbrot(self: *Self, pos: rl.Vector2) !Id {
        var id = self.newEntity(pos, drawMandelbrot);
        try self.other.append(id);
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

    _ = try world.newEnemy(rl.Vector2 { .x = 400, .y = 500 });
    _ = try world.newEnemy(rl.Vector2 { .x = 400, .y = 600 });
    _ = try world.newEnemy(rl.Vector2 { .x = 400, .y = 700 });

    _ = try world.newMandelbrot(rl.Vector2 { .x = 200, .y = 200 });

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
