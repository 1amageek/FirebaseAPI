import Foundation
import FirestoreCore

enum GeoHash {
    struct Range: Hashable, Sendable {
        let start: String
        let end: String
    }

    private static let base32 = Array("0123456789bcdefghjkmnpqrstuvwxyz")
    private static let base32Indexes = Dictionary(uniqueKeysWithValues: base32.enumerated().map { ($0.element, $0.offset) })
    private static let bitsPerCharacter = 5
    static let maximumPrecision = 10
    private static let maximumBitsPrecision = maximumPrecision * bitsPerCharacter
    private static let earthEquatorialRadius = 6_378_137.0
    private static let earthEccentricitySquared = 0.00669447819799
    private static let earthMeridionalCircumference = 40_007_860.0
    private static let metersPerLatitudeDegree = 110_574.0
    private static let epsilon = 1e-12

    static func queryBounds(center: GeoPoint, radiusInMeters: Double) throws -> [Range] {
        try validate(center)
        guard radiusInMeters.isFinite, radiusInMeters > 0 else {
            throw FirestoreError.invalidQuery("GeoQuery radius must be greater than zero.")
        }

        let queryBits = max(1, boundingBoxBits(center: center, radiusInMeters: radiusInMeters))
        let precision = Int(ceil(Double(queryBits) / Double(bitsPerCharacter)))
        let coordinates = boundingBoxCoordinates(center: center, radiusInMeters: radiusInMeters)

        var ranges = Set<Range>()
        for coordinate in coordinates {
            let geohash = encode(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                precision: precision
            )
            ranges.insert(queryRange(for: geohash, bits: queryBits))
        }

        return ranges.sorted { lhs, rhs in lhs.start < rhs.start }
    }

    static func encode(latitude: Double, longitude: Double, precision: Int) -> String {
        let resolvedPrecision = min(max(precision, 1), 10)
        var latitudeRange = (-90.0, 90.0)
        var longitudeRange = (-180.0, 180.0)
        var isEvenBit = true
        var bitCount = 0
        var value = 0
        var result = ""

        while result.count < resolvedPrecision {
            if isEvenBit {
                let middle = (longitudeRange.0 + longitudeRange.1) / 2
                if longitude >= middle {
                    value = value * 2 + 1
                    longitudeRange.0 = middle
                } else {
                    value *= 2
                    longitudeRange.1 = middle
                }
            } else {
                let middle = (latitudeRange.0 + latitudeRange.1) / 2
                if latitude >= middle {
                    value = value * 2 + 1
                    latitudeRange.0 = middle
                } else {
                    value *= 2
                    latitudeRange.1 = middle
                }
            }

            isEvenBit.toggle()
            bitCount += 1
            if bitCount == 5 {
                result.append(base32[value])
                bitCount = 0
                value = 0
            }
        }

        return result
    }

    private static func queryRange(for geohash: String, bits: Int) -> Range {
        let precision = Int(ceil(Double(bits) / Double(bitsPerCharacter)))
        let prefix = String(geohash.prefix(precision))
        guard let lastCharacter = prefix.last,
              let lastCharacterValue = base32Indexes[lastCharacter]
        else {
            return Range(start: geohash, end: "\(geohash)~")
        }

        let base = String(prefix.dropLast())
        let significantBits = bits - base.count * bitsPerCharacter
        let unusedBits = bitsPerCharacter - significantBits
        let startValue = (lastCharacterValue >> unusedBits) << unusedBits
        let endValue = startValue + (1 << unusedBits)
        let start = "\(base)\(base32[startValue])"
        let end = endValue > base32.count - 1 ? "\(base)~" : "\(base)\(base32[endValue])"
        return Range(start: start, end: end)
    }

    private static func boundingBoxBits(center: GeoPoint, radiusInMeters: Double) -> Int {
        let latitudeDegrees = radiusInMeters / metersPerLatitudeDegree
        let latitudeNorth = min(90, center.latitude + latitudeDegrees)
        let latitudeSouth = max(-90, center.latitude - latitudeDegrees)
        let latitudeBits = floor(latitudeBitsForResolution(radiusInMeters)) * 2
        let longitudeBitsNorth = floor(longitudeBitsForResolution(radiusInMeters, latitude: latitudeNorth)) * 2 - 1
        let longitudeBitsSouth = floor(longitudeBitsForResolution(radiusInMeters, latitude: latitudeSouth)) * 2 - 1
        let bits = min(latitudeBits, longitudeBitsNorth, longitudeBitsSouth, Double(maximumBitsPrecision))
        return Int(bits)
    }

    private static func latitudeBitsForResolution(_ resolutionInMeters: Double) -> Double {
        min(
            log2(earthMeridionalCircumference / 2 / resolutionInMeters),
            Double(maximumBitsPrecision)
        )
    }

    private static func longitudeBitsForResolution(_ resolutionInMeters: Double, latitude: Double) -> Double {
        let degrees = metersToLongitudeDegrees(resolutionInMeters, at: latitude)
        guard abs(degrees) > epsilon else {
            return 1
        }
        return min(log2(360 / degrees), Double(maximumBitsPrecision))
    }

    private static func boundingBoxCoordinates(center: GeoPoint, radiusInMeters: Double) -> [GeoPoint] {
        let latitudeDegrees = radiusInMeters / metersPerLatitudeDegree
        let latitudeNorth = min(90, center.latitude + latitudeDegrees)
        let latitudeSouth = max(-90, center.latitude - latitudeDegrees)
        let longitudeDegreesNorth = metersToLongitudeDegrees(radiusInMeters, at: latitudeNorth)
        let longitudeDegreesSouth = metersToLongitudeDegrees(radiusInMeters, at: latitudeSouth)
        let longitudeDegrees = max(longitudeDegreesNorth, longitudeDegreesSouth)
        let longitudeWest = normalizeLongitude(center.longitude - longitudeDegrees)
        let longitudeEast = normalizeLongitude(center.longitude + longitudeDegrees)

        return [
            GeoPoint(latitude: center.latitude, longitude: center.longitude),
            GeoPoint(latitude: center.latitude, longitude: longitudeWest),
            GeoPoint(latitude: center.latitude, longitude: longitudeEast),
            GeoPoint(latitude: latitudeNorth, longitude: center.longitude),
            GeoPoint(latitude: latitudeNorth, longitude: longitudeWest),
            GeoPoint(latitude: latitudeNorth, longitude: longitudeEast),
            GeoPoint(latitude: latitudeSouth, longitude: center.longitude),
            GeoPoint(latitude: latitudeSouth, longitude: longitudeWest),
            GeoPoint(latitude: latitudeSouth, longitude: longitudeEast)
        ]
    }

    private static func validate(_ point: GeoPoint) throws {
        guard point.latitude.isFinite,
              point.longitude.isFinite,
              (-90...90).contains(point.latitude),
              (-180...180).contains(point.longitude) else {
            throw FirestoreError.invalidQuery("GeoQuery center must contain a valid latitude and longitude.")
        }
    }

    private static func metersToLongitudeDegrees(_ distanceInMeters: Double, at latitude: Double) -> Double {
        let radians = latitude * .pi / 180
        let numerator = cos(radians) * earthEquatorialRadius * .pi / 180
        let denominator = 1 / sqrt(1 - earthEccentricitySquared * pow(sin(radians), 2))
        let deltaDegrees = numerator * denominator
        guard deltaDegrees >= epsilon else {
            return distanceInMeters > 0 ? 360 : 0
        }
        return min(360, distanceInMeters / deltaDegrees)
    }

    private static func normalizeLongitude(_ value: Double) -> Double {
        var longitude = value
        while longitude < -180 {
            longitude += 360
        }
        while longitude > 180 {
            longitude -= 360
        }
        return longitude
    }
}
