const std = @import("std");
const zbench = @import("zbench");
const lcs = @import("lcs.zig");
const lis = @import("lis.zig");

fn randomArray(random: *std.Random, comptime length: comptime_int, comptime alphabet_size: comptime_int) [length]u8 {
    var array: [length]u8 = undefined;
    for (&array) |*num| {
        num.* = random.int(u8) % alphabet_size;
    }
    return array;
}

fn LongestCommonSubsequenceBenchmark(comptime length: comptime_int, comptime alphabet_size: comptime_int) type {
    return struct {
        source: [length]u8,
        target: [length]u8,

        fn init(random: *std.Random) @This() {
            return .{
                .source = randomArray(random, length, alphabet_size),
                .target = randomArray(random, length, alphabet_size),
            };
        }

        pub fn run(self: @This(), _: std.mem.Allocator) void {
            const allocator = std.heap.smp_allocator;
            const subsequence = lcs.longestCommonSubsequence(u8, std.heap.smp_allocator, &self.source, &self.target) catch unreachable;
            defer allocator.free(subsequence);
            std.mem.doNotOptimizeAway(subsequence);
        }
    };
}

fn LongestIncreasingSubsequenceBenchmark(comptime length: comptime_int, comptime alphabet_size: comptime_int) type {
    return struct {
        input: [length]u8,

        fn init(random: *std.Random) @This() {
            return .{
                .input = randomArray(random, length, alphabet_size),
            };
        }

        pub fn run(self: @This(), _: std.mem.Allocator) void {
            const allocator = std.heap.smp_allocator;
            const subsequence = lis.longestIncreasingSubsequence(u8, std.heap.smp_allocator, &self.input) catch unreachable;
            defer allocator.free(subsequence);
            std.mem.doNotOptimizeAway(subsequence);
        }
    };
}

pub fn main() !void {
    var prng = std.Random.DefaultPrng.init(std.testing.random_seed);
    var random = prng.random();

    const stdout = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var bench = zbench.Benchmark.init(allocator, .{});
    defer bench.deinit();

    const lengths = [_]comptime_int{ 10, 100, 250, 500 };
    const alphabet_sizes = [_]comptime_int{ 1, 16, 32 };

    inline for (lengths) |length| {
        inline for (alphabet_sizes) |alphabet_size| {
            const name = std.fmt.comptimePrint(
                "lcs_L{d}_A{d}",
                .{ length, alphabet_size },
            );
            const benchmark = LongestCommonSubsequenceBenchmark(length, alphabet_size).init(&random);
            try bench.addParam(name, &benchmark, .{ .time_budget_ns = 20_000_000 * (length * 3) });
        }
    }

    inline for (lengths) |length| {
        inline for (alphabet_sizes) |alphabet_size| {
            const name = std.fmt.comptimePrint(
                "lis_L{d}_A{d}",
                .{ length, alphabet_size },
            );
            const benchmark = LongestIncreasingSubsequenceBenchmark(length, alphabet_size).init(&random);
            try bench.addParam(name, &benchmark, .{ .time_budget_ns = 20_000_000 * length });
        }
    }

    try stdout.writeAll("\n");
    try bench.run(stdout);
}
