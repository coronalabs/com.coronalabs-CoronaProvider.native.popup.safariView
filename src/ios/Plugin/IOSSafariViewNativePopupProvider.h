//
//  IOSSafariViewNativePopupProvider.h
//
//  Copyright (c) 2015 Corona Labs. All rights reserved.
//

#ifndef _IOSSafariViewNativePopupProvider_H__
#define _IOSSafariViewNativePopupProvider_H__

#include "CoronaLua.h"
#include "CoronaMacros.h"

// This corresponds to the name of the library, e.g. [Lua] require "plugin.library"
// where the '.' is replaced with '_'
CORONA_EXPORT int luaopen_CoronaProvider_native_popup_safariView( lua_State *L );
CORONA_EXPORT int luaopen_plugin_safariView( lua_State *L );

#endif // _IOSSafariViewNativePopupProvider_H__
