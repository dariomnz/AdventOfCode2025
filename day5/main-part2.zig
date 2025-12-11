const std = @import("std");
const FormatoConSeparador = struct {
    value: usize,
    separator: u8 = '.',

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        // Convertir el número a una cadena temporal de bytes.
        // Asignamos una matriz lo suficientemente grande para cualquier usize.
        var buf: [128]u8 = undefined;
        const number_slice = std.fmt.bufPrint(&buf, "{}", .{self.value}) catch return std.Io.Writer.Error.WriteFailed;

        var char_index = number_slice.len;
        var digits_count: usize = 0;

        // Reservar espacio suficiente en el escritor (esto podría ser una optimización)
        // El peor caso es cada 3 dígitos + 1 para el separador.
        // Como estamos yendo hacia atrás y escribiendo, simplemente escribiremos.

        // Dado que std.fmt.allocPrint no permite ir hacia atrás fácilmente
        // con la salida final, la manera más simple es construir la cadena
        // final en un ArrayList y luego escribirla.
        var list = std.ArrayList(u8).initCapacity(std.heap.page_allocator, 128) catch return std.Io.Writer.Error.WriteFailed;
        defer list.deinit(std.heap.page_allocator);

        // Recorrer los dígitos del número de atrás hacia adelante
        while (char_index > 0) {
            char_index -= 1;
            list.append(std.heap.page_allocator, number_slice[char_index]) catch return std.Io.Writer.Error.WriteFailed;
            digits_count += 1;

            // Insertar el separador después de cada 3 dígitos, si quedan más dígitos.
            if (digits_count % 3 == 0 and char_index > 0) {
                list.append(std.heap.page_allocator, self.separator) catch return std.Io.Writer.Error.WriteFailed;
            }
        }

        // La cadena está al revés en 'list', así que la invertimos al escribirla.
        var i: usize = list.items.len;
        while (i > 0) {
            i -= 1;
            try writer.writeByte(list.items[i]);
        }
    }
};

const range = struct {
    start: usize,
    end: usize,

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("[{f}   {f}] size {f}", .{
            FormatoConSeparador{ .value = self.start },
            FormatoConSeparador{ .value = self.end },
            FormatoConSeparador{ .value = self.end + 1 - self.start },
        });
    }
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

        self.merge();
    }

    pub fn mergeOne(self: *@This()) bool {
        for (0.., self.data.items) |i, ran1| {
            for (0.., self.data.items) |j, *ran2| {
                if (i == j) continue;
                {
                    if ((ran1.start <= ran2.end and ran2.start - 1 <= ran1.end) or (ran2.start <= ran1.end - 1 and ran1.start <= ran2.end)) {
                        std.debug.print("merge: {f} {f}\n", .{ ran1, ran2 });
                        ran2.start = @min(ran1.start, ran2.start);
                        ran2.end = @max(ran1.end, ran2.end);
                        std.debug.print("merge result: {f}\n", .{ran2});
                        _ = self.data.swapRemove(i);
                        return true;
                    }
                }
                // {
                //     const value = ran1.end;
                //     if (value >= ran2.start and value <= ran2.end) {
                //         std.debug.print("merge end: {}-{} {}-{}\n", .{ ran1.start, ran1.end, ran2.start, ran2.end });
                //         if (ran1.start < ran2.start) {
                //             ran2.start = ran1.start;
                //         }
                //         if (ran1.end > ran2.end) {
                //             ran2.end = ran1.end;
                //         }
                //         std.debug.print("merge end result: {}-{}\n", .{ ran2.start, ran2.end });
                //         _ = self.data.swapRemove(i);
                //         return true;
                //     }
                // }
            }
        }
        return false;
    }

    pub fn merge(self: *@This()) void {
        std.debug.print("---------------------------------------\n", .{});
        while (self.mergeOne()) {}
        std.debug.print("-------------Unique nums {f}------------\n", .{FormatoConSeparador{ .value = self.unique_nums() }});
        // self.print();
    }

    pub fn in_range(self: *@This(), value: usize) bool {
        for (self.data.items) |ran| {
            if (value >= ran.start and value <= ran.end) {
                return true;
            }
        }
        return false;
    }

    pub fn unique_nums(self: *@This()) usize {
        var sum: usize = 0;
        for (self.data.items) |ran| {
            const to_sum = ran.end - ran.start + 1;
            sum += to_sum;
            // std.debug.print("Unique_nums to sum: {} sum: {}\n", .{ to_sum, sum });
        }
        return sum;
    }

    pub fn print(self: *@This()) void {
        self.sort();
        std.debug.print("Ranges: {}\n", .{self.data.items.len});
        for (0.., self.data.items) |i, value| {
            std.debug.print("Range[{}]: {f}\n", .{ i, value });
        }
    }

    fn sort_range(_: void, ran1: range, ran2: range) bool {
        return ran1.start < ran2.start;
    }

    pub fn sort(self: *@This()) void {
        std.mem.sort(range, self.data.items, {}, sort_range);
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
            const ran: range = .{ .start = value1, .end = value2 };
            std.debug.print("range: {f}\n", .{ran});
            try ranges_list.append(ran);
        } else {
            const value = try std.fmt.parseInt(usize, item, 10);
            const is_fresh = ranges_list.in_range(value);
            if (is_fresh) {
                sum += 1;
            }
            // std.debug.print("value: {s} {} in range {}\n", .{ item, value, is_fresh });
        }
    }
    ranges_list.print();
    std.debug.print("sum: {} unique nums: {}\n", .{ sum, ranges_list.unique_nums() });
}
