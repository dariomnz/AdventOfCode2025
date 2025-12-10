const std = @import("std");

const dial = struct {
    position: i32 = 50,
    times_in_0: i32 = 0,
    const max_pos: i32 = 100;

    pub fn change(self: *@This(), pos: i32) void {
        const is_neg = blk: {
            if (pos < 0) {
                break :blk true;
            } else {
                break :blk false;
            }
        };
        for (0..@abs(pos)) |_| {
            var new_pos: i32 = self.position;
            if (is_neg) {
                new_pos -= 1;
            } else {
                new_pos += 1;
            }
            new_pos = @mod(new_pos, max_pos);
            std.debug.print("Change from {} to {}\n", .{ self.position, new_pos });
            self.position = new_pos;
            if (self.position == 0) {
                self.times_in_0 += 1;
            }
        }
    }
};

pub fn main() !void {
    const file = try std.fs.cwd().openFile("day1-input.txt", .{});
    var buffer: [1024]u8 = undefined;
    var reader = file.reader(&buffer);

    var d: dial = .{};
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

        var number = try std.fmt.parseInt(i32, line[1..], 10);
        // const prev_pos = position;
        switch (line[0]) {
            'L' => {
                number = -number;
            },
            'R' => {},
            else => return error.MalformedLine,
        }

        d.change(number);

        // if (prev_pos != 0 and (position < 0 or position > max_pos)) {
        //     const to_add: u32 = @divFloor(@abs(position), max_pos) + 1;
        //     times_in_0 += @intCast(to_add);
        //     std.debug.print("Pass throwth 0 times {} -------------------------------\n", .{to_add});
        // } else if (position == 0 or position == max_pos) {
        //     times_in_0 += 1;
        //     std.debug.print("Is 0 ....................................\n", .{});
        // }
        // const prev_mod_pos = position;
        // position = @mod(position, max_pos);
        // std.debug.print("{s} prev pos {} prev mod pos {} new pos {}\n", .{ line, prev_pos, prev_mod_pos, position });
    }

    std.debug.print("Times in 0: {}\n", .{d.times_in_0});
}
