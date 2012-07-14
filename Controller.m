/*
 This file is part of the TVShows source code.
 http://tvshows.sourceforge.net
 It may be used under the terms of the GNU General Public License.
*/

#include "osdep.h"

#import "Controller.h"
#import "ValueTransformers.h"

// Toolbar
#define ToolbarFilter			@"Filter"
#define ToolbarPreferences		@"Preferences"
#define ToolbarUpdateShowList	@"UpdateShowList"

// Shows properties
#define ShowsVersion			@"Version"
#define ShowsLatestVersion		@"1"
#define ShowsShows				@"Shows"

// Show properties
#define ShowHumanName			@"HumanName"
#define ShowExactName			@"ExactName"
#define ShowEpisode				@"Episode"
#define	ShowSeason				@"Season"
#define ShowSubscribed			@"Subscribed"
#define ShowDate				@"Date"
#define ShowTitle				@"Title"
#define ShowType				@"Type"
#define ShowTime				@"Time"

// Types of shows
#define TypeSeasonEpisode		@"SeasonEpisodeType"
#define TypeDate				@"DateType"		
#define TypeTime				@"TimeType"

// Details keys
#define DetailsEpisodes			@"Episodes"

// Preferences keys
#define TVShowsIsEnabled			@"IsEnabled"
#define TVShowsAutomaticallyOpen	@"AutomaticallyOpen"
#define TVShowsCheckDelay			@"CheckDelay"
#define TVShowsQuality				@"Quality"
#define TVShowsTorrentFolder		@"TorrentFolder"
#define TVShowsScriptInstalledVersion @"ScriptVersion"

// Misc
#define TVShowsURL					@"http://tvshows.sourceforge.net"
#define TVShowsFeedbackURL			@"http://sourceforge.net/tracker/?group_id=190705"
#define TransmissionURL				@"http://transmission.m0k.org"

@implementation Controller

#pragma mark -
#pragma mark Init / AwakeFromNib

- (id)init
{
	self = [super init];
	if (self != nil) {
		
		// Experimental
		/*
		tableItems = [NSArray arrayWithObjects:
			[NSDictionary dictionaryWithObjectsAndKeys:@"GENERAL",@"Label",[NSNumber numberWithBool:YES],@"IsHeading",nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"Preferences",@"Label",[NSNumber numberWithBool:NO],@"IsHeading",nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"AVAILABLE SHOWS",@"Label",[NSNumber numberWithBool:YES],@"IsHeading",nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"The Shield",@"Label",[NSNumber numberWithBool:NO],@"IsHeading",nil],
			nil];
		*/
		
		h = [[Helper alloc] init];
		[self unloadFromLaunchd];
		
		[NSApp setDelegate:self];
		[self setDetails:[NSArray array]];
		
		[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
		
		retries = 0;
		qualities = [NSArray arrayWithObjects:
			[NSDictionary dictionaryWithObjectsAndKeys:@"Normal",@"quality",@"350Mb per episode",@"label",nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"High",@"quality",@"700Mb per episode",@"label",nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"Very High (720p)",@"quality",@"1.2Gb per episode",@"label",nil],
			nil];
		
		// Merge the defaults defaults with the defaults
		NSDictionary *userDefaultsDefaults = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"]];
		NSEnumerator *enumerator = [userDefaultsDefaults keyEnumerator];
		NSString *key;
		while ( key = [enumerator nextObject] ) {
			if ( ![[NSUserDefaults standardUserDefaults] objectForKey:key] ) {
				[[NSUserDefaults standardUserDefaults] setObject:[userDefaultsDefaults objectForKey:key] forKey:key];
			}
		}
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		if ( [[NSFileManager defaultManager] fileExistsAtPath:[h showsPath]] ) {
			[self setShows:[NSDictionary dictionaryWithContentsOfFile:[h showsPath]]];
		} else {
			[self setShows:nil];
		}
		
		NonZeroValueTransformer *tr1 = [[[NonZeroValueTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:tr1
										forName:@"NonZeroValueTransformer"];
		
		DownloadBooleanToTitleTransformer *tr2 = [[[DownloadBooleanToTitleTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:tr2
										forName:@"DownloadBooleanToTitleTransformer"];
		
		EnabledToImagePathTransformer *tr3 = [[[EnabledToImagePathTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:tr3
										forName:@"EnabledToImagePathTransformer"];
		
		EnabledToStringTransformer *tr4 = [[[EnabledToStringTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:tr4
										forName:@"EnabledToStringTransformer"];
		
		PathToNameTransformer *tr5 = [[[PathToNameTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:tr5
										forName:@"PathToNameTransformer"];
		
		IndexesToIndexTransformer *tr6 = [[[IndexesToIndexTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:tr6
										forName:@"IndexesToIndexTransformer"];
		
		DetailToStringTransformer *tr7 = [[[DetailToStringTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:tr7
										forName:@"DetailToStringTransformer"];
		
		DateToShortDateTransformer *tr8 = [[[DateToShortDateTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:tr8
										forName:@"DateToShortDateTransformer"];
		
		
    os_init();
	}
	return self;
}

- (void)awakeFromNib
{

	// Experimental
	/*
	[mainColumn setDataCell:[[TVTextFieldCell alloc] init]];
	*/
	
	[mainView addSubview:preferencesView];
	[mainView setNeedsDisplay:YES];
	[preferencesView setNeedsDisplay:YES];
	
	
	[showsTable setIntercellSpacing:NSMakeSize(3.0,10.0)];
	
	[defaultsController setAppliesImmediately:YES];
	
	// Register to some notifications		
	// Dowload shows
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mainWindowDidBecomeMain:)
												 name:NSWindowDidBecomeMainNotification
											   object:nil];
	
	// Toolbar
	mainToolbar = [[NSToolbar alloc] initWithIdentifier:@"mainToolbar"];
	[mainToolbar setDelegate:self];
	[mainToolbar setAllowsUserCustomization:YES];
	[mainWindow setToolbar:mainToolbar];
	
	[showsController setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:ShowSubscribed ascending:NO] autorelease]]];
	
}

#pragma mark -
#pragma mark Toolbar

- (NSToolbarItem *)toolbar: (NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
	
    if ( [itemIdentifier isEqualToString:ToolbarFilter] ) {
		[toolbarItem setLabel:@"Filter"];
		[toolbarItem setPaletteLabel:@"Filter"];
		[toolbarItem setToolTip:@"Filter shows name"];
		[toolbarItem setView:searchToolbarItemView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([searchToolbarItemView frame]),NSHeight([searchToolbarItemView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(150,NSHeight([searchToolbarItemView frame]))];
	} else if ( [itemIdentifier isEqualToString:ToolbarPreferences] ) {
		[toolbarItem setLabel:@"Preferences"];
		[toolbarItem setPaletteLabel:@"Preferences"];
		[toolbarItem setToolTip:@"Open preferences window"];
		[toolbarItem setImage:[NSImage imageNamed:@"Preferences.png"]];
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(openPreferences:)];
	} else if ( [itemIdentifier isEqualToString:ToolbarUpdateShowList] ) {
		[toolbarItem setLabel:@"Update list"];
		[toolbarItem setPaletteLabel:@"Update list"];
		[toolbarItem setToolTip:@"Updates the show list"];
		[toolbarItem setImage:[NSImage imageNamed:@"Reload.png"]];
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(downloadShowList)];
    } else {
		[toolbarItem release];
		toolbarItem = nil;
    }
    return toolbarItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers: (NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:ToolbarFilter,NSToolbarFlexibleSpaceItemIdentifier,ToolbarUpdateShowList,ToolbarPreferences,nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers: (NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:ToolbarFilter,NSToolbarFlexibleSpaceItemIdentifier,ToolbarUpdateShowList,ToolbarPreferences,nil];
}

#pragma mark -
#pragma mark Download Show List

- (void)mainWindowDidBecomeMain: (NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:nil];
	[self checkForBittorrentClient];
	if ( ![shows valueForKey:ShowsShows] || ([shows valueForKey:ShowsShows] && NSOrderedAscending == [[shows valueForKey:ShowsVersion] compare:ShowsLatestVersion options:NSNumericSearch])) 
		[self downloadShowList];
}

- (IBAction)downloadShowList
{
	[NSApp beginSheet:progressPanel
	   modalForWindow:mainWindow
		modalDelegate:self
	   didEndSelector:nil
		  contextInfo:nil];
	[progressPanelIndicator startAnimation:nil];
	
	NSTask *aTask = [[NSTask alloc] init];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadShowListDidFinish:) name:NSTaskDidTerminateNotification object:aTask];
	
  [aTask setLaunchPath: [NSString stringWithUTF8String:os_bundled_node_path]];
  [aTask setCurrentDirectoryPath: [NSString stringWithUTF8String:os_bundled_backend_path]];
  [aTask setArguments:[NSArray arrayWithObjects:@"download-show-list.js", nil]];
  NSPipe* err = [NSPipe pipe];
  [aTask setStandardError:err];
  [aTask setStandardOutput:err];
  [aTask launch];
}

- (void)downloadShowListDidFinish: (NSNotification *)notification
{
	if ( [(NSTask *)[notification object] terminationStatus] != 0 ) {
		[NSApp endSheet:progressPanel];
		[progressPanel close];
		[Helper dieWithErrorMessage:@"Could not download the show list. Are you connected to the internet ?"];
	} else {
		[self setShows:[NSDictionary dictionaryWithContentsOfFile:[h showsPath]]];
		[NSApp endSheet:progressPanel];
		[progressPanel close];
	}
}


#pragma mark -
#pragma mark Setters/Getters

- (NSArray *)qualities
{
	return qualities;
}

- (void)setQualities: (NSArray *)someQualities
{
	if ( someQualities != qualities ) {
		[qualities release];
		qualities = [someQualities retain];
	}
}

- (NSDictionary *)shows
{
	return shows;
}

- (void)setShows: (NSDictionary *)someShows
{
	if ( someShows != shows ) {
		[shows release];
		shows = [someShows retain];
	}
}

- (NSArray *)details;
{
	return details;
}

- (void)setDetails: (NSArray *)someDetails
{
	if ( someDetails != details ) {
		[details release];
		details = [someDetails retain];
	}
}
		
- (NSString *)currentShellOutput;
{
	return currentShellOutput;
}

- (void)setCurrentShellOutput: (NSString *)someOutput
{
	if ( someOutput != currentShellOutput ) {
		[currentShellOutput release];
		currentShellOutput = [someOutput retain];
	}
}

- (AMShellWrapper *)shellWrapper
{
	return shellWrapper;
}

- (void)setShellWrapper:(AMShellWrapper *)newShellWrapper
{
	id old = nil;
	
	if (newShellWrapper != shellWrapper) {
		old = shellWrapper;
		shellWrapper = [newShellWrapper retain];
		[old release];
	}
}

#pragma mark -
#pragma mark Preferences

- (IBAction)openPreferences: (id)sender
{
	[NSApp beginSheet:preferencesWindow
	   modalForWindow:mainWindow
		modalDelegate:self
	   didEndSelector:nil
		  contextInfo:nil];
	if ( ( [[[NSUserDefaults standardUserDefaults] valueForKey:TVShowsIsEnabled] boolValue] && [[enableDisableButton title] isEqualToString:@"Enabled"] ) ||
		( ![[[NSUserDefaults standardUserDefaults] valueForKey:TVShowsIsEnabled] boolValue] && [[enableDisableButton title] isEqualToString:@"Disable"] ) ) {
		[self enableDisable:enableDisableButton];
	}
	[preferencesWindow makeKeyAndOrderFront:sender];
}

- (IBAction)closePreferences: (id)sender
{
	[[NSUserDefaults standardUserDefaults] synchronize];
	[NSApp endSheet:preferencesWindow];
	[preferencesWindow close];
}

- (IBAction)enableDisable: (id)sender
{
	if ( [[sender title] isEqualToString:@"Enable"] ) {
		[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:TVShowsIsEnabled];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[sender setTitle:@"Disable"];
		[enableDisableLabel setStringValue:@"TVShows is enabled"];
	} else if ( [[sender title] isEqualToString:@"Disable"] ) {
		[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO] forKey:TVShowsIsEnabled];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[sender setTitle:@"Enable"];
		[enableDisableLabel setStringValue:@"TVShows is disabled"];
	}
}

- (IBAction)changeSaveFolder: (id)sender
{
	if ( 0 == [sender indexOfSelectedItem] ) {
		return;
	} else if ( 2 == [sender indexOfSelectedItem] ) {
		int result;
		NSOpenPanel *oPanel = [NSOpenPanel openPanel];
		[oPanel setAllowsMultipleSelection:YES];
		[oPanel setTitle:@"Torrents will be saved in..."];
		[oPanel setMessage:@"Choose the folder in which torrents will be downloaded."];
		[oPanel setDelegate:self];
		[oPanel setCanChooseFiles:NO];
		[oPanel setCanChooseDirectories:YES];
		result = [oPanel runModalForDirectory:NSHomeDirectory() file:nil types:nil];
		[sender selectItemAtIndex:0];
		if (result == NSOKButton) {
			[[NSUserDefaults standardUserDefaults] setObject:[oPanel filename] forKey:TVShowsTorrentFolder];
		}
	}
}

// ============================================================
// conforming to the AMShellWrapperDelegate protocol:
// ============================================================

// output from stdout
- (void)process:(AMShellWrapper *)wrapper appendOutput:(id)output
{
  NSString *ouput = [[self currentShellOutput] stringByAppendingString:output];
  [self setCurrentShellOutput:ouput];
}

// output from stderr
- (void)process:(AMShellWrapper *)wrapper appendError:(NSString *)error
{
	//[errorOutlet setString:[[errorOutlet string] stringByAppendingString:error]];
}

// This method is a callback which your controller can use to do other initialization
// when a process is launched.
- (void)processStarted:(AMShellWrapper *)wrapper
{
//	[progressIndicator startAnimation:self];
//	[runButton setTitle:@"Stop"];
//	[runButton setAction:@selector(stopTask:)];
}

// This method is a callback which your controller can use to do other cleanup
// when a process is halted.
- (void)processFinished:(AMShellWrapper *)wrapper withTerminationStatus:(int)resultCode
{
  	[self setShellWrapper:nil];
//	[textOutlet scrollRangeToVisible:NSMakeRange([[textOutlet string] length], 0)];
//	[errorOutlet scrollRangeToVisible:NSMakeRange([[errorOutlet string] length], 0)];
//	[runButton setEnabled:YES];
//	[progressIndicator stopAnimation:self];
//	[runButton setTitle:@"Execute"];
//	[runButton setAction:@selector(printBanner:)];

  // Already retried
	if ( retries >= 2 ) {
		
		retries = 0;
		[detailsProgressIndicator setHidden:YES];
		[detailsErrorText setStringValue:@"Could not reach eztv.it, please retry later."];
		return;
		
    // Should retry
	} else if ( resultCode != 0 ) {

		retries++;
		[self subscribe:nil];
    
    // Ok
	} else {
		retries = 0;
    NSString *errorString;    
    id someDetails = [NSPropertyListSerialization
                      propertyListFromData:[[self currentShellOutput] dataUsingEncoding:NSUTF8StringEncoding]
                      mutabilityOption:NSPropertyListImmutable
                      format:NULL
                      errorDescription:&errorString];
    
    if ( errorString ) {
      NSLog(@"TVShows: error getting show details (%@).",errorString);
      [errorString release];
      return;
    }
    
    [self setDetails:(NSArray *)someDetails];
    [detailsProgressIndicator setHidden:YES];
    [detailsErrorText setHidden:YES];
    [detailsTable setHidden:NO];
    [detailsOKButton setEnabled:YES];
    [detailsController setSelectedObjects:nil];	
    [self setCurrentShellOutput:nil];	
	}
}

- (void)processLaunchException:(NSException *)exception
{
  	NSString* temp=[NSString stringWithFormat:@"\rcaught %@ while executing command\r", [exception name]];
//	[textOutlet scrollRangeToVisible:NSMakeRange([[textOutlet string] length], 0)];
//	[errorOutlet scrollRangeToVisible:NSMakeRange([[errorOutlet string] length], 0)];
//	[runButton setEnabled:YES];
//	[progressIndicator stopAnimation:self];
//	[runButton setTitle:@"Execute"];
//	[runButton setAction:@selector(printBanner:)];
	[self setShellWrapper:nil];
  [self setCurrentShellOutput:nil];
}

#pragma mark -
#pragma mark Show list

- (IBAction)subscribe: (id)sender
{	
	if ( retries == 0 ) currentShow = [[showsController arrangedObjects] objectAtIndex:[sender clickedRow]];
	if ( ![[currentShow valueForKey:ShowSubscribed] boolValue] ) {
		if ( retries > 0 ) {
			[detailsErrorText setStringValue:[NSString stringWithFormat:@"Could not reach eztv.it, retrying (%d)...",retries]];
			[detailsErrorText setHidden:NO];
			[detailsErrorText display];
			sleep(2); // That's bad, I know
		} else {
			[self setDetails:[NSArray array]];
			[detailsErrorText setHidden:YES];
			[detailsProgressIndicator setHidden:NO];
			[detailsTable setHidden:YES];
			[detailsOKButton setEnabled:NO];
			[NSApp beginSheet:detailsSheet
			   modalForWindow:mainWindow
				modalDelegate:self
			   didEndSelector:nil
				  contextInfo:nil];
			[detailsProgressIndicator startAnimation:nil];
		}
    
    [self setCurrentShellOutput:@""];
    AMShellWrapper *wrapper = [[[AMShellWrapper alloc] 
                                initWithInputPipe:nil 
                                outputPipe:nil 
                                errorPipe:nil 
                                workingDirectory:[NSString stringWithUTF8String:os_bundled_backend_path] 
                                environment:nil 
                                arguments:[NSArray arrayWithObjects:
                                           [NSString stringWithUTF8String:os_bundled_node_path],
                                           @"get-show-details.js", 
                                           @"--show-id", 
                                           [[[showsController arrangedObjects] objectAtIndex:[sender clickedRow]] valueForKey:@"ShowId"], 
                                           nil] 
                                context:NULL] autorelease];
    
    [wrapper setDelegate:self];
    [self setShellWrapper:wrapper];
    
    NS_DURING
    if (shellWrapper) {
      [shellWrapper setOutputStringEncoding:NSASCIIStringEncoding];
      [shellWrapper startProcess];
      
      //[self write:@"launched: "];
      //[self write:[arguments objectAtIndex:0]];
      //[self write:@"\r"];
    } else {
      //[self write:@"Ops! Something went wrong.\r Was not able to execute command.\r"];
    }
    NS_HANDLER
    NSLog(@"Caught %@: %@", [localException name], [localException reason]);
    [self processLaunchException:localException];
    NS_ENDHANDLER
	} else {
		[currentShow setValue:[NSNumber numberWithBool:NO] forKeyPath:ShowSubscribed];
		[showsController rearrangeObjects];
	}
}

- (void)getShowDetailsDidFinish: (NSNotification *)notification
{	
}

- (IBAction)cancelSubscription: (id)sender
{
  [shellWrapper stopProcess];
	[currentShow setValue:[NSNumber numberWithBool:NO] forKeyPath:ShowSubscribed];
	[NSApp endSheet:detailsSheet];
	[detailsSheet close];
}

- (IBAction)okSubscription: (id)sender
{	
	NSDictionary *selectedShow = [[detailsController selectedObjects] objectAtIndex:0];
	
  [NSApp beginSheet:progressPanel
	   modalForWindow:detailsSheet
      modalDelegate:self
	   didEndSelector:nil
        contextInfo:nil];
	[progressPanelIndicator startAnimation:nil];
	
	NSTask *aTask = [[NSTask alloc] init];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(okSubscriptionFinish:) name:NSTaskDidTerminateNotification object:aTask];

  [aTask setLaunchPath: [NSString stringWithUTF8String:os_bundled_node_path]];
  [aTask setCurrentDirectoryPath: [NSString stringWithUTF8String:os_bundled_backend_path]];
  [aTask setArguments:[NSArray arrayWithObjects:@"subscribe-show-details.js", 
      @"--show-id",
      [selectedShow objectForKey:@"ShowId"],
      @"--file-name",
      [selectedShow objectForKey:@"FileName"],
      nil]];
  
  //[currentShow setValue:[NSNumber numberWithBool:YES] forKeyPath:ShowSubscribed];
  
//  NSPipe* err = [NSPipe pipe];
//  [aTask setStandardError:err];
//  [aTask setStandardOutput:err];
  [aTask launch];
}



- (void)okSubscriptionFinish: (NSNotification *)notification
{
  if ( [(NSTask *)[notification object] terminationStatus] != 0 ) {
    [NSApp endSheet:progressPanel];
    [progressPanel close];
    [Helper dieWithErrorMessage:@"Could not x,y,z. Are you connected to the internet?"];
  } else {
    [self setShows:[NSDictionary dictionaryWithContentsOfFile:[h showsPath]]];
    [NSApp endSheet:progressPanel];
    [progressPanel close];
  }
  
  [showsController rearrangeObjects];
	[NSApp endSheet:detailsSheet];
	[detailsSheet close];
}


- (IBAction)okSubscriptionToNextAiredEpisode: (id)sender
{	
	[currentShow setValue:[NSNumber numberWithBool:YES] forKeyPath:ShowSubscribed];
	
	[showsController rearrangeObjects];
	[NSApp endSheet:detailsSheet];
	[detailsSheet close];
}

- (void) tableView:(NSTableView*)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn*)tableColumn row:(int)row 
{
	if ( [[tableView tableColumns] lastObject] == tableColumn ) {
		[cell bind:@"title" toObject:[[showsController arrangedObjects] objectAtIndex:row] withKeyPath:ShowSubscribed options:[NSDictionary dictionaryWithObject:@"DownloadBooleanToTitleTransformer" forKey:NSValueTransformerNameBindingOption]];
	}
}

- (IBAction)filterShows: (id)sender
{
	if ( [[sender stringValue] length] > 0 ) {
		[showsController setFilterPredicate:[NSPredicate predicateWithFormat:@"HumanName CONTAINS[cd] %@",[sender stringValue]]];
	} else {
		[showsController setFilterPredicate:nil];
	}
}

#pragma mark -
#pragma mark launchd

- (void)unloadFromLaunchd
{
	NSTask *aTask = [[NSTask alloc] init];
	[aTask setLaunchPath:@"/bin/launchctl"];
	[aTask setArguments:[NSArray arrayWithObjects:@"unload",[h launchdPlistPath],nil]];
	[aTask launch];
	[aTask waitUntilExit];
	[aTask release];
}

- (void)loadIntoLaunchd
{
	NSTask *aTask = [[NSTask alloc] init];
	[aTask setLaunchPath:@"/bin/launchctl"];
	[aTask setArguments:[NSArray arrayWithObjects:@"load",[h launchdPlistPath],nil]];
	[aTask launch];
	[aTask waitUntilExit];
	[aTask release];
}

- (void)saveLaunchdPlist
{
	NSMutableDictionary *launchdProperties = [NSMutableDictionary dictionary];
	[[NSFileManager defaultManager] removeFileAtPath:[h launchdPlistPath] handler:nil];
	int checkDelay = [[[NSUserDefaults standardUserDefaults] objectForKey:TVShowsCheckDelay] intValue];
	if ( checkDelay <= 2 ) {
		switch (checkDelay) {
		case 0:
			[launchdProperties setObject:[NSNumber numberWithInt:15*60] forKey:@"StartInterval"];
			break;
		case 1:
			[launchdProperties setObject:[NSNumber numberWithInt:30*60] forKey:@"StartInterval"];
			break;
		}
		[launchdProperties setObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[[NSCalendarDate calendarDate] minuteOfHour]],@"Minute",nil]
							  forKey:@"StartCalendarInterval"];
	} else {
		[launchdProperties setObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[[NSCalendarDate calendarDate] hourOfDay]],@"Hour",nil]
							  forKey:@"StartCalendarInterval"];
	}	
	[launchdProperties setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"] 
						  forKey:@"Label"];
	[launchdProperties setObject:[NSArray arrayWithObjects:[NSString stringWithUTF8String:os_bundled_node_path],@"tv-shows.js",nil]
						  forKey:@"ProgramArguments"];
	[launchdProperties setObject:[Helper negate:[[NSUserDefaults standardUserDefaults] objectForKey:TVShowsIsEnabled]]
						  forKey:@"Disabled"];
	[launchdProperties setObject:[NSString stringWithUTF8String:os_log_file]
						  forKey:@"StandardErrorPath"];
  [launchdProperties setObject:[NSString stringWithUTF8String:os_log_file]
                        forKey:@"StandardOutPath"];
  
	[launchdProperties setObject:[NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:os_bundled_backend_path] forKey:@"TVSHOWSPATH"]
						  forKey:@"EnvironmentVariables"];
  [launchdProperties setObject:[NSString stringWithUTF8String:os_bundled_backend_path] forKey:@"WorkingDirectory"];
  
	[launchdProperties setObject:[NSNumber numberWithBool:YES]
						  forKey:@"RunAtLoad"];
	
	if ( ![launchdProperties writeToFile:[h launchdPlistPath] atomically:YES] )
		[Helper dieWithErrorMessage:@"could not write the ~/Library/LaunchAgents/net.sourceforge.tvshows.plist"];
}


#pragma mark -
#pragma mark Menu handlers

- (IBAction)find: (id)sender
{
	[mainWindow makeFirstResponder:searchToolbarItemTextField];
}

- (IBAction)help: (id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:TVShowsURL]];
}

- (IBAction)sendFeedback: (id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:TVShowsFeedbackURL]];
}

#pragma mark -
#pragma mark Misc

- (void)applicationWillTerminate: (NSNotification *)aNotification
{
	[shows writeToFile:[h showsPath] atomically:YES];
	[self saveLaunchdPlist];
	[self loadIntoLaunchd];	
}

- (IBAction)test: (id)sender
{
	[defaultsController save:self];
}

- (BOOL)shouldGreenRowAtIndex: (int)index
{
	if ( index < [[showsController arrangedObjects] count] )
		return [[[[showsController arrangedObjects] objectAtIndex:index] objectForKey:ShowSubscribed] boolValue];
	return NO;
}

- (void)checkForBittorrentClient
{
	if ( kLSApplicationNotFoundErr == LSGetApplicationForInfo(kLSUnknownType,kLSUnknownCreator,CFSTR("torrent"),kLSRolesAll,NULL,NULL) ) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"Download Transmission"];
		[alert addButtonWithTitle:@"No"];
		[alert setMessageText:@"You need a Bittorrent client to use TVShows, would you like to download one?"];
		[alert setInformativeText:@"We recommend Transmission, a great client."];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(checkForBittorrentClientAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	}
}

- (void)checkForBittorrentClientAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertFirstButtonReturn) {
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:TransmissionURL]];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

@end
