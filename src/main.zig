const std = @import("std");
const tok = @import("tok.zig");

// interpreter value
const Value = f64;

// byte code
// 1 byte fields
// | C | B | A | op |
// |   D   | A | op |
// MSB             LSB
const ByteCode = union {
    bits: u32,
    ad: packed struct {
        op: u8,
        a: u8,
        d: u16,
    },
    abc: packed struct {
        op: u8,
        a: u8,
        c: u8,
        b: u8,
    },
};

const ArgsError = error{
    NotEnough,
};

extern fn startvm(*u32, *f64, *f64) Value;

fn compile(l: *tok.Lexer, bytecode: []ByteCode, constants: []Value) void {
    const fslot = 2;
    const cslot = 1;

    l.next();
    const token = l.cur;
    switch (token) {
        tok.Token.num => |val| constants[cslot] = val,
        else => unreachable,
    }

    var load = ByteCode{ .ad = .{ .d = cslot, .a = fslot, .op = 1 } };
    var halt = ByteCode{ .ad = .{ .d = 0xdddd, .a = fslot, .op = 0 } };

    // const load_2f_to_0 = 0x00010001;
    // const load_5f_to_1 = 0x00020101;
    // const add_0_1_to_2 = 0x00010202;
    // const halt         = 0xdddd0200;
    // const bytecode = [_]u32{ load_2f_to_0, load_5f_to_1, add_0_1_to_2, halt };

    bytecode[0] = load;
    bytecode[1] = halt;
}

pub fn main() !void {
    var args = std.process.args();
    _ = args.next();
    var source = args.next() orelse return ArgsError.NotEnough;

    var l = tok.new_tokenizer(source[0..source.len]);

    var bytecode = [_]ByteCode{ByteCode{ .bits = 0 }} ** 3;
    var constants = [_]Value{0.0} ** 3;

    compile(&l, &bytecode, &constants);

    var call_frame = [_]Value{0.0} ** 3;
    const val = startvm(@ptrCast(&bytecode), @ptrCast(&constants), @ptrCast(&call_frame));
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
