

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
    elseif event.action == "dismissing" then
        print("Safari view will be dismissed")
    end
end

local popupOptions =
{
    url="https://solar2d.com"
    , prewarm={"https://solar2d.com","https://apple.com"}
    -- , prewarm="https://solar2d.com"
    , animated=true
    , barCollapsingEnabled=true
    , listener=safariListener
    , entersReaderIfAvailable = false
    , presentationStyle = "pageSheet"
    , dismissButton = "close"
    , backgroundColor = {0.25}
    , controlColor = {0.5,0.5,0.8}
}
}

-- Check if the safari view is available
local native = false
if native then
	print("NATIVE WAY")
	local safariViewAvailable = native.canShowPopup( "safariView" )

	if safariViewAvailable then
		-- Show the safari view
		native.prewarmUrls( "safariView", popupOptions )
        timer.performWithDelay(3000, function()
            native.showPopup( "safariView", popupOptions )
        end)
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
		safariView.prewarmUrls( "safariView", popupOptions )
		print("Prewarming ...")
		timer.performWithDelay(3000, function()
			print("Show ...")
			safariView.showPopup( "safariView", popupOptions )
		end)
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
