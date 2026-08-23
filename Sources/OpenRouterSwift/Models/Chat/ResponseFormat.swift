import Foundation

/// Output format constraints (`response_format` request field).
/// OpenRouter supports `text`, `json_object`, `json_schema`, `grammar` (GBNF), and `python`.
public enum ResponseFormat: Encodable, Sendable {
  case text
  case jsonObject
  case jsonSchema(name: String, schema: JSONValue, strict: Bool? = nil, description: String? = nil)
  /// Constrain output with a GBNF grammar definition.
  case grammar(String)
  /// Constrain output to valid Python.
  case python

  enum CodingKeys: String, CodingKey {
    case type
    case jsonSchema = "json_schema"
    case grammar
  }

  struct JSONSchemaPayload: Encodable {
    let name: String
    let strict: Bool?
    let description: String?
    let schema: JSONValue
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .text:
      try container.encode("text", forKey: .type)

    case .jsonObject:
      try container.encode("json_object", forKey: .type)

    case .jsonSchema(let name, let schema, let strict, let description):
      try container.encode("json_schema", forKey: .type)
      try container.encode(
        JSONSchemaPayload(name: name, strict: strict, description: description, schema: schema),
        forKey: .jsonSchema)

    case .grammar(let definition):
      try container.encode("grammar", forKey: .type)
      try container.encode(definition, forKey: .grammar)

    case .python:
      try container.encode("python", forKey: .type)
    }
  }
}
