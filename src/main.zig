const std = @import("std");
const lex = @import("lex.zig");
const compile = @import("compile.zig");

const ArgsError = error{
    NotEnough,
};

extern fn startvm(*u32, *f64, *f64) compile.Value;

pub fn main() !void {
    var args = std.process.args();
    _ = args.next();
    var source = args.next() orelse return ArgsError.NotEnough;

    var l = lex.new_tokenizer(source[0..source.len]);

    var bytecode = [_]compile.ByteCode{compile.ByteCode{ .bits = 0 }} ** 3;
    var constants = [_]compile.Value{0.0} ** 3;

    try compile.compile_expr(&l, &bytecode, &constants);

    var call_frame = [_]compile.Value{0.0} ** 3;
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
