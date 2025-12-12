const std = @import("std");
const alloc = std.heap.page_allocator;

const map = struct {
    data: std.ArrayList(u8),
    width: usize = 0,
    height: usize = 0,

    pub fn init() map {
        return .{
            .data = std.ArrayList(u8).initCapacity(alloc, 4) catch unreachable,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.data.deinit(alloc);
    }

    pub fn append(self: *@This(), buffer: []u8) void {
        self.data.appendSlice(alloc, buffer) catch unreachable;
        if (self.width == 0) {
            self.width = buffer.len;
        } else if (self.width != buffer.len) {
            unreachable;
        }
        self.height += 1;
    }

    pub fn index(self: @This(), x: usize, y: usize) !usize {
        if (x < 0 or x >= self.width) return error.OutOfBounds;
        if (y < 0 or y >= self.height) return error.OutOfBounds;
        return y * self.width + x;
    }

    pub fn get(self: @This(), x: usize, y: usize) !u8 {
        return self.data.items[try self.index(x, y)];
    }
    pub fn set(self: @This(), x: usize, y: usize, value: u8) !void {
        self.data.items[try self.index(x, y)] = value;
    }

    pub fn get_start(self: @This()) struct { x: usize, y: usize } {
        var ret_x: usize = 0;
        for (0..self.width) |x| {
            if (self.data.items[self.index(x, 0) catch unreachable] == 'S') {
                ret_x = x;
            }
        }
        return .{ .x = ret_x, .y = 0 };
    }

    pub fn print(self: @This()) void {
        std.debug.print("Map width {} height {}\n", .{ self.width, self.height });
        for (1.., self.data.items) |i, value| {
            std.debug.print("{c}", .{value});
            if (@mod(i, self.width) == 0) {
                std.debug.print("\n", .{});
            }
        }
    }
};

pub fn main() !void {
    const file = try std.fs.cwd().openFile("day7-input.txt", .{});
    var buffer: [1024 * 4]u8 = undefined;
    var reader = file.reader(&buffer);

    var tree_map = map.init();

    while (try reader.interface.takeDelimiter('\n')) |item| {
        tree_map.append(item);
    }

    tree_map.print();

    const start = tree_map.get_start();
    std.debug.print("Start: {any}\n", .{start});

    var lines = std.AutoHashMap(usize, usize).init(alloc);
    defer lines.deinit();

    try lines.put(start.x, 1);

    var num_splits: usize = 0;
    var num_posibilities: usize = 1;
    for (1..tree_map.height) |y| {
        for (0..tree_map.width) |x| {
            if (!lines.contains(x)) continue;

            const value = try tree_map.get(x, y);
            const line_value = lines.get(x) orelse 0;
            if (value == '.') {
                try tree_map.set(x, y, '|');
                try lines.put(x, line_value);
            } else if (value == '^') {
                const line_value_left = lines.get(x - 1) orelse 0;
                const line_value_right = lines.get(x + 1) orelse 0;
                num_splits += 1;
                num_posibilities += line_value;
                {
                    try tree_map.set(x - 1, y, '|');
                    try lines.put(x - 1, line_value_left + line_value);
                    std.debug.print("left lines.put {} to {} before{}\n", .{ x - 1, line_value_left + line_value, line_value_left });
                }
                {
                    try tree_map.set(x + 1, y, '|');
                    try lines.put(x + 1, line_value_right + line_value);
                    std.debug.print("right lines.put {} to {} before{}\n", .{ x + 1, line_value_right + line_value, line_value_right });
                }
                _ = lines.remove(x);
            }
        }
        std.debug.print("-----------------------------------------------------\n", .{});
        tree_map.print();
        std.debug.print("----------------num_splits: {}-----------------------\n", .{num_splits});
    }

    std.debug.print("num_splits: {}\n", .{num_splits});

    var num_pos: usize = 0;
    var iter = lines.iterator();
    while (iter.next()) |val| {
        std.debug.print("entry: {} {}\n", .{ val.key_ptr.*, val.value_ptr.* });
        num_pos += val.value_ptr.*;
    }

    std.debug.print("num_pos: {}\n", .{num_pos});
    std.debug.print("num_posibilities: {}\n", .{num_posibilities});
}
