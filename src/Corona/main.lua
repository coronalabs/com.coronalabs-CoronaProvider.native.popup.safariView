

local myRectangle = display.newRect( display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight )
myRectangle:setFillColor( 0.5 )

local log = display.newText{
    text = "Tap anywhere to present safariView.\n",
    x = display.contentCenterX,
    y = display.contentCenterY,
    width = display.contentWidth,
    fontSize = 12,
    align = "center"
}

function safariListener(event)
	log.text = log.text .. "\nAction received: " .. event.action

	if event.action == "failed" then
		print("Page was not loaded properly :(")
	elseif event.action == "loaded" then
		print("Good news, page was loaded! ")
    elseif event.action == "done" then
        print("Safari view was closed")
    elseif event.action == "dismissed" then
        print("Safari view was dismissed")
    end
end

local popupOptions =
{
	  url="https://solar2d.com"
    , animated=true
    , barCollapsingEnabled=true
    , listener=safariListener
    , entersReaderIfAvailable = false
    , presentationStyle = "pageSheet"
    , dismissButton = "close"
    , backgroundColor = {0.0,0.2,0.0}
    , controlColor = {0.9,0,0}
}

-- Check if the safari view is available
local native = false
if native then
	print("NATIVE WAY")
	local safariViewAvailable = native.canShowPopup( "safariView" )

	if safariViewAvailable then
		-- Show the safari view
		native.showPopup( "safariView", popupOptions )
		-- timer.performWithDelay(5000, function()
		-- 	native.hidePopup( "safariView", popupOptions )
		-- end)
	else
		log.text = log.text .. "\nSafari view is not supported"
	end


	local function myTouchListener( event )
	    if event.phase == "ended" then
			if safariViewAvailable then
				-- Show the safari view
				native.showPopup( "safariView", popupOptions )
			else
				log.text = log.text .. "\nSafari view is not supported"
			end
	    end
	end
	Runtime:addEventListener( "touch", myTouchListener )
else
	print("PLUGIN WAY")
	local safariView = require "plugin.safariView"
	local safariViewAvailable = safariView.canShowPopup( "safariView" )

	if safariViewAvailable then
		-- Show the safari view
		safariView.showPopup( "safariView", popupOptions )
		print("TRYING TO HIDE 1")
		timer.performWithDelay(3000, function()
			print("TRYING TO HIDE")
			safariView.hidePopup( "safariView", popupOptions )
		end)
		print("TRYING TO HIDE 2")
	else
		log.text = log.text .. "\nSafari view is not supported"
	end


	local function myTouchListener( event )
	    if event.phase == "ended" then
			if safariViewAvailable then
				-- Show the safari view
				safariView.showPopup( "safariView", popupOptions )
			else
				log.text = log.text .. "\nSafari view is not supported"
			end
	    end
	end
	Runtime:addEventListener( "touch", myTouchListener )

end


local function onResize( event )
    log.x = display.contentCenterX
    log.y = display.contentCenterY
    
    print("Resize event!")
end

Runtime:addEventListener( "resize", onResize )
