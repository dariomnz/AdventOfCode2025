const std = @import("std");

fn check_id(id: usize) bool {
    var buffer: [1024]u8 = undefined;
    const size = std.fmt.printInt(&buffer, id, 10, .lower, .{});
    // std.debug.print("check_id {s}\n", .{buffer[0..size]});

    for (2..size + 1) |div| {
        if (@mod(size, div) != 0) continue;

        const splices_size = size / div;
        var is_valid = true;
        for (1..div) |value| {
            const start1 = 0;
            const end1 = splices_size;
            const start2 = value * splices_size;
            const end2 = value * splices_size + splices_size;
            // std.debug.print("Compare '{s}' '{s}'\n", .{ buffer[start1..end1], buffer[start2..end2] });
            if (!std.mem.eql(u8, buffer[start1..end1], buffer[start2..end2])) {
                is_valid = false;
            }
        }
        if (is_valid) {
            // std.debug.print("is true {s}\n", .{buffer[0..size]});
            return true;
        }
    }
    return false;
}

fn check_range(start: usize, end: usize) usize {
    var sum: usize = 0;
    for (@intCast(start)..@intCast(end + 1)) |value| {
        if (check_id(@intCast(value))) {
            sum += value;
        }
    }
    return sum;
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile("day2-input.txt", .{});
    var buffer: [1024]u8 = undefined;
    var reader = file.reader(&buffer);

    var sum: usize = 0;

    while (try reader.interface.takeDelimiter(',')) |item| {
        // std.debug.print("{s}\n", .{item});

        var item_reader = std.Io.Reader.fixed(item);

        const value1_str = try item_reader.takeDelimiterExclusive('-');
        const value1 = try std.fmt.parseInt(usize, value1_str, 10);
        _ = try item_reader.takeByte();
        const value2_str = try item_reader.take(item_reader.end - item_reader.seek);
        const value2 = try std.fmt.parseInt(usize, value2_str, 10);

        std.debug.print("1: '{}' 2: '{}'\n", .{ value1, value2 });
        sum += check_range(value1, value2);
    }

    std.debug.print("Sum: {}\n", .{sum});
}
