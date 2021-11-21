import Foundation
import System



public enum XattrError : Error {
	
	case notFileURL
	case system(Errno)
	
}

typealias Err = XattrError
