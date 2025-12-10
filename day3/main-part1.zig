const std = @import("std");

fn get_max(buffer_num: []u8) !usize {
    var max_buf: [2]u8 = .{ '0', '0' };
    var value: usize = 0;
    for (0.., buffer_num) |i, value1| {
        for (buffer_num[i + 1 ..]) |value2| {
            // std.debug.print("i {} j {} value1 {c} value2 {c}\n", .{ i, j, value1, value2 });
            max_buf[0] = value1;
            max_buf[1] = value2;
            const actual_value = try std.fmt.parseInt(usize, &max_buf, 10);
            if (value < actual_value) {
                // std.debug.print("Update value from {} to {}\n", .{ value, actual_value });
                value = actual_value;
            }
        }
    }
    std.debug.print("Max for {s} value {}\n", .{ buffer_num, value });
    return value;
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile("day2-input.txt", .{});
    var buffer: [1024]u8 = undefined;
    var reader = file.reader(&buffer);

    var sum: usize = 0;
    sum = 0;

    while (try reader.interface.takeDelimiter('\n')) |item| {
        std.debug.print("{s}\n", .{item});

        sum += try get_max(item);
    }

    std.debug.print("Sum: {}\n", .{sum});
}
