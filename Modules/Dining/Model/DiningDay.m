#import "DiningDay.h"
#import "HouseVenue.h"
#import "DiningMeal.h"
#import "CoreDataManager.h"

@implementation DiningDay

@dynamic date;
@dynamic message;
@dynamic meals;
@dynamic houseVenue;

+ (DiningDay *)newDayWithDictionary:(NSDictionary *)dict {
    DiningDay *day = [CoreDataManager insertNewObjectForEntityForName:@"DiningDay"];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/New_York"]];
    NSDate *date = [formatter dateFromString:dict[@"date"]];
    day.date = date;
    
    if (dict[@"message"]) {
        day.message = dict[@"message"];
    }
    
    for (NSDictionary *mealDict in dict[@"meals"]) {
        DiningMeal *meal = [DiningMeal newMealWithDictionary:mealDict];
        [day addMealsObject:meal];
        
        // adjust all of the start and end times to be complete dates and times to make querying easier
        
        if (meal.startTime && meal.endTime) {
            NSDate *dayDate = day.date;
            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSDateComponents *dayComponents = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:dayDate];
            NSDateComponents *timeComponents = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:meal.startTime];
            timeComponents.year = dayComponents.year;
            timeComponents.month = dayComponents.month;
            timeComponents.day = dayComponents.day;

            meal.startTime = [calendar dateFromComponents:timeComponents];

            timeComponents = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:meal.endTime];
            timeComponents.year = dayComponents.year;
            timeComponents.month = dayComponents.month;
            timeComponents.day = dayComponents.day;
            
            meal.endTime = [calendar dateFromComponents:timeComponents];

//            NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:meal.startTime toDate:dayDate options:0];
//            components.day += 1;
//            meal.startTime = [calendar dateByAddingComponents:components toDate:meal.startTime options:0];
//            components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit) fromDate:meal.endTime toDate:dayDate options:0];
//            components.day += 1;
//            meal.endTime = [calendar dateByAddingComponents:components toDate:meal.endTime options:0];
//            
//            NSLog(@"%@ %@ %@", dayDate, meal.startTime, meal.endTime);

        }
    }
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:YES];
    NSArray *sortedMeals = [[day.meals array] sortedArrayUsingDescriptors:@[sort]];
    [day setMeals:[NSOrderedSet orderedSetWithArray:sortedMeals]];
    
    return day;
}

+ (DiningDay *)dayForDate:(NSDate *) date forVenue:(HouseVenue *)venue
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date == %@ && houseVenue == %@", date, venue];
    NSArray * array = [CoreDataManager objectsForEntity:@"DiningDay" matchingPredicate:predicate];
    
    return [array lastObject];
}

// There appears to be a bug in Apple's autogenerated NSOrderedSet accessors: http://stackoverflow.com/questions/7385439/exception-thrown-in-nsorderedset-generated-accessors
- (void)addMealsObject:(DiningMeal *)value {
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.meals];
    [tempSet addObject:value];
    self.meals = tempSet;
}

- (NSString *)allHoursSummary {
    NSMutableArray *summaries = [NSMutableArray array];
    for (DiningMeal *meal in self.meals) {
        NSString *summary = [meal hoursSummary];
        if (summary) {
            [summaries addObject:summary];
        }
    }
    return [summaries componentsJoinedByString:@", "];
}

- (DiningMeal *)mealWithName:(NSString *)name
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
    return [[[self.meals set] filteredSetUsingPredicate:predicate] anyObject];
}

- (DiningMeal *)mealForDate:(NSDate *)date {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"startTime <= %@ AND endTime >= %@", date, date];
    
    return [[[self.meals set] filteredSetUsingPredicate:predicate] anyObject];
}

- (DiningMeal *)bestMealForDate:(NSDate *)date {
    
    // get current meal if one is occurring now
    DiningMeal *meal = [self mealForDate:date];
    
    if (!meal) {
        // get next meal to begin
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"startTime >= %@", date];
        // array keeps order intact, could also use sortdescriptor
        NSArray *meals = [[self.meals array] filteredArrayUsingPredicate:predicate];
        if ([meals count]) {
            meal = meals[0];
        }
    }
    
    if (!meal) {
        // get last meal of the day
        meal = [self.meals lastObject];
    }
    
    return meal;
}


@end