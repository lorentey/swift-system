/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress {
  @frozen
  /// An IPv4 address and port number.
  public struct IPv4: RawRepresentable {
    public var rawValue: CInterop.SockAddrIn

    public init(rawValue: CInterop.SockAddrIn) {
      self.rawValue = rawValue
      self.rawValue.sin_family = Family.ipv4.rawValue
    }

    public init?(_ address: SocketAddress) {
      guard address.family == .ipv4 else { return nil }
      let value: CInterop.SockAddrIn? = address.withUnsafeBytes { buffer in
        guard buffer.count >= MemoryLayout<CInterop.SockAddrIn>.size else {
          return nil
        }
        return buffer.baseAddress!.load(as: CInterop.SockAddrIn.self)
      }
      guard let value = value else { return nil }
      self.rawValue = value
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress {
  /// Create a SocketAddress from an IPv4 address and port number.
  public init(_ ipv4: IPv4) {
    self = Swift.withUnsafeBytes(of: ipv4.rawValue) { buffer in
      SocketAddress(buffer)
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv4 {
  /// Create a socket address from a given Internet address and port number.
  public init(address: Address, port: Port) {
    rawValue = CInterop.SockAddrIn()
    rawValue.sin_family = CInterop.SAFamily(SocketDescriptor.Domain.ipv4.rawValue);
    rawValue.sin_port = port.rawValue._networkOrder
    rawValue.sin_addr = CInterop.InAddr(s_addr: address.rawValue._networkOrder)
  }

  public init?(address: String, port: Port) {
    guard let address = Address(address) else { return nil }
    self.init(address: address, port: port)
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv4: Hashable {
  public static func ==(left: Self, right: Self) -> Bool {
    left.address == right.address && left.port == right.port
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(address)
    hasher.combine(port)
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv4: CustomStringConvertible {
  public var description: String {
    "\(address):\(port)"
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv4 {
  @frozen
  /// The port number on which the socket is listening.
  public struct Port: RawRepresentable, ExpressibleByIntegerLiteral, Hashable {
    /// The port number, in host byte order.
    public var rawValue: CInterop.InPort

    public init(_ value: CInterop.InPort) {
      self.rawValue = value
    }

    public init(rawValue: CInterop.InPort) {
      self.init(rawValue)
    }

    public init(integerLiteral value: CInterop.InPort) {
      self.init(value)
    }
  }

  public var port: Port {
    get { Port(CInterop.InPort(_networkOrder: rawValue.sin_port)) }
    set { rawValue.sin_port = newValue.rawValue._networkOrder }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv4.Port: CustomStringConvertible {
  public var description: String {
    rawValue.description
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv4 {
  @frozen
  /// A 32-bit IPv4 address.
  public struct Address: RawRepresentable, Hashable {
    /// The raw internet address value, in host byte order.
    public var rawValue: CInterop.InAddrT

    public init(rawValue: CInterop.InAddrT) {
      self.rawValue = rawValue
    }
  }

  public var address: Address {
    get {
      let value = CInterop.InAddrT(_networkOrder: rawValue.sin_addr.s_addr)
      return Address(rawValue: value)
    }
    set {
      rawValue.sin_addr.s_addr = newValue.rawValue._networkOrder
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv4.Address: CustomStringConvertible {
  public var description: String {
    _inet_ntop()
  }

  internal func _inet_ntop() -> String {
    let addr = CInterop.InAddr(s_addr: rawValue._networkOrder)
    return withUnsafeBytes(of: addr) { src in
      String(_unsafeUninitializedCapacity: Int(_INET_ADDRSTRLEN)) { dst in
        dst.baseAddress!.withMemoryRebound(
          to: CChar.self,
          capacity: Int(_INET_ADDRSTRLEN)
        ) { dst in
          let res = system_inet_ntop(
              _PF_INET,
              src.baseAddress!,
              dst,
              CInterop.SockLen(_INET_ADDRSTRLEN))
          if res == -1 {
            let errno = Errno.current
            fatalError("Failed to convert IPv4 address to string: \(errno)")
          }
          let length = system_strlen(dst)
          assert(length <= _INET_ADDRSTRLEN)
          return length
        }
      }
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv4.Address: LosslessStringConvertible {
  public init?(_ description: String) {
    guard let value = Self._inet_pton(description) else { return nil }
    self = value
  }

  internal static func _inet_pton(_ string: String) -> Self? {
    string.withCString { ptr in
      var addr = CInterop.InAddr()
      let res = system_inet_pton(_PF_INET, ptr, &addr)
      guard res == 1 else { return nil }
      return Self(rawValue: CInterop.InAddrT(_networkOrder: addr.s_addr))
    }
  }
}
