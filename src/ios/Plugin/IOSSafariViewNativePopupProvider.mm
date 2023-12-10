//
//  IOSSafariViewNativePopupProvider.mm
//
//  Copyright (c) 2015 Corona Labs. All rights reserved.
//

#import "IOSSafariViewNativePopupProvider.h"

#include "CoronaRuntime.h"
#include "CoronaEvent.h"
#include "CoronaAssert.h"
#include "CoronaLibrary.h"

#import <SafariServices/SafariServices.h>



// ----------------------------------------------------------------------------

namespace IOSSafariViewNativePopupProvider
{
	// This corresponds to the event name, e.g. [Lua] event.name
	static const char *kPopupName = "safariView";

	int canShowPopup( lua_State *L );
	int hidePopup( lua_State *L );
	int showPopup( lua_State *L );
};


// ----------------------------------------------------------------------------

@interface SafariViewCloseWatch : NSObject <SFSafariViewControllerDelegate>

- (instancetype)initWithLuaState: (lua_State*)L andListener:(CoronaLuaRef)listener;

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller;

- (void)safariViewController:(SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully;

@property (nonatomic, assign) lua_State *luaState;
@property (nonatomic, assign) Corona::Lua::Ref listenerRef;

@end

@implementation SafariViewCloseWatch

-(instancetype)initWithLuaState:(lua_State *)L andListener:(CoronaLuaRef)listener
{
	self = [super init];
	if (self)
	{
		self.luaState = L;
		self.listenerRef = listener;
	}
	return self;
}

-(void)safariViewController:(SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully
{
	CoronaLuaNewEvent( self.luaState, CoronaEventPopupName() );
	
	lua_pushstring( self.luaState, IOSSafariViewNativePopupProvider::kPopupName );
	lua_setfield( self.luaState, -2, CoronaEventTypeKey() );
	
	if (didLoadSuccessfully)
	{
		lua_pushstring( self.luaState, "loaded" );
	}else
	{
		lua_pushstring( self.luaState, "failed" );
	}
	
	lua_setfield( self.luaState, -2, "action" );

	
	CoronaLuaDispatchEvent( self.luaState, self.listenerRef, 1 );
}

-(void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
	CoronaLuaNewEvent( self.luaState, CoronaEventPopupName() );
	
	lua_pushstring( self.luaState, IOSSafariViewNativePopupProvider::kPopupName );
	lua_setfield( self.luaState, -2, CoronaEventTypeKey() );
	
	lua_pushstring( self.luaState, "done" );
	lua_setfield( self.luaState, -2, "action" );
	
	lua_pushboolean( self.luaState, 0 );
	lua_setfield( self.luaState, -2, CoronaEventIsErrorKey() );
	
	CoronaLuaDispatchEvent( self.luaState, self.listenerRef, 1 );
	
	//cleanup
	CoronaLuaDeleteRef( self.luaState, self.listenerRef );
	[self release];
}

@end

@interface SafariViewDismissWatch : NSObject <UIAdaptivePresentationControllerDelegate>

- (instancetype)initWithLuaState: (lua_State*)L andListener:(CoronaLuaRef)listener;

- (void)presentationControllerDidDismiss:(UIPresentationController *)controller;

//- (void)safariViewController:(SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully;

@property (nonatomic, assign) lua_State *luaState;
@property (nonatomic, assign) Corona::Lua::Ref listenerRef;

@end

@implementation SafariViewDismissWatch

-(instancetype)initWithLuaState:(lua_State *)L andListener:(CoronaLuaRef)listener
{
    self = [super init];
    if (self)
    {
        self.luaState = L;
        self.listenerRef = listener;
    }
    return self;
}

-(void)presentationControllerDidDismiss:(UIPresentationController *)controller
{
    CoronaLuaNewEvent( self.luaState, CoronaEventPopupName() );
    
    lua_pushstring( self.luaState, IOSSafariViewNativePopupProvider::kPopupName );
    lua_setfield( self.luaState, -2, CoronaEventTypeKey() );
    
    lua_pushstring( self.luaState, "dismissed" );
    lua_setfield( self.luaState, -2, "action" );
    
    lua_pushboolean( self.luaState, 0 );
    lua_setfield( self.luaState, -2, CoronaEventIsErrorKey() );
    
    CoronaLuaDispatchEvent( self.luaState, self.listenerRef, 1 );
    
    //cleanup
    CoronaLuaDeleteRef( self.luaState, self.listenerRef );
    [self release];
}

@end

// [lua] local safariViewAvailiable = native.canShowPopup( "safariView" )
int
IOSSafariViewNativePopupProvider::canShowPopup( lua_State *L )
{
	bool canShow = ( NSClassFromString( @"SFSafariViewController" ) != Nil );
	lua_pushboolean( L, canShow );
	return 1;
}

int
IOSSafariViewNativePopupProvider::hidePopup( lua_State *L )
{
	bool result = false;
	int index = 2;
	
	if ( [SFSafariViewController class] )
	{
		BOOL animated = NO;
		
		if ( lua_istable( L, index ) )
		{
			lua_getfield( L, index, "animated" );
			if ( lua_isboolean( L, -1 ) )
			{
				animated = lua_toboolean( L, -1 );
			}
			lua_pop( L, 1 );
		}
		
		@try {
			id<CoronaRuntime> runtime = (id<CoronaRuntime>)CoronaLuaGetContext( L );
			UIViewController *vc = runtime.appViewController;
			if([vc.presentedViewController isKindOfClass:[SFSafariViewController class]])
			{
				[vc.presentedViewController dismissViewControllerAnimated:animated completion:nil];
				result = true;
			}
		}
		@catch (NSException *exception) {
			const char* err = [exception.reason UTF8String];
			if ( !err)
			{
				err = "unknown";
			}
			CoronaLuaWarning( L, "safariView.show(), internal error: %s", err);
		}
	}
	lua_pushboolean(L, result);
	return 1;
}

// [Lua] native.showPopup( "safariView", { url="https://coronalabs.com" [, animated=false][, listener=safariListener]} )
int
IOSSafariViewNativePopupProvider::showPopup( lua_State *L )
{
	int index = 2;
	bool result = false;
	
	if ( [SFSafariViewController class] )
	{
		BOOL animated = NO;
        BOOL entersReaderIfAvailiable = NO;
        BOOL barCollapsingEnabled = NO;
        
        BOOL uiPresentationModal = NO;
        
        float bgTintR = 1;
        float bgTintG = 1;
        float bgTintB = 1;
        bool bgTintColor = NO;
        
        float contTintR = 1;
        float contTintG = 1;
        float contTintB = 1;
        bool contTintColor = NO;
        
		CoronaLuaRef listener = 0;
        
        const char *szUrl = 0;
        const char *presentationStyle = 0;
        const char *dismissButton = 0;
		
		if( lua_isstring( L, index) )
		{
			szUrl = lua_tostring( L, index );
		}
		else if ( lua_istable( L, index ) )
		{
			lua_getfield( L, index, "url" );
			if ( lua_isstring( L, -1 ) )
			{
				szUrl = lua_tostring( L, -1 );
			}
			lua_pop( L, 1 );
			
			lua_getfield( L, index, "animated" );
			if ( lua_isboolean( L, -1 ) )
			{
				animated = lua_toboolean( L, -1 );
			}
			lua_pop( L, 1 );
            
            lua_getfield( L, index, "entersReaderIfAvailable" );
            if ( lua_isboolean( L, -1 ) )
            {
                entersReaderIfAvailiable = lua_toboolean( L, -1 );
            }
            lua_pop( L, 1 );
            
            lua_getfield( L, index, "barCollapsingEnabled" );
            if ( lua_isboolean( L, -1 ) )
            {
                barCollapsingEnabled = lua_toboolean( L, -1 );
            }
            lua_pop( L, 1 );
            
            lua_getfield( L, index, "presentationStyle" );
            if ( lua_isstring( L, -1 ) )
            {
                presentationStyle = lua_tostring( L, -1 );
            }
            lua_pop( L, 1 );
            
            lua_getfield( L, index, "dismissButton" );
            if ( lua_isstring( L, -1 ) )
            {
                dismissButton = lua_tostring( L, -1 );
            }
            lua_pop( L, 1 );
            
            lua_getfield( L, index, "backgroundColor" );
            if ( lua_istable( L, -1 ) )
            {
                if ( lua_objlen(L, -1 ) == 1)
                {
                    lua_rawgeti(L, -1, 1);
                    if ( lua_isnumber( L, -1 ) )
                    {
                        bgTintR = lua_tonumber( L, -1 );
                        bgTintG = bgTintR;
                        bgTintB = bgTintR;
                        bgTintColor = YES;
                    }
                }
                else if ( lua_objlen(L, -1 ) == 3)
                {
                    lua_rawgeti(L, -1, 1);
                    if ( lua_isnumber( L, -1 ) )
                    {
                        
                        bgTintR = lua_tonumber( L, -1 );
                        bgTintColor = YES;
                        
                    }
                    lua_pop( L, 1 );
                    
                    lua_rawgeti(L, -1, 2);
                    if ( lua_isnumber( L, -1 ) )
                    {
                        bgTintG = lua_tonumber( L, -1 );
                        
                    } else {
                        bgTintColor = NO;
                    }
                    lua_pop( L, 1 );
                    
                    lua_rawgeti(L, -1, 3);
                    if ( lua_isnumber( L, -1 ) )
                    {
                        bgTintB = lua_tonumber( L, -1 );
                        
                    } else {
                        bgTintColor = NO;
                    }
                    lua_pop( L, 1 );
                }
            }
            lua_pop( L, 1 );
            
            lua_getfield( L, index, "controlColor" );
            if ( lua_istable( L, -1 ) )
            {
                if ( lua_objlen(L, -1 ) == 1)
                {
                    lua_rawgeti(L, -1, 1);
                    if ( lua_isnumber( L, -1 ) )
                    {
                        contTintR = lua_tonumber( L, -1 );
                        contTintG = contTintR;
                        contTintB = contTintR;
                        contTintColor = YES;
                    }
                }
                else if ( lua_objlen(L, -1 ) == 3)
                {
                    lua_rawgeti(L, -1, 1);
                    if ( lua_isnumber( L, -1 ) )
                    {
                        contTintR = lua_tonumber( L, -1 );
                        contTintColor = YES;
                        
                    }
                    lua_pop( L, 1 );
                    
                    lua_rawgeti(L, -1, 2);
                    if ( lua_isnumber( L, -1 ) )
                    {
                        contTintG = lua_tonumber( L, -1 );
                        
                    } else {
                        contTintColor = NO;
                    }
                    lua_pop( L, 1 );
                    
                    lua_rawgeti(L, -1, 3);
                    if ( lua_isnumber( L, -1 ) )
                    {
                        contTintB = lua_tonumber( L, -1 );
                        
                    } else {
                        contTintColor = NO;
                    }
                    lua_pop( L, 1 );
                }
            }
            lua_pop( L, 1 );
			
			lua_getfield( L, index, "listener" );
			if ( szUrl && CoronaLuaIsListener( L, -1, IOSSafariViewNativePopupProvider::kPopupName) )
			{
				listener = CoronaLuaNewRef( L, -1 );
			}
			lua_pop( L, 1 );
		}
		
		if (szUrl)
		{
			@try {
                
				NSURL *url = [NSURL URLWithString:[NSString stringWithUTF8String:szUrl]];
                
                SFSafariViewControllerConfiguration *config = [[SFSafariViewControllerConfiguration alloc] init];
                config.entersReaderIfAvailable = entersReaderIfAvailiable;
                config.barCollapsingEnabled = barCollapsingEnabled;
                
                SFSafariViewController* controller = [[[SFSafariViewController alloc] initWithURL:url configuration:config] autorelease];
                
				if (listener)
				{
					// listener will release itself
					controller.delegate = [[SafariViewCloseWatch alloc] initWithLuaState:L andListener:listener];
				}
                
                if (presentationStyle)
                {
                    if (strcmp(presentationStyle,"pageSheet")==0) {
                        controller.modalPresentationStyle = UIModalPresentationPageSheet;
                        uiPresentationModal = YES;
                    } else if (strcmp(presentationStyle,"automatic")==0) {
                        controller.modalPresentationStyle = UIModalPresentationAutomatic;
                        uiPresentationModal = YES;
                    } else if (strcmp(presentationStyle,"formSheet")==0) {
                        controller.modalPresentationStyle = UIModalPresentationFormSheet;
                        uiPresentationModal = YES;
                    } else if (strcmp(presentationStyle,"popover")==0) {
                        controller.modalPresentationStyle = UIModalPresentationPopover;
                        uiPresentationModal = YES;
                    } else if (strcmp(presentationStyle,"fullScreen")==0) {
                        controller.modalPresentationStyle = UIModalPresentationFullScreen;
                        uiPresentationModal = YES;
                    } else if (strcmp(presentationStyle,"overFullScreen")==0) {
                        controller.modalPresentationStyle = UIModalPresentationOverFullScreen;
                        uiPresentationModal = YES;
                    } else if (strcmp(presentationStyle,"currentContext")==0) {
                        controller.modalPresentationStyle = UIModalPresentationCurrentContext;
                        uiPresentationModal = YES;
                    }
                }
                
                if (dismissButton)
                {
                    if (strcmp(dismissButton,"cancel")==0) {
                        controller.dismissButtonStyle = SFSafariViewControllerDismissButtonStyleCancel;
                    } else if (strcmp(dismissButton,"close")==0) {
                        controller.dismissButtonStyle = SFSafariViewControllerDismissButtonStyleClose;
                    } else if (strcmp(dismissButton,"done")==0) {
                        controller.dismissButtonStyle = SFSafariViewControllerDismissButtonStyleDone;
                    }
                }
                
                if (bgTintColor)
                {
                    controller.preferredBarTintColor = [UIColor colorWithRed:bgTintR green:bgTintG blue:bgTintB alpha:1.0];
                }
                
                if (contTintColor)
                {
                    controller.preferredControlTintColor = [UIColor colorWithRed:contTintR green:contTintG blue:contTintB alpha:1.0];
                }
                
                
                if (listener and uiPresentationModal)
                {
                    // listener will release itself
                    controller.presentationController.delegate = [[SafariViewDismissWatch alloc] initWithLuaState:L andListener:listener];
                }
                
				// Present the controller
				id<CoronaRuntime> runtime = (id<CoronaRuntime>)CoronaLuaGetContext( L );
				[runtime.appViewController presentViewController:controller animated:animated completion:nil];
				result = true;
			}
			@catch (NSException *exception) {
				const char* err = [exception.reason UTF8String];
				if ( !err)
				{
					err = "unknown";
				}
				CoronaLuaWarning( L, "safariView.show(), internal error: %s", err);
				if( listener )
				{
					CoronaLuaDeleteRef( L, listener );
				}
			}
		}
		else
		{
			CoronaLuaWarning( L, "safariView.show(), no url provided as a single string parameter or 'url' field" );
		}
	}
	
	lua_pushboolean( L, result );
	return 1;
}

// ----------------------------------------------------------------------------
static const luaL_Reg kVTable[] =
{
	{ "canShowPopup", IOSSafariViewNativePopupProvider::canShowPopup },
	{ "showPopup", IOSSafariViewNativePopupProvider::showPopup },
	{ "hidePopup", IOSSafariViewNativePopupProvider::hidePopup },

	{ NULL, NULL }
};

CORONA_EXPORT int luaopen_CoronaProvider_native_popup_safariView( lua_State *L )
{
	const char *name = lua_tostring( L, 1 );
	CORONA_ASSERT( 0 == strcmp( IOSSafariViewNativePopupProvider::kPopupName, name ) );
	int result = CoronaLibraryProviderNew( L, "native.popup", name, "com.coronalabs" );
	
	if (result>0)
	{
		int libIndex = lua_gettop( L );
		lua_pushvalue( L, libIndex ); // push library
		
		luaL_openlib( L, NULL, kVTable, 0 );
		lua_pop( L, 1 ); // pop library
	}
	
	return result;
}

CORONA_EXPORT int luaopen_plugin_safariView( lua_State *L )
{
	luaL_openlib( L, "plugin.safariView", kVTable, 0 );
	return 1;
}
