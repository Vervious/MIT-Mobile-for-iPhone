#import "DiningData.h"

#import "DiningRoot.h"
#import "HouseVenue.h"
#import "RetailVenue.h"
#import "DiningDietaryFlag.h"
#import "CoreDataManager.h"
#import "MITMobileServerConfiguration.h"
#import "ConnectionDetector.h"
#import "ModuleVersions.h"
#import "MobileRequestOperation.h"
#import "JSON.h"

@implementation DiningData

+ (DiningData *)sharedData {
    static DiningData *_sharedData = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _sharedData = [[self alloc] init];
    });
    
    return _sharedData;
}

- (NSString *)announcementsHTML {
    // There should only be one DiningRoot
    NSArray *roots = [CoreDataManager objectsForEntity:@"DiningRoot" matchingPredicate:nil];
    DiningRoot *root = [roots lastObject];
    return root.announcementsHTML;
}

- (NSArray *)links {
    NSArray *links = [CoreDataManager objectsForEntity:@"DiningLink" matchingPredicate:nil sortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"ordinality" ascending:YES]]];
    return links;
}

// TODO: This should be rewritten to not lose favorited venues every time you reload
- (void)reload {
    // Fetch data
    NSDictionary *latestDataDict = [self fetchData];
    
    if (latestDataDict) {
        // Make sure the set list of dietary flags already exist before we start parsing.
        [DiningDietaryFlag createDietaryFlagsInStore];

        // TODO
        // Find already favorited venues
        NSArray *favoritedVenues = [CoreDataManager objectsForEntity:@"RetailVenue"
                                                   matchingPredicate:[NSPredicate predicateWithFormat:@"favorite == YES"]];
        // Make list of old entities to delete
        NSArray *oldRoot = [CoreDataManager fetchDataForAttribute:@"DiningRoot"];
        // Delete old things
        [CoreDataManager deleteObjects:oldRoot];
        // Create new entities in Core Data
        [DiningRoot newRootWithDictionary:latestDataDict];
        // Save
        [CoreDataManager saveData];
    }
}

- (NSDictionary *)fetchData {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"dining-sample" ofType:@"json" inDirectory:@"dining"];
    NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
    NSError *error = nil;
    NSDictionary *parsedData = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
    if (error) {
        NSLog(@"Houston we have a problem. Sample Data not initialized from local file.");
        return nil;
    } else {
        return parsedData;
    }
}

//- (void)loadDebugData {
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"dining-sample" ofType:@"json" inDirectory:@"dining"];
//    NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
//    NSError *error = nil;
//    id sampleData = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
//    if (error) {
//        NSLog(@"Houston we have a problem. Sample Data not initialized from local file.");
//    } else {
//        [CoreDataManager clearDataForAttribute:@"HouseVenue"];
//        [CoreDataManager clearDataForAttribute:@"RetailVenue"];
//        [CoreDataManager saveData];
//        [self importData:sampleData];
//        [CoreDataManager saveData];
//    }
//}

//- (void)importData:(NSDictionary *)parsedJSON {
//    if ([parsedJSON respondsToSelector:@selector(objectForKey:)]) {
//        NSMutableArray *venues = [NSMutableArray array];
//        for (NSDictionary *venueDict in parsedJSON[@"venues"][@"house"]) {
//            [venues addObject:[HouseVenue newVenueWithDictionary:venueDict]];
//        }
//        venues = [NSMutableArray array];
//        for (NSDictionary *venueDict in parsedJSON[@"venues"][@"retail"]) {
//            [venues addObject:[RetailVenue newVenueWithDictionary:venueDict]];
//        }
//    } else {
//        DDLogError(@"Dining JSON is not a dictionary.");
//    }
//}

@end
