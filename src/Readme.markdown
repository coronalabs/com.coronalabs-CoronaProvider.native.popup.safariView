# plugin.native-popup-safariView


## Overview

This plugin provides `"safariView"` native popup. It can be used to present iOS9 Safari View Controller (`SFSafariViewController`).

## Platform support

* iOS

## Usage

### Checking availability
```lua
native.canShowPopup( "safariView" )
```

Returns boolean value, indicating if Safari View Controller is available.

### Showing Safari View Controller

```lua
native.showPopup( "safariView", url )
native.showPopup( "safariView", { url=url, animated=false, listener=safariListener })
```

Call `native.showPopup` with first parameter `"safariView"` to present Safari View Controller. Second parameter must contain parameters table or single string with web address (treated as `url` field in parameters table).

See below for description of parameters table fields.

#### Parameters

##### `url`
String with web address to be opened. Must have`http://` or `https://` url scheme.

##### `animated` (_optional_)

Boolean value, if `true` controller would slide in. Otherwise it will appear instantly.


##### `listener` (_optional_)

Function to be called when safari view is loaded or closed. Field `action` would indicate status:

* `'loaded'` - initial loading is finished.
* `'failed'` - there was an error while loading page (safari view is still displayed).
* `'done'` - indicates that user pressed "Done" button and Safari View Controller was closed


#### Return value

Function `native.showPopup( "safariView", ... )` returns single boolean value:

* `true` would indicate that Safari View Controller is presented
* `false` - error occurred.


## Enabling plugin
Add following entry to `settings` table in `build.settings`:

```lua

plugins =
{
	["CoronaProvider.native.popup.safariView"] =
	{
		publisherId = "com.coronalabs",
		supportedPlatforms = { iphone=true, ["iphone-sim"]=true },
	},
},

```

## Example

```lua

function safariListener(event)
	if event.action == "failed" then
			print("Page was not loaded properly :(")
	elseif event.action == "loaded" then
			print("Good news, page was loaded! ")
	elseif event.action == "done" then
		print("Safari view was closed")
	end
end

local popupOptions =
{
	  url="https://coronalabs.com"
	, animated=false
	, listener=safariListener
}

-- Check if the safari view is available
local safariViewAvailable = native.canShowPopup( "safariView" )

if safariViewAvailable then
	-- Show the safari view
	native.showPopup( "safariView", popupOptions )
end

```
