const std = @import("std");

const NUM_NEED = 12;
fn get_max(buffer_num: []u8) !usize {
    var max_buf: [NUM_NEED]u8 = @splat('0');
    var last_selected: isize = -1;

    std.debug.print("buffer_num {s}\n", .{buffer_num});
    for (0..NUM_NEED) |num_i| {
        const prev_last_selected = last_selected + 1;
        const posible_nums = buffer_num[@intCast(last_selected + 1) .. buffer_num.len - (NUM_NEED - 1 - num_i)];
        std.debug.print("posible_nums {s}\n", .{posible_nums});
        var i = posible_nums.len;
        while (i > 0) : (i -= 1) {
            const num = posible_nums[i - 1];

            std.debug.print("num_i {} i {} Compare {c} to {c}\n", .{ num_i, i - 1, max_buf[num_i], num });
            if (max_buf[num_i] <= num) {
                max_buf[num_i] = num;
                last_selected = prev_last_selected + @as(isize, @intCast(i)) - 1;

                std.debug.print("last_selected {} max_buf[{}] {c}\n", .{ last_selected, num_i, max_buf[num_i] });
            }
        }
        std.debug.print("max_buf {s}\n", .{max_buf});
    }
    const value = try std.fmt.parseInt(usize, &max_buf, 10);
    std.debug.print("Max for {s} value {}\n", .{ buffer_num, value });
    return value;
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile("day3-input.txt", .{});
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
