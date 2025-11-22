const std = @import("std");
const debug = std.log.debug;
const defaultLogEnabled = std.log.defaultLogEnabled;

pub fn dumpSlice(slice: []const u8) void {
    if (!defaultLogEnabled(.debug) or slice.len == 0) return;
    var i: usize = 0;
    while (i < slice.len) {
        logSlice32(i, slice[i .. i + 32]);
        i += 32;
    }
    if (i > slice.len) {
        i -= 32;
        logSlice32(i, slice[i..]);
    }
}

fn logSlice32(i: usize, slice: []const u8) void {
    debug("0x{: >4}: 0x{x:0>64}", .{ i, slice });
}
