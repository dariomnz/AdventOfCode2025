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

pub fn main() !void {
    const file = try std.fs.cwd().openFile("day6-input.txt", .{});
    var buffer: [1024 * 4]u8 = undefined;
    var reader = file.reader(&buffer);

    var operations: std.ArrayList(operation) = try .initCapacity(alloc, 16);
    defer operations.deinit(alloc);

    // var sum: usize = 0;
    var idx: usize = 0;
    while (try reader.interface.takeDelimiter('\n')) |item| : (idx = 0) {
        var line_reader = std.Io.Reader.fixed(item);

        std.debug.print("line: {s}\n", .{item});
        while (try line_reader.takeDelimiter(' ')) |str_value| {
            if (str_value.len == 0) continue;
            if (idx >= operations.items.len) {
                try operations.append(alloc, .init());
                std.debug.print("append operation\n", .{});
            }

            std.debug.print("value: {s} len: {} idx: {}\n", .{ str_value, str_value.len, idx });
            if (str_value[0] == '+') {
                operations.items[idx].operation_type = .sum;
            } else if (str_value[0] == '*') {
                operations.items[idx].operation_type = .mul;
            } else {
                const value = try std.fmt.parseInt(usize, str_value, 10);
                try operations.items[idx].data.append(alloc, value);
            }
            idx += 1;
        }
    }

    var sum: usize = 0;
    for (0.., operations.items) |i, op| {
        const result = op.result();
        sum += result;

        std.debug.print("result[{}]: {}\n", .{ i, result });
    }
    std.debug.print("sum: {}\n", .{sum});
}
