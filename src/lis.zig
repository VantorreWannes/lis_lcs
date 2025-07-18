const std = @import("std");
const testing = std.testing;

const NO_PREDECESSORS = std.math.maxInt(usize);

/// Finds the longest increasing subsequence in a slice of elements.
///
/// An increasing subsequence is a sequence of elements from the input slice
/// that are in increasing order. This function finds the longest such subsequence.
/// The algorithm used is a variation of Patience sorting, which has a time
/// complexity of O(n log n), where n is the length of the input slice.
///
/// # Parameters
///
/// - `T`: The type of elements in the slice. Must be an ordered type.
/// - `allocator`: The memory allocator to use for intermediate and result allocations.
/// - `input`: The slice to find the LIS from.
///
/// # Returns
///
/// A new slice containing the longest increasing subsequence, allocated by `allocator`.
/// The caller is responsible for freeing this memory.
/// Returns an error if memory allocation fails.
pub fn longestIncreasingSubsequence(
    comptime T: type,
    allocator: std.mem.Allocator,
    input: []const T,
) ![]T {
    if (input.len == 0) {
        return &[0]T{};
    }

    var tails = std.ArrayList(T).init(allocator);
    defer tails.deinit();

    var lis_indices = std.ArrayList(usize).init(allocator);
    defer lis_indices.deinit();

    var predecessors = try allocator.alloc(usize, input.len);
    defer allocator.free(predecessors);

    for (predecessors) |*p| {
        p.* = NO_PREDECESSORS;
    }

    const Ctx = struct {
        fn compare(context_num: T, slice_item: T) std.math.Order {
            return std.math.order(context_num, slice_item);
        }
    };

    for (input, 0..) |num, input_index| {
        const tails_index = std.sort.lowerBound(T, tails.items, num, Ctx.compare);

        if (tails_index > 0) {
            predecessors[input_index] = lis_indices.items[tails_index - 1];
        }

        if (tails_index == tails.items.len) {
            try tails.append(num);
            try lis_indices.append(input_index);
        } else {
            tails.items[tails_index] = num;
            lis_indices.items[tails_index] = input_index;
        }
    }

    const lis_len = tails.items.len;
    if (lis_len == 0) {
        return &[0]T{};
    }

    const result = try allocator.alloc(T, lis_len);

    var current_idx = lis_indices.items[lis_len - 1];
    var result_idx = lis_len;

    while (current_idx != NO_PREDECESSORS) {
        result_idx -= 1;
        result[result_idx] = input[current_idx];
        current_idx = predecessors[current_idx];
    }

    return result;
}

test "empty slice" {
    const input: []const u32 = &[_]u32{};
    const result = try longestIncreasingSubsequence(u32, testing.allocator, input);
    defer testing.allocator.free(result);
    try testing.expectEqualSlices(u32, &.{}, result);
}

test "single element" {
    const input: []const u32 = &[_]u32{42};
    const result = try longestIncreasingSubsequence(u32, testing.allocator, input);
    defer testing.allocator.free(result);
    try testing.expectEqualSlices(u32, &.{42}, result);
}

test "already sorted" {
    const input: []const u32 = &[_]u32{ 1, 2, 3, 4, 5 };
    const result = try longestIncreasingSubsequence(u32, testing.allocator, input);
    defer testing.allocator.free(result);
    try testing.expectEqualSlices(u32, &.{ 1, 2, 3, 4, 5 }, result);
}

test "reverse sorted" {
    const input: []const i32 = &[_]i32{ 5, 4, 3, 2, 1 };
    const result = try longestIncreasingSubsequence(i32, testing.allocator, input);
    defer testing.allocator.free(result);
    try testing.expectEqualSlices(i32, &.{1}, result);
}

test "general case from wikipedia" {
    const input: []const u32 = &[_]u32{ 0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15 };
    const expected: []const u32 = &[_]u32{ 0, 2, 6, 9, 11, 15 };
    const result = try longestIncreasingSubsequence(u32, testing.allocator, input);
    defer testing.allocator.free(result);
    try testing.expectEqualSlices(u32, expected, result);
}

test "with duplicates" {
    const input: []const u32 = &[_]u32{ 3, 4, 4, 1, 5, 2, 6 };
    const expected: []const u32 = &[_]u32{ 3, 4, 5, 6 };
    const result = try longestIncreasingSubsequence(u32, testing.allocator, input);
    defer testing.allocator.free(result);
    try testing.expectEqualSlices(u32, expected, result);
}
