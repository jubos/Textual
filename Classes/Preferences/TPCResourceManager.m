/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

@implementation TPCResourceManager

+ (void)copyResourcesToCustomAddonsFolder
{
	/* Copy specific resource files to the custom addons folder. */
	/* For now, we only are copying the text file containing information
	 about installing custom scripts. */

	/* Copy script information. */
	NSString *destnPath = [[TPCPreferences applicationSupportFolderPath] stringByAppendingPathComponent:@"/Installing Custom Scripts.txt"];
	NSString *sourePath = [[TPCPreferences bundledScriptFolderPath] stringByAppendingPathComponent:@"/Installing Custom Scripts.txt"];

	/* Only copy if it does not exist. */
	if ([RZFileManager() fileExistsAtPath:destnPath] == NO) {
		[RZFileManager() copyItemAtPath:sourePath toPath:destnPath error:NULL]; // We don't care about erros.
	}
	
	/* Add a system link for the unsupervised scripts folder if it exists. */
	sourePath = [TPCPreferences systemUnsupervisedScriptFolderPath];
	destnPath = [[TPCPreferences applicationSupportFolderPath] stringByAppendingPathComponent:@"/Custom Scripts/"];
	
	if ([RZFileManager() fileExistsAtPath:sourePath] && [RZFileManager() fileExistsAtPath:destnPath] == NO) {
		[RZFileManager() createSymbolicLinkAtPath:destnPath withDestinationPath:sourePath error:NULL];
	}
	
#ifdef TEXTUAL_BUILT_WITH_ICLOUD_SUPPORT
	/* Add a system link for the iCloud folder if the iCloud folder exists. */
	destnPath = [[TPCPreferences applicationSupportFolderPath] stringByAppendingPathComponent:@"/iCloud Resources/"];
	sourePath = [self.masterController.cloudSyncManager ubiquitousContainerURLPath];
	
	if ([self.masterController.cloudSyncManager ubiquitousContainerIsAvailable]) {
		if ([RZFileManager() fileExistsAtPath:destnPath] == NO) {
			[RZFileManager() createSymbolicLinkAtPath:destnPath withDestinationPath:sourePath error:NULL]; // We don't care about errors.
		}
	}
#endif

	/* We're done here for now… */
}

@end

@implementation TPCResourceManagerDocumentTypeImporter

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
	PointerIsEmptyAssertReturn(url, NO);
	
	/* Is it a script? */
	if ([url.absoluteString hasSuffix:TPCResourceManagerScriptDocumentTypeExtension]) {
		[self performImportOfScriptFile:url];
		
		return YES;
	}
	
	/* Is it a plugin? */
	NSString *pluginSuffix = [TPCResourceManagerBundleDocumentTypeExtension stringByAppendingString:@"/"]; // It's a folder…
	
	if ([url.absoluteString hasSuffix:pluginSuffix]) {
		[self performImportOfPluginFile:url];
		
		return YES;
	}
	
	return NO;
}

#pragma mark -
#pragma mark Custom Plugin Files

- (void)performImportOfPluginFile:(NSURL *)url
{
	PointerIsEmptyAssert(url);
	
	/* Establish install path. */
	NSString *filename = [url lastPathComponent];
	
	NSString *newPath = [[TPCPreferences customExtensionFolderPath] stringByAppendingPathComponent:filename];
	
	/* Try to import. */
	BOOL didImport = [self import:url into:[NSURL fileURLWithPath:newPath]];
	
	/* Was it successful? */
	if (didImport) {
		filename = [filename stringByDeletingPathExtension];
		
		[TLOPopupPrompts dialogWindowWithQuestion:TXTFLS(@"ResourcesFileImportBundleInstallSuccessDialogMessage", filename)
											title:TXTLS(@"ResourcesFileImportBundleInstallSuccessDialogTitle")
									defaultButton:TXTLS(@"OkButton")
								  alternateButton:nil
								   suppressionKey:nil
								  suppressionText:nil];
	}
}

#pragma mark -
#pragma mark Custom Script Files

- (void)performImportOfScriptFile:(NSURL *)url
{
	/* Scripts can only be Mountain Lion or later. */
	if ([TPCPreferences featureAvailableToOSXMountainLion] == NO) {
		[TLOPopupPrompts dialogWindowWithQuestion:TXTLS(@"ResourcesFileImportSystemVersionErrorDialogMessage")
											title:TXTLS(@"ResourcesFileImportSystemVersionErrorDialogTitle")
									defaultButton:TXTLS(@"OkButton")
								  alternateButton:nil
								   suppressionKey:nil
								  suppressionText:nil];
		
		return; // Cancel.
	}
	
	/* Script install. */
	NSSavePanel *d = [NSSavePanel savePanel];
	
	/* First we need to check which folder exists where. We are going to try
	 and bring users to the actual scripts folder, but if that does not exist,
	 then we bring them to the root folder for them to create it. */
	NSString *txtlsFolder = [TPCPreferences systemUnsupervisedScriptFolderPath];
	
	BOOL scriptsFolderExists = NO;
	
	if ([RZFileManager() fileExistsAtPath:txtlsFolder isDirectory:&scriptsFolderExists] == NO) {
		txtlsFolder = [TPCPreferences systemUnsupervisedScriptFolderRootPath];
	}
	
	NSURL *folderRep = [NSURL fileURLWithPath:txtlsFolder isDirectory:YES];
	
	/* Show save panel to user. */
	[d setCanCreateDirectories:YES];
	[d setDirectoryURL:folderRep];
	[d setTitle:TXTLS(@"ResourcesFileImportScriptSaveDialogTitle")];
	[d setMessage:TXTFLS(@"ResourcesFileImportScriptSaveDialogMessage", [TPCPreferences applicationBundleIdentifier])];
	[d setNameFieldStringValue:[url lastPathComponent]];
	
#ifdef TXSystemIsMacOSMavericksOrNewer
	if ([TPCPreferences featureAvailableToOSXMavericks]) {
		[d setShowsTagField:NO];
	}
#endif
	
	/* Complete the import. */
	[d beginWithCompletionHandler:^(NSInteger returnCode) {
		if (returnCode == NSOKButton) {
			if ([self import:url into:d.URL]) {
				/* Script was successfully installed. */
				NSString *filename = [d.URL.lastPathComponent stringByDeletingPathExtension];
	
				/* Perform after a delay to allow sheet to close. */
				[self performSelector:@selector(performImportOfScriptFilePostflight:) withObject:filename afterDelay:0.5];
			}
		}
	}];
}

- (void)performImportOfScriptFilePostflight:(NSString *)filename
{
	[TLOPopupPrompts dialogWindowWithQuestion:TXTFLS(@"ResourcesFileImportScriptInstallSuccessDialogMessage", filename)
										title:TXTLS(@"ResourcesFileImportScriptInstallSuccessDialogTitle")
								defaultButton:TXTLS(@"OkButton")
							  alternateButton:nil
							   suppressionKey:nil
							  suppressionText:nil];
}

#pragma mark -
#pragma mark General Import Controller

- (BOOL)import:(NSURL *)url into:(NSURL *)destination
{
	PointerIsEmptyAssertReturn(url, NO);
	PointerIsEmptyAssertReturn(destination, NO);
	
	NSError *instError;
	
	/* Try to remove the existing item before continuing. */
	if ([destination checkResourceIsReachableAndReturnError:NULL]) {
		BOOL trashed = [RZFileManager() trashItemAtURL:destination resultingItemURL:nil error:&instError];
		
		if (trashed == NO && instError) {
			LogToConsole(@"Install Error:\nFrom: %@\nTo: %@\nError: %@", url, destination, [instError localizedDescription]);
			
			return NO;
		}
	}
	
	/* Move the new item into place. */
	[RZFileManager() copyItemAtURL:url toURL:destination error:&instError];
	
	if (instError) {
		LogToConsole(@"Install Error:\nFrom: %@\nTo: %@\nError: %@", url, destination, [instError localizedDescription]);
		
		return NO;
	}
	
	return YES;
}

@end

