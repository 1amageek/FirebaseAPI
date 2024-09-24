// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: google/firestore/v1/aggregation_result.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

/// The result of a single bucket from a Firestore aggregation query.
///
/// The keys of `aggregate_fields` are the same for all results in an aggregation
/// query, unlike document queries which can have different fields present for
/// each result.
public struct Google_Firestore_V1_AggregationResult: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// The result of the aggregation functions, ex: `COUNT(*) AS total_docs`.
  ///
  /// The key is the
  /// [alias][google.firestore.v1.StructuredAggregationQuery.Aggregation.alias]
  /// assigned to the aggregation function on input and the size of this map
  /// equals the number of aggregation functions in the query.
  public var aggregateFields: Dictionary<String,Google_Firestore_V1_Value> = [:]

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "google.firestore.v1"

extension Google_Firestore_V1_AggregationResult: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".AggregationResult"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    2: .standard(proto: "aggregate_fields"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 2: try { try decoder.decodeMapField(fieldType: SwiftProtobuf._ProtobufMessageMap<SwiftProtobuf.ProtobufString,Google_Firestore_V1_Value>.self, value: &self.aggregateFields) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.aggregateFields.isEmpty {
      try visitor.visitMapField(fieldType: SwiftProtobuf._ProtobufMessageMap<SwiftProtobuf.ProtobufString,Google_Firestore_V1_Value>.self, value: self.aggregateFields, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Google_Firestore_V1_AggregationResult, rhs: Google_Firestore_V1_AggregationResult) -> Bool {
    if lhs.aggregateFields != rhs.aggregateFields {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
