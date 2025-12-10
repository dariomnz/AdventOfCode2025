const std = @import("std");

const paper_map = struct {
    buffer: []u8,
    out_buffer: []u8,
    width: usize,
    height: usize,

    pub fn init(buffer: []u8, out_buffer: []u8, width: usize, height: usize) paper_map {
        return .{
            .buffer = buffer,
            .out_buffer = out_buffer,
            .width = width,
            .height = height,
        };
    }

    pub fn index(self: *@This(), x: isize, y: isize) !usize {
        if (x < 0 or x >= self.width) return error.OutOfBounds;
        if (y < 0 or y >= self.height) return error.OutOfBounds;
        return @as(usize, @intCast(y)) * self.width + @as(usize, @intCast(x));
    }

    pub fn value(self: *@This(), x: usize, y: usize) !u8 {
        return self.buffer[try self.index(@as(isize, @intCast(x)), @as(isize, @intCast(y)))];
    }

    pub fn neightbours(self: *@This(), _x: usize, _y: usize) usize {
        var num_neightbours: usize = 0;
        const x: isize = @intCast(_x);
        const y: isize = @intCast(_y);
        const x_idx: [3]isize = .{ x - 1, x, x + 1 };
        const y_idx: [3]isize = .{ y - 1, y, y + 1 };
        for (y_idx) |real_y| {
            for (x_idx) |real_x| {
                if (real_x == x and real_y == y) continue;
                const idx = self.index(real_x, real_y) catch continue;
                std.debug.print("x {} y {} real_x {} real_y {} value {c}\n", .{ x, y, real_x, real_y, self.buffer[idx] });
                if (self.buffer[idx] == '@') {
                    num_neightbours += 1;
                }
            }
        }
        std.debug.print("x {} y {} num_neightbours {}\n", .{ x, y, num_neightbours });
        return num_neightbours;
    }
};

pub fn main() !void {
    var width: usize = 0;
    var height: usize = 0;
    const file = try std.fs.cwd().openFile("day4-input.txt", .{});
    var buffer: [1024]u8 = undefined;
    var reader = file.reader(&buffer);

    const alloc = std.heap.page_allocator;
    var array: std.ArrayList(u8) = try .initCapacity(alloc, 1024);
    defer array.deinit(alloc);

    while (try reader.interface.takeDelimiter('\n')) |item| {
        if (width == 0) {
            width = item.len;
        } else {
            if (width != item.len) return error.MapNotSquare;
        }
        height += 1;
        try array.appendSlice(alloc, item);
    }

    std.debug.print("width: {} height: {} actual size {} real size {}\n", .{ width, height, array.items.len, width * height });

    var array2: std.ArrayList(u8) = try .initCapacity(alloc, array.items.len);
    defer array2.deinit(alloc);

    var map: paper_map = .init(array.items, array2.items, width, height);

    var sum: usize = 0;
    for (0..height) |y| {
        for (0..width) |x| {
            if (try map.value(x, y) != '@') continue;
            const neightbours = map.neightbours(x, y);
            if (neightbours < 4) {
                sum += 1;
            }
        }
    }
    std.debug.print("sum: {}\n", .{sum});
}
