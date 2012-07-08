/*
 This file is part of the TVShows source code.
 http://tvshows.sourceforge.net
 It may be used under the terms of the GNU General Public License.
*/

#import "ValueTransformers.h"

@implementation NonZeroValueTransformer
+ (Class)transformedValueClass;
{
    return [NSString class];
}
- (id)transformedValue:(id)value;
{
	if ( ![value isKindOfClass:[NSNumber class]] || [value intValue] == 0 ) {
		return @"";
	} else {
		return [value stringValue];
	}
}
@end

@implementation DownloadBooleanToTitleTransformer
+ (Class)transformedValueClass;
{
    return [NSString class];
}
- (id)transformedValue:(id)value;
{
	if ( [value boolValue] ) {
		return @"Unsubscribe";
	} else {
		return @"Subscribe";
	}
}
@end

@implementation EnabledToImagePathTransformer
+ (Class)transformedValueClass;
{
    return [NSString class];
}
- (id)transformedValue:(id)value;
{
	if ( [value boolValue] ) {
		return [[NSBundle mainBundle] pathForResource:@"Green" ofType:@"tif"];
	} else {
		return [[NSBundle mainBundle] pathForResource:@"Red" ofType:@"tif"];
	}
}
@end

@implementation EnabledToStringTransformer
+ (Class)transformedValueClass;
{
    return [NSString class];
}
- (id)transformedValue:(id)value;
{
	if ( [value boolValue] ) {
		return @"Enabled (quit to start daemon)";
	} else {
		return @"Disabled";
	}
}
@end

@implementation PathToNameTransformer
+ (Class)transformedValueClass;
{
    return [NSString class];
}
- (id)transformedValue:(id)value;
{
	if ( [value isKindOfClass:[NSString class]] ) {
		return [[NSFileManager defaultManager] displayNameAtPath:value];
	}
	return @"";
}
@end

@implementation IndexesToIndexTransformer
+ (Class)transformedValueClass;
{
    return [NSIndexSet class];
}
+ (BOOL)allowsReverseTransformation
{
	return YES;
}
- (id)transformedValue:(id)value;
{
	return [NSIndexSet indexSetWithIndex:[value intValue]];
}
- (id)reverseTransformedValue:(id)value
{
	return [NSNumber numberWithInt:[value firstIndex]];
}
@end

@implementation DetailToStringTransformer
+ (Class)transformedValueClass;
{
    return [NSString class];
}
- (id)transformedValue:(id)value;
{
	if ( ( nil == [value objectForKey:@"Subscribed"] ) || [[value objectForKey:@"Subscribed"] boolValue] ) {
    return [value objectForKey:@"LastSeen"];
	}
	return @"";
}
@end

@implementation DateToShortDateTransformer
+ (Class)transformedValueClass;
{
    return [NSString class];
}
- (id)transformedValue:(id)value;
{
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setDateStyle:NSDateFormatterShortStyle];
	[df setTimeStyle:NSDateFormatterShortStyle];
	return [df stringFromDate:value];
}
@end