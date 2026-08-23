import Foundation

// MARK: - Tool

/// A function tool the model may call.
public struct Tool: Encodable, Sendable {
  public struct Function: Encodable, Sendable {
    public var name: String
    public var description: String?
    /// JSON Schema for the function's arguments.
    public var parameters: JSONValue?
    public var strict: Bool?

    public init(
      name: String,
      description: String? = nil,
      parameters: JSONValue? = nil,
      strict: Bool? = nil)
    {
      self.name = name
      self.description = description
      self.parameters = parameters
      self.strict = strict
    }
  }

  public var type: String
  public var function: Function

  public init(function: Function) {
    type = "function"
    self.function = function
  }

  public static func function(
    name: String,
    description: String? = nil,
    parameters: JSONValue? = nil,
    strict: Bool? = nil)
    -> Tool
  {
    Tool(function: Function(name: name, description: description, parameters: parameters, strict: strict))
  }
}

// MARK: - ToolChoice

public enum ToolChoice: Encodable, Sendable {
  case auto
  case none
  case required
  case function(name: String)

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .auto:
      var container = encoder.singleValueContainer()
      try container.encode("auto")

    case .none:
      var container = encoder.singleValueContainer()
      try container.encode("none")

    case .required:
      var container = encoder.singleValueContainer()
      try container.encode("required")

    case .function(let name):
      struct Named: Encodable {
        let type = "function"
        let function: [String: String]
      }
      var container = encoder.singleValueContainer()
      try container.encode(Named(function: ["name": name]))
    }
  }
}

// MARK: - ToolCall

/// A tool call made by the assistant (request context) or returned in a response.
public struct ToolCall: Codable, Sendable {
  public struct Function: Codable, Sendable {
    public var name: String?
    /// JSON-encoded arguments string.
    public var arguments: String?

    public init(name: String?, arguments: String?) {
      self.name = name
      self.arguments = arguments
    }
  }

  public var id: String?
  public var type: String?
  public var index: Int?
  public var function: Function?

  public init(id: String?, type: String? = "function", index: Int? = nil, function: Function?) {
    self.id = id
    self.type = type
    self.index = index
    self.function = function
  }
}
