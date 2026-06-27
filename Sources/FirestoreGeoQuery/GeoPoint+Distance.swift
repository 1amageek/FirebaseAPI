import Foundation
import FirestoreCore

extension GeoPoint {
    func distanceInMeters(to other: GeoPoint) -> Double {
        let earthRadiusInMeters = 6_371_008.8
        let latitudeDelta = (other.latitude - latitude).degreesToRadians
        let longitudeDelta = (other.longitude - longitude).degreesToRadians
        let startLatitude = latitude.degreesToRadians
        let endLatitude = other.latitude.degreesToRadians

        let haversine = pow(sin(latitudeDelta / 2), 2)
            + cos(startLatitude) * cos(endLatitude) * pow(sin(longitudeDelta / 2), 2)
        return earthRadiusInMeters * 2 * atan2(sqrt(haversine), sqrt(1 - haversine))
    }
}

private extension Double {
    var degreesToRadians: Double {
        self * .pi / 180
    }
}
