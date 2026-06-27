import FirestoreProtobuf
import FirestorePipeline
import SwiftProtobuf

extension PipelineCompiler {
    func makeExplainOptions(_ options: PipelineExplainOptions) -> Google_Firestore_V1_Value {
        Google_Firestore_V1_Value.with {
            $0.mapValue = Google_Firestore_V1_MapValue.with {
                $0.fields = [
                    "mode": Google_Firestore_V1_Value.with {
                        $0.stringValue = options.mode.rawValue
                    },
                    "output_format": Google_Firestore_V1_Value.with {
                        $0.stringValue = options.outputFormat.rpcValue
                    }
                ]
            }
        }
    }
}
