# MacOS token extension for TCKK identity cards

If you run the host application inside in Xcode, it should register itself as a plugin on system. 
Just run `pluginkit -mv |grep EkkTokenExtension` on terminal and see if it's registered.

If not, open a terminal and run 
 `pluginkit -a ~/Library/Developer/Xcode/DerivedData/EkkTokenHost-*/Build/Products/Debug/EkkTokenHost.app/Contents/PlugIns/EkkTokenExtension.appex`

This command will register the extension only for user account.

If you want to debug the extension you should Attach the process with the name of "EkkTokenExtension" and insert the smart card.
This should load the extension and stop your breakpoints.

My intention is using the identity card on login but I can't. This extension is uncompleted and needs working on it.
