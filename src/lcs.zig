const std = @import("std");
const lis = @import("lis.zig");
const testing = std.testing;

pub const LongestCommonSubsequenceError = error{
    OutOfMemory,
} || lis.LongestIncreasingSubsequenceError;

fn sliceCounts(comptime T: type, allocator: std.mem.Allocator, slice: []const T) LongestCommonSubsequenceError!std.AutoHashMap(T, usize) {
    var counts = std.AutoHashMap(T, usize).init(allocator);
    errdefer counts.deinit();
    for (slice) |value| {
        const count = counts.get(value) orelse 0;
        try counts.put(value, count + 1);
    }
    return counts;
}

fn sliceIndexes(comptime T: type, allocator: std.mem.Allocator, slice: []const T) LongestCommonSubsequenceError!std.AutoHashMap(T, std.ArrayList(usize)) {
    var counts = try sliceCounts(T, allocator, slice);
    defer counts.deinit();
    var indexes = std.AutoHashMap(T, std.ArrayList(usize)).init(allocator);
    errdefer deinitSliceIndexes(T, allocator, &indexes);

    var key_it = counts.keyIterator();
    while (key_it.next()) |key| {
        const value = key.*;
        const count = counts.get(value).?;
        var value_indexes = try std.ArrayList(usize).initCapacity(allocator, count);
        errdefer value_indexes.deinit(allocator);
        try indexes.put(value, value_indexes);
    }

    for (slice, 0..) |value, index| {
        var value_indexes_ptr = indexes.getPtr(value).?;
        try value_indexes_ptr.append(allocator, index);
    }

    return indexes;
}

fn deinitSliceIndexes(comptime T: type, allocator: std.mem.Allocator, indexes: *std.AutoHashMap(T, std.ArrayList(usize))) void {
    var iterator = indexes.valueIterator();
    while (iterator.next()) |value| value.deinit(allocator);
    indexes.deinit();
}

/// Computes the longest common subsequence (LCS) between two slices.
///
/// The LCS is the longest subsequence that is present in both input slices.
/// This implementation uses an algorithm that reduces the LCS problem to the
/// Longest Increasing Subsequence (LIS) problem, which is efficient for
/// cases where the alphabet of the slices is small or when there are few
/// common elements.
///
/// # Parameters
///
/// - `T`: The type of elements in the slices. Must be comparable.
/// - `allocator`: The memory allocator to use for intermediate and result allocations.
/// - `source`: The first slice.
/// - `target`: The second slice.
///
/// # Returns
///
/// A new slice containing the longest common subsequence, allocated by `allocator`.
/// The caller is responsible for freeing this memory.
/// Returns an error if memory allocation fails.
pub fn longestCommonSubsequence(
    comptime T: type,
    allocator: std.mem.Allocator,
    source: []const T,
    target: []const T,
) LongestCommonSubsequenceError![]T {
    if (source.len == 0 or target.len == 0) {
        return try allocator.alloc(T, 0);
    }

    var target_indexes = try sliceIndexes(T, allocator, target);
    defer deinitSliceIndexes(T, allocator, &target_indexes);

    var intermediate: std.ArrayList(usize) = .empty;
    defer intermediate.deinit(allocator);

    for (source) |value| {
        if (target_indexes.get(value)) |indices| {
            var i: usize = indices.items.len;
            while (i > 0) {
                i -= 1;
                try intermediate.append(allocator, indices.items[i]);
            }
        }
    }

    const lis_indices = try lis.longestIncreasingSubsequence(usize, allocator, intermediate.items);
    defer allocator.free(lis_indices);

    const result = try allocator.alloc(T, lis_indices.len);
    errdefer allocator.free(result);

    for (lis_indices, 0..) |target_index, i| {
        result[i] = target[target_index];
    }

    return result;
}

test sliceCounts {
    const slice: []const u32 = &[_]u32{ 1, 2, 2, 3, 3, 3 };
    var result = try sliceCounts(u32, testing.allocator, slice);
    defer result.deinit();
    try testing.expectEqual(result.get(0), null);
    try testing.expectEqual(result.get(1).?, 1);
    try testing.expectEqual(result.get(2).?, 2);
    try testing.expectEqual(result.get(3).?, 3);
}

test sliceIndexes {
    const allocator = testing.allocator;
    const slice: []const u32 = &[_]u32{ 1, 2, 2, 3, 3, 3 };
    var result = try sliceIndexes(u32, allocator, slice);
    defer deinitSliceIndexes(u32, allocator, &result);
    try testing.expectEqual(result.get(0), null);

    const indexes1 = result.get(1).?;
    try testing.expectEqualSlices(usize, &[_]usize{0}, indexes1.items);

    const indexes2 = result.get(2).?;
    try testing.expectEqualSlices(usize, &[_]usize{ 1, 2 }, indexes2.items);

    const indexes3 = result.get(3).?;
    try testing.expectEqualSlices(usize, &[_]usize{ 3, 4, 5 }, indexes3.items);
}

test "sliceIndexes empty slice" {
    const allocator = testing.allocator;
    const slice: []const u32 = &[_]u32{};
    var result = try sliceIndexes(u32, allocator, slice);
    defer deinitSliceIndexes(u32, allocator, &result);
    try testing.expectEqual(@as(usize, 0), result.count());
}

test longestCommonSubsequence {
    const source = "XMJYAUZ";
    const target = "MZJAWXU";
    const expected = "MJAU";
    const result = try longestCommonSubsequence(u8, testing.allocator, source, target);
    defer testing.allocator.free(result);
    try testing.expectEqualSlices(u8, expected, result);
}
