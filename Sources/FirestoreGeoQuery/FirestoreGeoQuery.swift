import Foundation
import FirestoreCore

public struct FirestoreGeoQuery {
    private let query: Query
    private let center: GeoPoint
    private let radiusInMeters: Double
    private let geohashField: String
    private let locationField: String

    public init(
        query: Query,
        center: GeoPoint,
        radiusInMeters: Double,
        geohashField: String = "geohash",
        locationField: String = "location"
    ) {
        self.query = query
        self.center = center
        self.radiusInMeters = radiusInMeters
        self.geohashField = geohashField
        self.locationField = locationField
    }

    public func getDocuments() async throws -> [GeoQueryResult] {
        try validateBaseQuery()
        _ = try FirestoreFieldPath.normalize(geohashField)
        _ = try FirestoreFieldPath.split(locationField)

        let bounds = try GeoHash.queryBounds(center: center, radiusInMeters: radiusInMeters)
        var results: [String: GeoQueryResult] = [:]

        for bound in bounds {
            let snapshot = try await query
                .order(by: geohashField)
                .start(at: [bound.start])
                .end(at: [bound.end])
                .getDocuments()

            for document in snapshot.documents {
                guard let location = try GeoQueryLocationExtractor.geoPoint(
                    in: document,
                    fieldPath: locationField
                ) else {
                    continue
                }

                let distance = center.distanceInMeters(to: location)
                guard distance <= radiusInMeters else {
                    continue
                }

                let key = document.documentReference.path
                if let existing = results[key], existing.distanceInMeters <= distance {
                    continue
                }
                results[key] = GeoQueryResult(document: document, distanceInMeters: distance)
            }
        }

        return results.values.sorted {
            if $0.distanceInMeters == $1.distanceInMeters {
                return $0.document.documentReference.path < $1.document.documentReference.path
            }
            return $0.distanceInMeters < $1.distanceInMeters
        }
    }

    private func validateBaseQuery() throws {
        let unsupportedPredicate = query.predicates.first { predicate in
            !isFilterPredicate(predicate)
        }
        guard unsupportedPredicate == nil else {
            throw FirestoreError.invalidQuery("GeoQuery base queries can contain filters only.")
        }
    }

    private func isFilterPredicate(_ predicate: QueryPredicate) -> Bool {
        switch predicate {
        case .and(let predicates), .or(let predicates):
            return predicates.allSatisfy(isFilterPredicate)
        default:
            return predicate.type == .fieldFilter || predicate.type == .unaryFilter
        }
    }
}

extension Query {
    public func geoQuery(
        center: GeoPoint,
        radiusInMeters: Double,
        geohashField: String = "geohash",
        locationField: String = "location"
    ) -> FirestoreGeoQuery {
        FirestoreGeoQuery(
            query: self,
            center: center,
            radiusInMeters: radiusInMeters,
            geohashField: geohashField,
            locationField: locationField
        )
    }
}

extension CollectionReference {
    public func geoQuery(
        center: GeoPoint,
        radiusInMeters: Double,
        geohashField: String = "geohash",
        locationField: String = "location"
    ) -> FirestoreGeoQuery {
        FirestoreGeoQuery(
            query: toQuery(),
            center: center,
            radiusInMeters: radiusInMeters,
            geohashField: geohashField,
            locationField: locationField
        )
    }
}

extension CollectionGroup {
    public func geoQuery(
        center: GeoPoint,
        radiusInMeters: Double,
        geohashField: String = "geohash",
        locationField: String = "location"
    ) -> FirestoreGeoQuery {
        FirestoreGeoQuery(
            query: makeQuery(predicates: []),
            center: center,
            radiusInMeters: radiusInMeters,
            geohashField: geohashField,
            locationField: locationField
        )
    }
}
