import Foundation

/// Reasoning-token configuration (`reasoning` request field).
public struct Reasoning: Encodable, Sendable {
  public enum Effort: String, Encodable, Sendable {
    case max
    case xhigh
    case high
    case medium
    case low
    case minimal
    case none
  }

  public enum Summary: String, Encodable, Sendable {
    case auto
    case concise
    case detailed
  }

  public var effort: Effort?
  public var summary: Summary?

  public init(effort: Effort? = nil, summary: Summary? = nil) {
    self.effort = effort
    self.summary = summary
  }
}
