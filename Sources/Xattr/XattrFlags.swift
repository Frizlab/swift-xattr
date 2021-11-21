import Foundation
import System



/**
 The xattr “flags.”
 
 A flag is simply a suffix to an xattr name.
 By default when an xattr does not have a “post-hashtag” suffix, it has no flags.
 
 To generate your xattr name with the flags you want, use the methods in this struct.
 
 - Note: The list of xattr flags has been created from /usr/include/xattr\_flags.h on macOS 12.0.1, Xcode 13.1. */
public struct XattrFlags : OptionSet {
	
	public typealias RawValue = xattr_flags_t
	
	public static func xattrNameWithoutFlags(_ name: String) throws -> String {
		return try name.withCString{ cString in
			guard let newName = xattr_name_without_flags(cString) else {
				throw Err.system(Errno(rawValue: errno))
			}
			defer {free(newName)}
			return String(cString: newName)
		}
	}
	
	public var rawValue: xattr_flags_t
	
	public init(rawValue: xattr_flags_t) {
		self.rawValue = rawValue
	}
	
	public init(xattrName: String) {
		let rawValue = xattrName.withCString{ cString in
			return xattr_flags_from_name(cString)
		}
		self.init(rawValue: rawValue)
	}
	
	public func apply(to name: String) throws -> String {
		return try name.withCString{ cString in
			guard let newName = xattr_name_with_flags(cString, rawValue) else {
				throw Err.system(Errno(rawValue: errno))
			}
			defer {free(newName)}
			return String(cString: newName)
		}
	}
	
	/**
	 Declare that the extended property should not be exported; this is deliberately a bit vague,
	 but this is used by `XATTR_OPERATION_INTENT_SHARE` to indicate not to preserve the xattr. */
	public static var noExport: XattrFlags {.init(rawValue: XATTR_FLAG_NO_EXPORT)}
	
	/**
	 Declares the extended attribute to be tied to the contents of the file (or vice versa),
	 such that it should be re-created when the contents of the file change.
	 Examples might include cryptographic keys, checksums, saved position or search information, and text encoding.
	 
	 This property causes the EA to be preserved for copy and share, but not for safe save.
	 (In a safe save, the EA exists on the original, and will not be copied to the new version.) */
	public static var contentDependent: XattrFlags {.init(rawValue: XATTR_FLAG_CONTENT_DEPENDENT)}
	
	/**
	 Declares that the extended attribute is never to be copied, for any intention type. */
	public static var neverPreserve: XattrFlags {.init(rawValue: XATTR_FLAG_NEVER_PRESERVE)}
	
	/**
	 Declares that the extended attribute is to be synced, used by the `XATTR_OPERATION_ITENT_SYNC` intention.
	 Syncing tends to want to minimize the amount of metadata synced around, hence the default behavior is for the EA NOT to be synced,
	 even if it would else be preserved for the `XATTR_OPERATION_ITENT_COPY` intention. */
	public static var syncable: XattrFlags {.init(rawValue: XATTR_FLAG_SYNCABLE)}
	
}
