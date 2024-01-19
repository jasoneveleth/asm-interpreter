const std = @import("std");

// interpreter value
const Value = f64;

// byte code
// 1 byte fields
// | B | C | A | op |
// |   D   | A | op |
// MSB             LSB
const ByteCode = u32;

extern fn startvm(*const u32, *const f64, *const f64) Value;

pub fn main() !void {
    const load_2f_to_0 = 0x00010001;
    const load_5f_to_1 = 0x00020101;
    const add_0_1_to_2 = 0x00010202;
    const halt = 0xdddd0200;
    const bytecode = [_]u32{ load_2f_to_0, load_5f_to_1, add_0_1_to_2, halt };
    const constants = [_]f64{ 1.0, 2.0, 5.0 };
    var call_frame = [_]f64{ 0.0, 0.0, 0.0 };
    const val = startvm(&bytecode[0], &constants[0], &call_frame[0]);
    std.debug.print("Return from asm is {}\n", .{val});

    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();
    // try stdout.print("Run `zig build test` to run the tests.\n", .{});
    // try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
