import Foundation
import FirestoreCore

enum GeoQueryLocationExtractor {
    static func geoPoint(
        in document: QueryDocumentSnapshot,
        fieldPath: String
    ) throws -> GeoPoint? {
        let segments = try FirestoreFieldPath.split(fieldPath)
        var currentValue: Any = document.data()
        for segment in segments {
            guard let dictionary = currentValue as? [String: Any],
                  let nextValue = dictionary[segment] else {
                return nil
            }
            currentValue = nextValue
        }
        return currentValue as? GeoPoint
    }
}
