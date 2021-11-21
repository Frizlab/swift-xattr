import Foundation
import System



/* Adapted from https://stackoverflow.com/a/38343753
 * which was found from https://github.com/CleanCocoa/SwiftXattrs/blob/eacefff4bafb94448965149879d3f47265d1a877/SwiftXattrs/Xattrs.swift */
public extension URL {
	
	/**
	 Get extended attribute. If you want to use xattr flags, you should apply them to the name of the xattr before calling this method.
	 
	 - Note: Unlike `getxattr`, this method returns `nil` if the given xattr name does not exist. */
	func extendedAttribute(forName name: String, followLinks: Bool = true) throws -> Data? {
		guard isFileURL else {throw Err.notFileURL}
		let data = try withUnsafeFileSystemRepresentation{ fileSystemPath -> Data? in
			/* Determine attribute size.
			 * The position argument is only to be used for resource fork attributes and should always be 0 for other xattrs.
			 * We do not provide the XATTR_SHOWCOMPRESSION option. */
			let length = getxattr(/*path: */fileSystemPath, /*name: */name, /*value: */nil, /*size: */0, /*position: */0, /*options: */followLinks ? 0 : XATTR_NOFOLLOW)
			guard length >= 0 else {
				if errno == ENOATTR {return nil}
				else                {throw Err.system(Errno(rawValue: errno))}
			}
			
			var data = Data(count: length)
			let result = data.withUnsafeMutableBytes{ [count = data.count] in
				getxattr(/*path: */fileSystemPath, /*name: */name, /*value: */$0.baseAddress, /*size: */count, /*position: */0, /*options: */followLinks ? 0 : XATTR_NOFOLLOW)
			}
			guard result >= 0 else {throw Err.system(Errno(rawValue: errno))}
			return data
		}
		return data
	}
	
	/** Set extended attribute. If you want to use xattr flags, you should apply them to the name of the xattr before calling this method. */
	func setExtendedAttribute(data: Data, forName name: String, followLinks: Bool = true, failIfAlreadyExists: Bool = false, failIfDoesNotExist: Bool = false) throws {
		guard isFileURL else {throw Err.notFileURL}
		try withUnsafeFileSystemRepresentation{ fileSystemPath in
			let result = data.withUnsafeBytes{
				/* The position argument is only to be used for resource fork attributes and should always be 0 for other xattrs. */
				setxattr(
					/*path: */fileSystemPath,
					/*name: */name,
					/*value: */$0.baseAddress,
					/*size: */data.count,
					/*position: */0,
					/*options: */(followLinks ? 0 : XATTR_NOFOLLOW) | (failIfAlreadyExists ? XATTR_CREATE : 0) | (failIfDoesNotExist ? XATTR_REPLACE : 0)
				)
			}
			guard result == 0 else {throw Err.system(Errno(rawValue: errno))}
		}
	}
	
	/**
	 Remove extended attribute. If you want to use xattr flags, you should apply them to the name of the xattr before calling this method.
	 
	 - Note: Unlike `removexattr`, this method does **not** fail if the given xattr name does not exist.*/
	func removeExtendedAttribute(forName name: String, followLinks: Bool = true) throws {
		guard isFileURL else {throw Err.notFileURL}
		try withUnsafeFileSystemRepresentation{ fileSystemPath in
			/* We do not provide the XATTR_SHOWCOMPRESSION option. */
			let result = removexattr(/*path: */fileSystemPath, /*name: */name, /*options: */followLinks ? 0 : XATTR_NOFOLLOW)
			guard result == 0 || errno == ENOATTR else {
				throw Err.system(Errno(rawValue: errno))
			}
		}
	}
	
	/** Get list of all extended attributes. */
	func listExtendedAttributes(followLinks: Bool = true) throws -> [String] {
		guard isFileURL else {throw Err.notFileURL}
		let list = try withUnsafeFileSystemRepresentation{ fileSystemPath -> [String] in
			/* We do not provide the XATTR_SHOWCOMPRESSION option. */
			let length = listxattr(/*path: */fileSystemPath, /*namebuf: */nil, /*size: */0, /*options: */followLinks ? 0 : XATTR_NOFOLLOW)
			guard length >= 0 else {throw Err.system(Errno(rawValue: errno))}
			guard length > 0 else {return []}
			
			var namebuf = Array<CChar>(repeating: 0, count: length)
			let result = listxattr(/*path: */fileSystemPath, /*namebuf: */&namebuf, /*size: */namebuf.count, /*options: */followLinks ? 0 : XATTR_NOFOLLOW)
			guard result >= 0 else {throw Err.system(Errno(rawValue: errno))}
			
			/* Extract attribute names. */
			let list = namebuf.split(separator: 0).compactMap{
				$0.withUnsafeBufferPointer{
					$0.withMemoryRebound(to: UInt8.self){
						String(bytes: $0, encoding: .utf8)
					}
				}
			}
			return list
		}
		return list
	}
	
}
