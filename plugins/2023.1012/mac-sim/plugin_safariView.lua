local Library = require "CoronaLibrary"

-- Create library
local lib = Library:new{ name = 'plugin.safariView', publisherId = 'com.coronalabs' }

function lib.showPopup()
	native.showAlert( 'Not Supported', 'The safariView popup is currently not supported on this platform, please build for an iOS device', { 'OK' } )
end

function lib.canShowPopup()
	return false
end

function lib.hidePopUp()
	return false
end

-- Return an instance
return lib
