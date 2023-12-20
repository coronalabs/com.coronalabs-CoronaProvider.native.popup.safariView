local Library = require "CoronaLibrary"

-- Create library
local lib = Library:new{ name = 'CoronaProvider.native.popup.safariView', publisherId = 'com.coronalabs' }

-- native.showPopup
function lib.showPopup()
	native.showAlert( 'Not Supported', 'The safariView popup is currently not supported on this platform, please build for an iOS device', { 'OK' } )
end

-- native.canShowPopup
function lib.canShowPopup()
	return false
end

-- Return an instance
return lib
