const std = @import("std");

const word_string = @embedFile("5lw.txt");
const word_count = word_string.len / 6;

var buffer = [_]u8{0} ** 100;

const csi = "\x1b[";
const ansi_red = csi ++ "31;1m";
const ansi_green = csi ++ "32;1m";
const ansi_yellow = csi ++ "33;1m";
const ansi_reset = csi ++ "0m";

fn isWord(string: []const u8) bool {
    return std.mem.indexOf(u8, word_string, string) != null;
}

fn isLower(string: []const u8) bool {
    for (string) |c| {
        if (!std.ascii.isLower(c)) return false;
    }
    return true;
}

pub fn main() anyerror!void {
    var stdout = std.io.getStdOut().writer();
    var stdin = std.io.getStdIn().reader();

    const seed = @bitCast(u64, std.time.milliTimestamp());
    var random = std.rand.DefaultPrng.init(seed).random();
    const word_index = random.uintLessThan(usize, word_count);
    const random_word = word_string[6 * word_index .. 6 * word_index + 5];

    var did_win: bool = false;
    var guesses: u8 = 1;
    while (guesses <= 6 and !did_win) {
        try stdout.print(csi ++ "0K" ++ "{}. _____" ++ csi ++ "5D", .{guesses});

        const guess = try stdin.readUntilDelimiter(&buffer, '\n');
        if (!isLower(guess)) {
            try stdout.print(csi ++ "0K" ++ ansi_red ++ "Your guess should only contain lower case letters a-z.\n" ++ ansi_reset ++ csi ++ "2F", .{});
        } else if (guess.len != 5) {
            try stdout.print(csi ++ "0K" ++ ansi_red ++ "Your guess isn't 5 letters long.\n" ++ ansi_reset ++ csi ++ "2F", .{});
        } else if (!isWord(guess)) {
            try stdout.print(csi ++ "0K" ++ ansi_red ++ "{s} is not a known word.\n" ++ ansi_reset ++ csi ++ "2F", .{guess});
        } else {
            try stdout.writeAll(csi ++ "1F" ++ csi ++ "4G");
            did_win = true;
            for (guess) |c, i| {
                if (random_word[i] == c) {
                    try stdout.writeAll(ansi_green);
                } else if (std.mem.indexOfScalar(u8, random_word, c) != null) {
                    try stdout.writeAll(ansi_yellow);
                    did_win = false;
                } else {
                    try stdout.writeAll(ansi_reset);
                    did_win = false;
                }
                try stdout.writeByte(c);
            }
            try stdout.writeAll(ansi_reset ++ "\n");
            guesses += 1;
        }
    }
    if (did_win) {
        try stdout.print("You won! Your score is {}/6.\n", .{guesses});
    } else {
        try stdout.print("You lost. The word was {s}.\n", .{random_word});
    }
}
