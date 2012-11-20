#import "NMITMapView.h"
#import "MGSMapCoordinate.h"
#import "MGSMapView.h"
#import "MGSMapLayer.h"
#import "MGSMapAnnotation.h"

@interface NMITMapView ()
@property (nonatomic, weak) MGSMapView *mapView;
@property (nonatomic, strong) MGSMapLayer *annotationLayer;
@property (nonatomic, strong) MGSMapLayer *routeLayer;

- (void)initLayers;
@end

@implementation NMITMapView
@dynamic centerCoordinate;
@dynamic region;
@dynamic scrollEnabled;
@dynamic showsUserLocation;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        MGSMapView *mapView = [[MGSMapView alloc] initWithFrame:frame];
        self.mapView = mapView;
        [self addSubview:mapView];
        
        self.annotationLayer = [[MGSMapLayer alloc] init];
        [self.mapView addLayer:self.annotationLayer
                withIdentifier:@"edu.mit.mobile.map.annotations"];
        
        self.routeLayer = [[MGSMapLayer alloc] init];
        [self.mapView addLayer:self.routeLayer
                withIdentifier:@"edu.mit.mobile.map.routes"];
    }
    
    return self;
}

#pragma mark - Dynamic Properties
- (void)setCenterCoordinate:(CLLocationCoordinate2D)coord
{
    [self setCenterCoordinate:coord
                     animated:NO];
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)coord animated:(BOOL)animated
{
    MGSMapCoordinate *coordinate = [[MGSMapCoordinate alloc] initWithLocation:coord];
    [self.mapView centerAtCoordinate:coordinate
                            animated:animated];
}

- (MKCoordinateRegion)region
{
    return self.mapView.mapRegion;
}

- (void)setRegion:(MKCoordinateRegion)region
{
    self.mapView.mapRegion = region;
}

- (BOOL)scrollEnabled
{
    // Always NO
    // Zoom & Pan disable not currently supported by ArcGIS SDK
    return NO;
}

- (void)setScrollEnabled:(BOOL)scrollEnabled
{
    // NOP
    // Zoom & Pan disable not currently supported by ArcGIS SDK
}

- (BOOL)showsUserLocation
{
    return self.mapView.showUserLocation;
}

- (void)setShowsUserLocation:(BOOL)showsUserLocation
{
    self.mapView.showUserLocation = showsUserLocation;
}


#pragma mark - MKMapView Forwarding Stubs
- (CGPoint)convertCoordinate:(CLLocationCoordinate2D)coordinate toPointToView:(UIView *)view
{
    MGSMapCoordinate *coord = [[MGSMapCoordinate alloc] initWithLocation:coordinate];
    CGPoint screenPoint = [self.mapView screenPointForCoordinate:coord];
    
    return [view convertPoint:screenPoint
                     fromView:nil];
}

#pragma mark - MITMapView Annotation Handling
- (void)selectAnnotation:(id<MKAnnotation>)annotation
{
    [self selectAnnotation:annotation
                  animated:NO
              withRecenter:YES];
}

- (void)selectAnnotation:(id<MKAnnotation>)annotation
                animated:(BOOL)animated
            withRecenter:(BOOL)recenter
{
    __block MGSMapAnnotation *mapAnnotation = nil;
    
    [self.annotationLayer.annotations enumerateObjectsUsingBlock:^(MGSMapAnnotation *obj, NSUInteger idx, BOOL *stop) {
        if ([obj.userData isEqual:annotation])
        {
            mapAnnotation = obj;
            (*stop) = YES;
        }
    }];
    
    if (mapAnnotation)
    {
        if (recenter)
        {
            [self.mapView centerOnAnnotation:mapAnnotation];
        }
        
        [self.mapView showCalloutForAnnotation:mapAnnotation];
    }
}

- (void)deselectAnnotation:(id<MKAnnotation>)annotation
                  animated:(BOOL)animated
{
    [self.mapView hideCallout];
}

- (void)addAnnotation:(id<MKAnnotation>)anAnnotation
{
    [self addAnnotations:@[anAnnotation]];
}

- (void)addAnnotations:(NSArray *)annotations
{
    NSMutableArray *currentAnnotations = [NSMutableArray arrayWithArray:annotations];
    for (MGSMapAnnotation *annotation in self.annotationLayer.annotations)
    {
        if ([currentAnnotations containsObject:annotation.userData])
        {
            [currentAnnotations removeObject:annotation.userData];
        }
    }
    
    for (id<MKAnnotation> annotation in currentAnnotations)
    {
        MGSMapCoordinate *coord = [[MGSMapCoordinate alloc] initWithLocation:[annotation coordinate]];
        MGSMapAnnotation *mapAnnotation = [[MGSMapAnnotation alloc] initWithTitle:[annotation title]
                                                                       detailText:[annotation subtitle]
                                                                     atCoordinate:coord];
        [self.annotationLayer addAnnotation:mapAnnotation];
    }
}

- (void)removeAnnotation:(id<MKAnnotation>)annotation
{
    [self removeAnnotations:@[annotation]];
}

- (void)removeAnnotations:(NSArray *)annotations
{
    for (MGSMapAnnotation *annotation in self.annotationLayer.annotations)
    {
        if ([annotations containsObject:annotation.userData])
        {
            [self.annotationLayer deleteAnnotation:annotation];
        }
    }
}

- (void)removeAllAnnotations:(BOOL)includeUserLocation
{
    [self.annotationLayer deleteAllAnnotations];
}
@end