import Foundation
import FirestoreCore

public enum PipelineReplaceMode: String, Sendable {
    case fullReplace = "full_replace"
    case mergeOverwriteExisting = "merge_overwrite_existing"
    case mergeKeepExisting = "merge_keep_existing"
}
