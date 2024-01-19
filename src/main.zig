const std = @import("std");

// interpreter value
const Value = f64;

// byte code
// 1 byte fields
// | BC | A | B | C |
// | BC | A |   D   |
const ByteCode = u32;
// movzx  ecx, ah                  Decode RA
// movzx  ebp, al                  Decode opcode
// shr    eax, 0x10                Decode RD (or BC)
//
// if you want to split RD, you'll do it in preamble of byte code:
//
// movzx  ebp, ah                  Decode RC (split of RD)
// movzx  eax, al                  Decode RB (split of RD)

extern fn startvm(*const u32) Value;

pub fn main() !void {
    const bytecode = [_]u32{0xddddaa00};
    const val = startvm(&bytecode[0]);
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
