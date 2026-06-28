//
//  FieldValueTests.swift
//
import FirestoreProtobuf
import FirestoreRPC
import Testing
@testable import FirestoreAPI

@Suite("FieldValue Tests")
struct FieldValueTests {

    @Test("Delete sentinel is omitted from document fields")
    func testDeleteSentinelIsOmittedFromDocumentFields() throws {
        let documentData = DocumentData(data: [
            "name": "Alice",
            "removed": FieldValue.delete
        ])

        let fields = try documentData.getFields(allowsDelete: true)

        #expect(fields["name"]?.stringValue == "Alice")
        #expect(fields["removed"] == nil)
        #expect(documentData.keys.contains("removed"))
        #expect(try documentData.getFieldTransforms(
            documentPath: "projects/test-project/databases/(default)/documents/users/user123",
            allowsDelete: true
        ).isEmpty)
    }

    @Test("Transform sentinels are omitted from document fields")
    func testTransformSentinelsAreOmittedFromDocumentFields() throws {
        let documentData = DocumentData(data: [
            "updatedAt": FieldValue.serverTimestamp,
            "tags": FieldValue.arrayUnion(["swift"])
        ])

        let fields = try documentData.getFields(allowsDelete: false)
        let transforms = try documentData.getFieldTransforms(
            documentPath: "projects/test-project/databases/(default)/documents/users/user123",
            allowsDelete: false
        )

        #expect(fields["updatedAt"] == nil)
        #expect(fields["tags"] == nil)
        #expect(transforms.contains { transform in
            transform.fieldPath == "updatedAt" && transform.setToServerValue == .requestTime
        })
        #expect(transforms.contains { transform in
            transform.fieldPath == "tags" && transform.appendMissingElements.values.first?.stringValue == "swift"
        })
    }

    @Test("SDK-style FieldValue factories produce sentinels")
    func testSDKStyleFieldValueFactoriesProduceSentinels() throws {
        let documentData = DocumentData(data: [
            "updatedAt": FieldValue.serverTimestamp(),
            "removed": FieldValue.delete(),
            "tags": FieldValue.arrayUnion(["swift"])
        ])

        let fields = try documentData.getFields(allowsDelete: true)
        let transforms = try documentData.getFieldTransforms(
            documentPath: "projects/test-project/databases/(default)/documents/users/user123",
            allowsDelete: true
        )

        #expect(fields["updatedAt"] == nil)
        #expect(fields["removed"] == nil)
        #expect(fields["tags"] == nil)
        #expect(transforms.contains { transform in
            transform.fieldPath == "updatedAt" && transform.setToServerValue == .requestTime
        })
        #expect(transforms.contains { transform in
            transform.fieldPath == "tags" && transform.appendMissingElements.values.first?.stringValue == "swift"
        })
    }

    @Test("FirestoreVector factory supports contextual vector shorthand")
    func testFirestoreVectorFactorySupportsContextualVectorShorthand() {
        let doubleVector: FirestoreVector = .vector([0.12, 0.42, 0.86])
        let floatVector = FirestoreVector.vector([Float(0.12), Float(0.42), Float(0.86)])

        #expect(doubleVector == FirestoreVector([0.12, 0.42, 0.86]))
        #expect(floatVector.values.map { Float($0) } == [0.12, 0.42, 0.86])
    }

    @Test("Reserved document field names are rejected")
    func testReservedDocumentFieldNamesAreRejected() throws {
        let documentData = DocumentData(data: [
            "profile": [
                "__meta__": "reserved"
            ]
        ])

        do {
            _ = try documentData.getFields(allowsDelete: false)
            Issue.record("Expected reserved document field name error")
        } catch FirestoreError.invalidFieldPath(let message) {
            #expect(message.contains("reserved Firestore field name"))
        }
    }
}
