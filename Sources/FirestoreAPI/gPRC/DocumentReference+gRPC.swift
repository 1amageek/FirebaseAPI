//
//  DocumentReference+gRPC.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/10.
//

import Foundation
import GRPCCore
import GRPCProtobuf
import SwiftProtobuf

extension DocumentReference {

    var name: String {
        return "\(database.path)/\(path)".normalized
    }

    func getDocument<Transport: ClientTransport>(firestore: Firestore<Transport>, metadata: Metadata) async throws -> DocumentSnapshot {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: firestore.grpcClient)

        var requestMessage = Google_Firestore_V1_GetDocumentRequest()
        requestMessage.name = name

        let request = ClientRequest<Google_Firestore_V1_GetDocumentRequest>(
            message: requestMessage,
            metadata: metadata
        )

        do {
            let document = try await client.getDocument(
                request: request,
                serializer: ProtobufSerializer<Google_Firestore_V1_GetDocumentRequest>(),
                deserializer: ProtobufDeserializer<Google_Firestore_V1_Document>()
            ) { response in
                try response.message
            }
            return DocumentSnapshot(document: document, documentReference: self)
        } catch let error as RPCError {
            if error.code == .notFound {
                return DocumentSnapshot(documentReference: self)
            }
            throw FirestoreError.rpcError(error)
        } catch {
            throw error
        }
    }

    func setData<Transport: ClientTransport>(_ documentData: [String: Any], merge: Bool = false, firestore: Firestore<Transport>, metadata: Metadata) async throws {
        print("[FirebaseAPI.DocumentReference] 📝 setData called for document: \(name)")

        print("[FirebaseAPI.DocumentReference] 📝 Creating Firestore client from cached gRPC client...")
        print("[FirebaseAPI.DocumentReference] 🔍 grpcClient type: \(type(of: firestore.grpcClient))")
        print("[FirebaseAPI.DocumentReference] 🔍 transport type: \(type(of: firestore.transport))")
        let client = Google_Firestore_V1_Firestore.Client(wrapping: firestore.grpcClient)
        print("[FirebaseAPI.DocumentReference] ✅ Firestore client created")
        print("[FirebaseAPI.DocumentReference] 🔍 Created client type: \(type(of: client))")

        print("[FirebaseAPI.DocumentReference] 📝 Preparing document data...")
        let documentData = DocumentData(data: documentData)
        print("[FirebaseAPI.DocumentReference] ✅ Document data prepared")

        print("[FirebaseAPI.DocumentReference] 📝 Building commit request...")
        var requestMessage = Google_Firestore_V1_CommitRequest()
        requestMessage.database = firestore.database.database
        requestMessage.writes = [
            Google_Firestore_V1_Write.with {
                $0.update = Google_Firestore_V1_Document.with {
                    $0.name = name
                    $0.fields = documentData.getFields()
                }
                if merge {
                    $0.updateMask = Google_Firestore_V1_DocumentMask.with {
                        $0.fieldPaths = documentData.keys
                    }
                }
                let transforms = documentData.getFieldTransforms(documentPath: name)
                if !transforms.isEmpty {
                    $0.updateTransforms = transforms
                }
            }
        ]
        print("[FirebaseAPI.DocumentReference] ✅ Commit request built with \(requestMessage.writes.count) writes")

        // Detailed write inspection
        if !requestMessage.writes.isEmpty {
            let firstWrite = requestMessage.writes[0]
            print("[FirebaseAPI.DocumentReference] 🔍 First write operation type: \(firstWrite.operation != nil ? "set" : "nil")")
            print("[FirebaseAPI.DocumentReference] 🔍 First write has update: \(firstWrite.operation != nil)")
            print("[FirebaseAPI.DocumentReference] 🔍 First write update name: \(firstWrite.update.name)")
            print("[FirebaseAPI.DocumentReference] 🔍 First write update fields count: \(firstWrite.update.fields.count)")
            print("[FirebaseAPI.DocumentReference] 🔍 First write updateTransforms count: \(firstWrite.updateTransforms.count)")
        }

        print("[FirebaseAPI.DocumentReference] 📝 Creating ClientRequest...")
        print("[FirebaseAPI.DocumentReference] 🔍 Metadata: \(metadata)")
        print("[FirebaseAPI.DocumentReference] 🔍 Request database: \(requestMessage.database)")
        let request = ClientRequest<Google_Firestore_V1_CommitRequest>(
            message: requestMessage,
            metadata: metadata
        )
        print("[FirebaseAPI.DocumentReference] ✅ ClientRequest created")

        print("[FirebaseAPI.DocumentReference] 📝 Executing commit request to Firestore API...")
        print("[FirebaseAPI.DocumentReference] 🔍 Client type: \(type(of: client))")
        print("[FirebaseAPI.DocumentReference] 🔍 Request type: \(type(of: request))")
        print("[FirebaseAPI.DocumentReference] 🔍 About to call client.commit()...")

        do {
            print("[FirebaseAPI.DocumentReference] ⏳ Waiting for client.commit() to start...")
            let result = try await client.commit(
                request: request,
                serializer: ProtobufSerializer<Google_Firestore_V1_CommitRequest>(),
                deserializer: ProtobufDeserializer<Google_Firestore_V1_CommitResponse>()
            ) { response in
                print("[FirebaseAPI.DocumentReference] 📝 Response handler called!")
                print("[FirebaseAPI.DocumentReference] 📝 Response type: \(type(of: response))")
                print("[FirebaseAPI.DocumentReference] 📝 Processing commit response...")
                do {
                    let msg = try response.message
                    print("[FirebaseAPI.DocumentReference] ✅ Message extracted successfully")
                    print("[FirebaseAPI.DocumentReference] ✅ Message type: \(type(of: msg))")
                    return msg
                } catch {
                    print("[FirebaseAPI.DocumentReference] ❌ Error extracting message: \(error)")
                    throw error
                }
            }
            print("[FirebaseAPI.DocumentReference] ✅ client.commit() returned")
            print("[FirebaseAPI.DocumentReference] ✅ Result type: \(type(of: result))")
            print("[FirebaseAPI.DocumentReference] ✅ setData completed successfully")
        } catch let error as RPCError {
            print("[FirebaseAPI.DocumentReference] ❌ RPC Error occurred:")
            print("[FirebaseAPI.DocumentReference] ❌   Code: \(error.code)")
            print("[FirebaseAPI.DocumentReference] ❌   Message: \(error.message)")
            print("[FirebaseAPI.DocumentReference] ❌   Metadata: \(error.metadata)")
            throw FirestoreError.rpcError(error)
        } catch {
            print("[FirebaseAPI.DocumentReference] ❌ Unknown error occurred: \(error)")
            print("[FirebaseAPI.DocumentReference] ❌   Error type: \(type(of: error))")
            throw error
        }
    }

    func updateData<Transport: ClientTransport>(_ fields: [String: Any], firestore: Firestore<Transport>, metadata: Metadata) async throws {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: firestore.grpcClient)
        let documentData = DocumentData(data: fields)

        var requestMessage = Google_Firestore_V1_CommitRequest()
        requestMessage.database = firestore.database.database
        requestMessage.writes = [
            Google_Firestore_V1_Write.with {
                $0.update = Google_Firestore_V1_Document.with {
                    $0.name = name
                    $0.fields = documentData.getFields()
                }
                $0.updateMask = Google_Firestore_V1_DocumentMask.with {
                    $0.fieldPaths = documentData.keys
                }
                $0.currentDocument = Google_Firestore_V1_Precondition.with {
                    $0.exists = true
                }
                let transforms = documentData.getFieldTransforms(documentPath: name)
                if !transforms.isEmpty {
                    $0.updateTransforms = transforms
                }
            }
        ]

        let request = ClientRequest<Google_Firestore_V1_CommitRequest>(
            message: requestMessage,
            metadata: metadata
        )

        _ = try await client.commit(
            request: request,
            serializer: ProtobufSerializer<Google_Firestore_V1_CommitRequest>(),
            deserializer: ProtobufDeserializer<Google_Firestore_V1_CommitResponse>()
        ) { response in
            try response.message
        }
    }

    func delete<Transport: ClientTransport>(firestore: Firestore<Transport>, metadata: Metadata) async throws {
        let client = Google_Firestore_V1_Firestore.Client(wrapping: firestore.grpcClient)

        var requestMessage = Google_Firestore_V1_DeleteDocumentRequest()
        requestMessage.name = name

        let request = ClientRequest<Google_Firestore_V1_DeleteDocumentRequest>(
            message: requestMessage,
            metadata: metadata
        )

        _ = try await client.deleteDocument(
            request: request,
            serializer: ProtobufSerializer<Google_Firestore_V1_DeleteDocumentRequest>(),
            deserializer: ProtobufDeserializer<SwiftProtobuf.Google_Protobuf_Empty>()
        ) { response in
            try response.message
        }
    }
}

extension DocumentReference {

    func setData<T: Encodable, Transport: ClientTransport>(_ data: T, merge: Bool = false, firestore: Firestore<Transport>, metadata: Metadata) async throws {
        let documentData = try FirestoreEncoder().encode(data)
        try await self.setData(documentData, merge: merge, firestore: firestore, metadata: metadata)
    }

    func updateData<T: Encodable, Transport: ClientTransport>(_ data: T, firestore: Firestore<Transport>, metadata: Metadata) async throws {
        let updateData = try FirestoreEncoder().encode(data)
        try await self.updateData(updateData, firestore: firestore, metadata: metadata)
    }
}

extension DocumentReference {

    func getDocument<T: Decodable, Transport: ClientTransport>(type: T.Type, firestore: Firestore<Transport>, metadata: Metadata) async throws -> T? {
        let snapshot = try await getDocument(firestore: firestore, metadata: metadata)
        if !snapshot.exists {
            return nil
        }
        guard let data = snapshot.data() else {
            return nil
        }
        return try FirestoreDecoder().decode(type, from: data, in: self)
    }
}

extension DocumentReference {

    func addSnapshotListener<Transport: ClientTransport>(firestore: Firestore<Transport>, metadata: Metadata) async throws -> AsyncThrowingStream<DocumentSnapshot, Error> {
        // Create a target for this specific document
        var target = Google_Firestore_V1_Target()
        target.documents = Google_Firestore_V1_Target.DocumentsTarget.with {
            $0.documents = [self.name]
        }
        target.targetID = 1

        // Listen to changes
        let responseStream = try await firestore.listen(target: target)

        // Transform ListenResponse stream to DocumentSnapshot stream
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await response in responseStream {
                        // Check the response type and handle accordingly
                        guard let responseType = response.responseType else {
                            continue
                        }

                        switch responseType {
                        case .documentChange(let change):
                            let snapshot = DocumentSnapshot(
                                document: change.document,
                                documentReference: self
                            )
                            continuation.yield(snapshot)

                        case .documentDelete(_):
                            let snapshot = DocumentSnapshot(documentReference: self)
                            continuation.yield(snapshot)

                        case .documentRemove(_):
                            let snapshot = DocumentSnapshot(documentReference: self)
                            continuation.yield(snapshot)

                        case .targetChange(_), .filter(_):
                            // Target changes and filters don't affect document snapshots
                            break
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
