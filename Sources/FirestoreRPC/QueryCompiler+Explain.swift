import FirestoreCore
import FirestoreProtobuf

extension QueryCompiler {
    func makeExplainOptions(
        _ options: FirestoreExplainOptions
    ) -> Google_Firestore_V1_ExplainOptions {
        Google_Firestore_V1_ExplainOptions.with {
            $0.analyze = options.analyze
        }
    }
}
