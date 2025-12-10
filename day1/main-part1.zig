const std = @import("std");

pub fn main() !void {
    const file = try std.fs.cwd().openFile("day1-input.txt", .{});
    var buffer: [1024]u8 = undefined;
    var reader = file.reader(&buffer);

    var position: i32 = 50;
    const max_pos: i32 = 100;
    var times_in_0: i32 = 0;

    while (true) {
        const line_with_new_line = reader.interface.takeDelimiterInclusive('\n') catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };
        const line = line_with_new_line[0 .. line_with_new_line.len - 1];
        std.log.info("{s}", .{line});
        if (line.len < 2) {
            std.debug.print("Malformed line {s}\n", .{line});
            return error.MalformedLine;
        }

        const number = try std.fmt.parseInt(i32, line[1..], 10);
        const prev_pos = position;
        switch (line[0]) {
            'L' => {
                position = @mod((position - number), max_pos);
                std.debug.print("Left {} prev pos {} new pos {}\n", .{ number, prev_pos, position });
            },
            'R' => {
                position = @mod((position + number), max_pos);
                std.debug.print("Right {} prev pos {} new pos {}\n", .{ number, prev_pos, position });
            },
            else => return error.MalformedLine,
        }

        if (position == 0) {
            times_in_0 += 1;
        }
    }

    std.debug.print("Times in 0: {}\n", .{times_in_0});
}
