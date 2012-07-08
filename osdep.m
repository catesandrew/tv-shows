#include "osdep.h"

#import <Cocoa/Cocoa.h>

const char *os_bundled_resources_path;
const char *os_bundled_backend_path;
const char *os_bundled_node_path;
const char *os_preferences_path;
const char *os_log_path;
const char *os_log_file;

static void os_compute_paths() {
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];

    os_bundled_resources_path = strdup([resourcePath UTF8String]);
    os_bundled_node_path = strdup([[resourcePath stringByAppendingPathComponent:@"TVShowsNodejs"] UTF8String]);
    os_bundled_backend_path = strdup([[resourcePath stringByAppendingPathComponent:@"TVShowsScript"] UTF8String]);

    NSString *libraryFolder = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"TVShows"];

    NSString *logFolder = [libraryFolder stringByAppendingPathComponent:@"Logs"];
    NSString *dataFolder = [libraryFolder stringByAppendingPathComponent:@"Data"];

    os_log_path = strdup([logFolder UTF8String]);
    os_log_file = strdup([[logFolder stringByAppendingPathComponent:@"log.txt"] UTF8String]);
    os_preferences_path = strdup([dataFolder UTF8String]);

    [[NSFileManager defaultManager] createDirectoryAtPath:logFolder withIntermediateDirectories:YES attributes:nil error:NULL];
    [[NSFileManager defaultManager] createDirectoryAtPath:dataFolder withIntermediateDirectories:YES attributes:nil error:NULL];
}

static void os_init_logging() {
    int fd = open(os_log_file, O_WRONLY | O_CREAT | O_TRUNC, 0664);
    dup2(fd, 2);
    close(fd);
}

void os_init() {
    os_compute_paths();
    os_init_logging();
}
