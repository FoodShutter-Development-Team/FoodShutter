//
//  FoodEmojiMapperTests.swift
//  FoodShutterTesting
//
//  Tests for FoodEmojiMapper keyword matching and fallback behavior.
//

import XCTest
@testable import FoodShutter

final class FoodEmojiMapperTests: XCTestCase {

    // MARK: - Known dish keywords

    func testEmoji_ChineseDish_NoodlesKeyword_ReturnsNoodleEmoji() {
        XCTAssertEqual(FoodEmojiMapper.emoji(for: "炒面"), "🍜")
    }

    func testEmoji_ChineseDish_RiceKeyword_ReturnsRiceEmoji() {
        XCTAssertEqual(FoodEmojiMapper.emoji(for: "蛋炒饭"), "🍳")
    }

    func testEmoji_ChineseDish_DumplingKeyword_ReturnsDumplingEmoji() {
        XCTAssertEqual(FoodEmojiMapper.emoji(for: "饺子"), "🥟")
    }

    func testEmoji_ChineseDish_HotpotKeyword_ReturnsPotEmoji() {
        XCTAssertEqual(FoodEmojiMapper.emoji(for: "火锅"), "🍲")
    }

    // MARK: - Known ingredient keywords

    func testEmoji_EnglishIngredient_Broccoli_ReturnsCorrectEmoji() {
        XCTAssertEqual(FoodEmojiMapper.emoji(for: "broccoli"), "🥦")
    }

    func testEmoji_EnglishIngredient_Tomato_ReturnsCorrectEmoji() {
        XCTAssertEqual(FoodEmojiMapper.emoji(for: "tomato"), "🍅")
    }

    func testEmoji_EnglishIngredient_Bacon_ReturnsCorrectEmoji() {
        XCTAssertEqual(FoodEmojiMapper.emoji(for: "bacon"), "🥓")
    }

    // MARK: - Case insensitivity

    func testEmoji_EnglishName_CaseInsensitive() {
        XCTAssertEqual(FoodEmojiMapper.emoji(for: "Broccoli"),  "🥦")
        XCTAssertEqual(FoodEmojiMapper.emoji(for: "BROCCOLI"),  "🥦")
        XCTAssertEqual(FoodEmojiMapper.emoji(for: "TOMATO"),    "🍅")
    }

    // MARK: - Substring matching

    func testEmoji_PartialMatch_LongerName_StillMatches() {
        // "西红柿炒蛋" contains "蛋" (egg) and "西红柿" (tomato) — first match wins
        let emoji = FoodEmojiMapper.emoji(for: "西红柿炒蛋")
        XCTAssertFalse(emoji.isEmpty)
        XCTAssertNotEqual(emoji, "🍽️")
    }

    // MARK: - Unknown name fallback

    func testEmoji_UnknownName_ReturnsDefaultPlate() {
        XCTAssertEqual(FoodEmojiMapper.emoji(for: "xyzUnknownFood123"), "🍽️")
    }

    func testEmoji_EmptyString_ReturnsDefaultPlate() {
        XCTAssertEqual(FoodEmojiMapper.emoji(for: ""), "🍽️")
    }
}
