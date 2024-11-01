// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: google/firestore/v1/common.proto
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

import Foundation
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

/// A set of field paths on a document.
/// Used to restrict a get or update operation on a document to a subset of its
/// fields.
/// This is different from standard field masks, as this is always scoped to a
/// [Document][google.firestore.v1.Document], and takes in account the dynamic
/// nature of [Value][google.firestore.v1.Value].
public struct Google_Firestore_V1_DocumentMask: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// The list of field paths in the mask. See
  /// [Document.fields][google.firestore.v1.Document.fields] for a field path
  /// syntax reference.
  public var fieldPaths: [String] = []

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

/// A precondition on a document, used for conditional operations.
public struct Google_Firestore_V1_Precondition: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// The type of precondition.
  public var conditionType: Google_Firestore_V1_Precondition.OneOf_ConditionType? = nil

  /// When set to `true`, the target document must exist.
  /// When set to `false`, the target document must not exist.
  public var exists: Bool {
    get {
      if case .exists(let v)? = conditionType {return v}
      return false
    }
    set {conditionType = .exists(newValue)}
  }

  /// When set, the target document must exist and have been last updated at
  /// that time. Timestamp must be microsecond aligned.
  public var updateTime: SwiftProtobuf.Google_Protobuf_Timestamp {
    get {
      if case .updateTime(let v)? = conditionType {return v}
      return SwiftProtobuf.Google_Protobuf_Timestamp()
    }
    set {conditionType = .updateTime(newValue)}
  }

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  /// The type of precondition.
  public enum OneOf_ConditionType: Equatable, Sendable {
    /// When set to `true`, the target document must exist.
    /// When set to `false`, the target document must not exist.
    case exists(Bool)
    /// When set, the target document must exist and have been last updated at
    /// that time. Timestamp must be microsecond aligned.
    case updateTime(SwiftProtobuf.Google_Protobuf_Timestamp)

  }

  public init() {}
}

/// Options for creating a new transaction.
public struct Google_Firestore_V1_TransactionOptions: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// The mode of the transaction.
  public var mode: Google_Firestore_V1_TransactionOptions.OneOf_Mode? = nil

  /// The transaction can only be used for read operations.
  public var readOnly: Google_Firestore_V1_TransactionOptions.ReadOnly {
    get {
      if case .readOnly(let v)? = mode {return v}
      return Google_Firestore_V1_TransactionOptions.ReadOnly()
    }
    set {mode = .readOnly(newValue)}
  }

  /// The transaction can be used for both read and write operations.
  public var readWrite: Google_Firestore_V1_TransactionOptions.ReadWrite {
    get {
      if case .readWrite(let v)? = mode {return v}
      return Google_Firestore_V1_TransactionOptions.ReadWrite()
    }
    set {mode = .readWrite(newValue)}
  }

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  /// The mode of the transaction.
  public enum OneOf_Mode: Equatable, Sendable {
    /// The transaction can only be used for read operations.
    case readOnly(Google_Firestore_V1_TransactionOptions.ReadOnly)
    /// The transaction can be used for both read and write operations.
    case readWrite(Google_Firestore_V1_TransactionOptions.ReadWrite)

  }

  /// Options for a transaction that can be used to read and write documents.
  ///
  /// Firestore does not allow 3rd party auth requests to create read-write.
  /// transactions.
  public struct ReadWrite: @unchecked Sendable {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    /// An optional transaction to retry.
    public var retryTransaction: Data = Data()

    public var unknownFields = SwiftProtobuf.UnknownStorage()

    public init() {}
  }

  /// Options for a transaction that can only be used to read documents.
  public struct ReadOnly: Sendable {
    // SwiftProtobuf.Message conformance is added in an extension below. See the
    // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
    // methods supported on all messages.

    /// The consistency mode for this transaction. If not set, defaults to strong
    /// consistency.
    public var consistencySelector: Google_Firestore_V1_TransactionOptions.ReadOnly.OneOf_ConsistencySelector? = nil

    /// Reads documents at the given time.
    ///
    /// This must be a microsecond precision timestamp within the past one
    /// hour, or if Point-in-Time Recovery is enabled, can additionally be a
    /// whole minute timestamp within the past 7 days.
    public var readTime: SwiftProtobuf.Google_Protobuf_Timestamp {
      get {
        if case .readTime(let v)? = consistencySelector {return v}
        return SwiftProtobuf.Google_Protobuf_Timestamp()
      }
      set {consistencySelector = .readTime(newValue)}
    }

    public var unknownFields = SwiftProtobuf.UnknownStorage()

    /// The consistency mode for this transaction. If not set, defaults to strong
    /// consistency.
    public enum OneOf_ConsistencySelector: Equatable, Sendable {
      /// Reads documents at the given time.
      ///
      /// This must be a microsecond precision timestamp within the past one
      /// hour, or if Point-in-Time Recovery is enabled, can additionally be a
      /// whole minute timestamp within the past 7 days.
      case readTime(SwiftProtobuf.Google_Protobuf_Timestamp)

    }

    public init() {}
  }

  public init() {}
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "google.firestore.v1"

extension Google_Firestore_V1_DocumentMask: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".DocumentMask"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "field_paths"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedStringField(value: &self.fieldPaths) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.fieldPaths.isEmpty {
      try visitor.visitRepeatedStringField(value: self.fieldPaths, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Google_Firestore_V1_DocumentMask, rhs: Google_Firestore_V1_DocumentMask) -> Bool {
    if lhs.fieldPaths != rhs.fieldPaths {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Google_Firestore_V1_Precondition: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".Precondition"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "exists"),
    2: .standard(proto: "update_time"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try {
        var v: Bool?
        try decoder.decodeSingularBoolField(value: &v)
        if let v = v {
          if self.conditionType != nil {try decoder.handleConflictingOneOf()}
          self.conditionType = .exists(v)
        }
      }()
      case 2: try {
        var v: SwiftProtobuf.Google_Protobuf_Timestamp?
        var hadOneofValue = false
        if let current = self.conditionType {
          hadOneofValue = true
          if case .updateTime(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.conditionType = .updateTime(v)
        }
      }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    switch self.conditionType {
    case .exists?: try {
      guard case .exists(let v)? = self.conditionType else { preconditionFailure() }
      try visitor.visitSingularBoolField(value: v, fieldNumber: 1)
    }()
    case .updateTime?: try {
      guard case .updateTime(let v)? = self.conditionType else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }()
    case nil: break
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Google_Firestore_V1_Precondition, rhs: Google_Firestore_V1_Precondition) -> Bool {
    if lhs.conditionType != rhs.conditionType {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Google_Firestore_V1_TransactionOptions: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".TransactionOptions"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    2: .standard(proto: "read_only"),
    3: .standard(proto: "read_write"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 2: try {
        var v: Google_Firestore_V1_TransactionOptions.ReadOnly?
        var hadOneofValue = false
        if let current = self.mode {
          hadOneofValue = true
          if case .readOnly(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.mode = .readOnly(v)
        }
      }()
      case 3: try {
        var v: Google_Firestore_V1_TransactionOptions.ReadWrite?
        var hadOneofValue = false
        if let current = self.mode {
          hadOneofValue = true
          if case .readWrite(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.mode = .readWrite(v)
        }
      }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    switch self.mode {
    case .readOnly?: try {
      guard case .readOnly(let v)? = self.mode else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }()
    case .readWrite?: try {
      guard case .readWrite(let v)? = self.mode else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    }()
    case nil: break
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Google_Firestore_V1_TransactionOptions, rhs: Google_Firestore_V1_TransactionOptions) -> Bool {
    if lhs.mode != rhs.mode {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Google_Firestore_V1_TransactionOptions.ReadWrite: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = Google_Firestore_V1_TransactionOptions.protoMessageName + ".ReadWrite"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "retry_transaction"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.retryTransaction) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.retryTransaction.isEmpty {
      try visitor.visitSingularBytesField(value: self.retryTransaction, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Google_Firestore_V1_TransactionOptions.ReadWrite, rhs: Google_Firestore_V1_TransactionOptions.ReadWrite) -> Bool {
    if lhs.retryTransaction != rhs.retryTransaction {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Google_Firestore_V1_TransactionOptions.ReadOnly: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = Google_Firestore_V1_TransactionOptions.protoMessageName + ".ReadOnly"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    2: .standard(proto: "read_time"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 2: try {
        var v: SwiftProtobuf.Google_Protobuf_Timestamp?
        var hadOneofValue = false
        if let current = self.consistencySelector {
          hadOneofValue = true
          if case .readTime(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.consistencySelector = .readTime(v)
        }
      }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if case .readTime(let v)? = self.consistencySelector {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Google_Firestore_V1_TransactionOptions.ReadOnly, rhs: Google_Firestore_V1_TransactionOptions.ReadOnly) -> Bool {
    if lhs.consistencySelector != rhs.consistencySelector {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
