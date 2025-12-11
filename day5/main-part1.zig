const std = @import("std");

const range = struct {
    start: usize,
    end: usize,
};

const ranges = struct {
    data: std.ArrayList(range),

    pub fn init() ranges {
        return .{
            .data = std.ArrayList(range).initCapacity(std.heap.page_allocator, 1024) catch unreachable,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.data.deinit(std.heap.page_allocator);
    }

    pub fn append(self: *@This(), item: range) !void {
        try self.data.append(std.heap.page_allocator, item);
    }

    pub fn in_range(self: *@This(), value: usize) bool {
        for (self.data.items) |ran| {
            if (value >= ran.start and value <= ran.end) {
                return true;
            }
        }
        return false;
    }
};

pub fn main() !void {
    const file = try std.fs.cwd().openFile("day5-input.txt", .{});
    var buffer: [1024]u8 = undefined;
    var reader = file.reader(&buffer);

    var ranges_list: ranges = .init();
    defer ranges_list.deinit();

    var sum: usize = 0;
    while (try reader.interface.takeDelimiter('\n')) |item| {
        if (item.len == 0) continue;
        if (std.mem.containsAtLeast(u8, item, 1, "-")) {
            std.debug.print("range: {s}\n", .{item});
            var parse_reader = std.Io.Reader.fixed(item);
            const str1 = try parse_reader.takeDelimiter('-') orelse unreachable;
            const str2 = try parse_reader.takeDelimiter('-') orelse unreachable;
            const value1 = try std.fmt.parseInt(usize, str1, 10);
            const value2 = try std.fmt.parseInt(usize, str2, 10);
            std.debug.print("range: {s} value1: {} value2: {}\n", .{ item, value1, value2 });
            try ranges_list.append(.{ .start = value1, .end = value2 });
        } else {
            const value = try std.fmt.parseInt(usize, item, 10);
            const is_fresh = ranges_list.in_range(value);
            if (is_fresh) {
                sum += 1;
            }
            std.debug.print("value: {s} {} in range {}\n", .{ item, value, is_fresh });
        }
    }
    std.debug.print("sum: {}\n", .{sum});
}
