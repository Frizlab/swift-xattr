import Foundation



/**
 Declare what the intent of the copy is. Not a bit-field (for now, at least).
 
 - Note: The list of xattr operation intents has been created from /usr/include/xattr\_flags.h on macOS 12.0.1, Xcode 13.1.
 We have used an enum because the doc says this type is not a bit-field. */
public enum XattrOperationIntent : RawRepresentable {
	
	public typealias RawValue = UInt32
	
	/**
	 The EA is attached to an object that is simply being copied.
	 E.g., `cp src dst` */
	case copy
	/**
	 The EA is attached to an object being saved; as in a “safe save,” the destination is being replaced by the source,
	 so the question is whether the EA should be applied to the destination, or generated anew. */
	case save
	/**
	 The EA is attached to an object that is being given out to other people.
	 For example, saving to a public folder, or attaching to an email message. */
	case share
	/**
	 The EA is attached to an object that is being synced to other storages for the same user.
	 For example synced to iCloud. */
	case sync
	
	public init?(rawValue: UInt32) {
		/* We cast because the intents are defined using a #define and thus swift imports them as Int32… */
		switch rawValue {
			case UInt32(XATTR_OPERATION_INTENT_COPY):  self = .copy
			case UInt32(XATTR_OPERATION_INTENT_SAVE):  self = .save
			case UInt32(XATTR_OPERATION_INTENT_SHARE): self = .share
			case UInt32(XATTR_OPERATION_INTENT_SYNC):  self = .sync
			default: return nil
		}
	}
	
	public var rawValue: UInt32 {
		/* We cast because the intents are defined using a #define and thus swift imports them as Int32… */
		switch self {
			case .copy:  return UInt32(XATTR_OPERATION_INTENT_COPY)
			case .save:  return UInt32(XATTR_OPERATION_INTENT_SAVE)
			case .share: return UInt32(XATTR_OPERATION_INTENT_SHARE)
			case .sync:  return UInt32(XATTR_OPERATION_INTENT_SYNC)
		}
	}
	
	public func preserve(xattrFlags: XattrFlags) -> Bool {
		return xattr_intent_with_flags(rawValue, xattrFlags.rawValue) != 0 /* In C, everything that is not 0 is true. */
	}
	
	public func preserve(xattrName: String) -> Bool {
		let value = xattrName.withCString{ cString in
			return xattr_preserve_for_intent(cString, rawValue)
		}
		return value != 0 /* In C, everything that is not 0 is true. */
	}
	
}
