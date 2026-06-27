import Foundation

public protocol FirestoreAdminClient:
    FirestoreAdminReferenceClient,
    FirestoreAdminWriteClient,
    FirestoreAdminTransactionClient,
    FirestoreAdminPipelineClient,
    FirestoreAdminLifecycleClient
{}

extension FirestoreAdmin: FirestoreAdminClient {}
