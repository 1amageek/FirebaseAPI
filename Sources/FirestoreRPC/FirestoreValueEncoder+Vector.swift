import FirestoreCore
import FirestoreProtobuf

extension FirestoreValueEncoder {
    package static func encodeVector(
        _ vector: FirestoreVector,
        path: String
    ) throws -> Google_Firestore_V1_Value {
        try validateVector(vector, path: path)
        return Google_Firestore_V1_Value.with {
            $0.arrayValue = Google_Firestore_V1_ArrayValue.with {
                $0.values = vector.values.map { dimension in
                    Google_Firestore_V1_Value.with {
                        $0.doubleValue = dimension
                    }
                }
            }
        }
    }

    static func validateVector(_ vector: FirestoreVector, path: String) throws {
        guard !vector.values.isEmpty else {
            throw FirestoreError.invalidFieldValue("FirestoreVector at '\(path)' must contain at least one dimension.")
        }
        guard vector.values.count <= 2_048 else {
            throw FirestoreError.invalidFieldValue("FirestoreVector at '\(path)' exceeds 2,048 dimensions.")
        }
    }
}
