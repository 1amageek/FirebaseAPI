# FirebaseAPI

FirebaseAPI for Swift is a Swift package that provides a simple interface to interact.

This repository includes the [googleapis](https://github.com/googleapis/googleapis) repository as a submodule, which is used to generate the API client code for Firebase.


# Development

To develop this library, you will need a `ServiceAccount.json` file.

Please copy this file to the `FirestoreTests` directory.

## Development Steps

1. Download the service account key from Firebase Console and save it as `ServiceAccount.json`.

2. Copy the `ServiceAccount.json` file to the `FirestoreTests` directory.

3. Open the project in Xcode and select the `FirestoreTests` target.

```Package.swift
        .testTarget(
            name: "FirestoreTests",
            dependencies: ["Firestore"],
            resources: [
                .copy("ServiceAccount.json")
            ]),
```

## Output latest API

```
mkdir -p Sources/Firestore/Proto
cd googleapi
protoc \
 ./google/firestore/v1/*.proto \
 ./google/api/field_behavior.proto \
 ./google/api/resource.proto \
 ./google/longrunning/operations.proto \
 ./google/rpc/status.proto \
 ./google/type/latlng.proto \
 --swift_out=../Sources/FirestoreAPI/Proto \
 --grpc-swift_out=../Sources/FirestoreAPI/Proto \
 --swift_opt=Visibility=Public \
 --grpc-swift_opt=Visibility=Public
```
