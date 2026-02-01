import Testing
@testable import RoomHandling

import Foundation

extension RoomTests {

    @Suite
    struct FieldsTests {

        @Test("Validate fields accepts valid fields", arguments: [
            [],
            ["Email"],
            ["Student ID", "Email"],
            (0..<20).map { String($0) },
        ])
        func test_validateFieldsAcceptsValidFields(_ fields: [String]) throws {
            let room = try createRoom(fields: fields)
            try Self.runFieldValidationTests(room: room, fieldKeys: fields, expected: true)
        }

        @Test("Validate fields rejects extra")
        func test_validateFieldsRejectsExtraFields() throws {
            let room = try createRoom()
            let invalidFieldKey = "Phone number"
            var invalidFieldKeys = room.fields
            invalidFieldKeys.append(invalidFieldKey)
            try Self.runFieldValidationTests(
                room: room, 
                fieldKeys: invalidFieldKeys,
                expected: false, 
                expectedExtra: [invalidFieldKey]
            )
        }

        @Test("Validate fields rejects too few fields")
        func test_validateFieldsRejectsTooFewFields() async throws {
            let extraFields = ["extra field"]
            let room = try createRoom(fields: defaultFields + extraFields)
            try Self.runFieldValidationTests(
                room: room, 
                fieldKeys: defaultFields, 
                expected: false,
                expectedMissing: extraFields
            )
        }

        static func runFieldValidationTests(
            room: some RoomProtocol,
            fieldKeys: some Collection<String>,
            expected: Bool = true,
            expectedMissing: [String] = [],
            expectedExtra: [String] = []
        ) throws {
            var extraFields = [String]()
            var missingFields = [String]()
            #expect(room.validateFieldKeys(fieldKeys) == expected)
            #expect(room.validateFieldKeys(fieldKeys, missingFields: &missingFields, extraFields: &extraFields) == expected)
            #expect(missingFields == expectedMissing)
            #expect(extraFields == expectedExtra)

            // Intentionally do not reset extraFields and missingFields here, 
            // the function being called should do it by itself
            let fields = Dictionary(uniqueKeysWithValues: fieldKeys.map { ($0, UUID().uuidString) })
            #expect(room.validateFields(fields) == expected)
            #expect(room.validateFields(fields, missingFields: &missingFields, extraFields: &extraFields) == expected)
            #expect(missingFields == expectedMissing)
            #expect(extraFields == expectedExtra)
        }

    }

}
