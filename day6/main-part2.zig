const std = @import("std");
const alloc = std.heap.page_allocator;

const op_type = enum {
    none,
    sum,
    mul,
};

const operation = struct {
    data: std.ArrayList(usize),
    operation_type: op_type = .none,

    pub fn init() operation {
        return .{
            .data = std.ArrayList(usize).initCapacity(alloc, 4) catch unreachable,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.data.deinit(alloc);
    }

    pub fn result(self: @This()) usize {
        var res: usize = 0;
        switch (self.operation_type) {
            .sum => {
                res = 0;
                for (self.data.items) |value| {
                    res += value;
                }
            },
            .mul => {
                res = 1;
                for (self.data.items) |value| {
                    res *= value;
                }
            },
            .none => unreachable,
        }
        return res;
    }
};

const file_data = struct {
    data: std.ArrayList(u8),
    width: usize = 0,
    height: usize = 0,

    pub fn init() file_data {
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

    pub fn index(self: *@This(), x: usize, y: usize) !usize {
        if (x < 0 or x >= self.width) return error.OutOfBounds;
        if (y < 0 or y >= self.height) return error.OutOfBounds;
        return y * self.width + x;
    }

    pub fn get(self: *@This(), x: usize, y: usize) !u8 {
        return self.data.items[try self.index(x, y)];
    }
};

pub fn main() !void {
    const fs_file = try std.fs.cwd().openFile("day6-input.txt", .{});
    var buffer: [1024 * 4]u8 = undefined;
    var reader = fs_file.reader(&buffer);

    var operations: std.ArrayList(operation) = try .initCapacity(alloc, 16);
    defer operations.deinit(alloc);

    var file: file_data = .init();
    defer file.deinit();

    // var sum: usize = 0;
    var idx: usize = 0;
    while (try reader.interface.takeDelimiter('\n')) |item| : (idx = 0) {
        file.append(item);
    }

    var empty: i32 = 0;
    var aux_op = operation.init();
    for (0..file.width) |x| {
        empty = 0;
        var aux_buffer: [1024]u8 = undefined;
        var fixed = std.Io.Writer.fixed(&aux_buffer);
        for (0..file.height - 1) |y| {
            const value = try file.get(x, y);
            std.debug.print("Value[{}][{}] {c}\n", .{ x, y, value });
            if (value == ' ') {
                empty += 1;
            } else {
                try fixed.writeByte(value);
            }
        }
        if (empty != file.height - 1) {
            const num = try std.fmt.parseInt(usize, aux_buffer[0..fixed.end], 10);
            try aux_op.data.append(alloc, num);
            std.debug.print("append {}\n", .{num});
        }

        const value = try file.get(x, file.height - 1);
        std.debug.print("Value[{}][{}] {c}\n", .{ x, file.height - 1, value });
        switch (value) {
            ' ' => empty += 1,
            '+' => aux_op.operation_type = .sum,
            '*' => aux_op.operation_type = .mul,
            else => unreachable,
        }

        if (empty == file.height) {
            try operations.append(alloc, aux_op);
            aux_op = operation.init();
        }

        std.debug.print("empty {}\n", .{empty});
    }
    try operations.append(alloc, aux_op);

    var sum: usize = 0;
    for (0.., operations.items) |i, op| {
        const result = op.result();
        sum += result;

        std.debug.print("result[{}]: {}\n", .{ i, result });
    }
    std.debug.print("sum: {}\n", .{sum});
}
