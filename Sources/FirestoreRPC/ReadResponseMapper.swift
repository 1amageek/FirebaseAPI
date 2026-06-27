import FirestoreCore
import FirestoreRPCSupport

package struct ReadResponseMapper {
    let runtime: any FirestoreReferenceRuntime
    let decoder: FirestoreDocumentDataDecoder

    package init(runtime: any FirestoreReferenceRuntime) {
        self.runtime = runtime
        self.decoder = FirestoreDocumentDataDecoder(runtime: runtime)
    }
}
