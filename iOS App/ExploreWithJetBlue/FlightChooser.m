//
//  FlightChooser.m
//  ExploreWithJetBlue
//
//  Created by Toby on 2017-12-02.
//  Copyright © 2017 YHACK17. All rights reserved.
//

#import "FlightChooser.h"

@interface FlightChooser ()

@end

@implementation FlightChooser

- (void)viewDidLoad {
    UISwipeGestureRecognizer *rightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(rightSwipeHandle:)];
    rightRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [rightRecognizer setNumberOfTouchesRequired:1];
    
    //add the your gestureRecognizer , where to detect the touch..
    [self.view addGestureRecognizer:rightRecognizer];

    
    UISwipeGestureRecognizer *leftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leftSwipeHandle:)];
    leftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [leftRecognizer setNumberOfTouchesRequired:1];
    
    [self.view  addGestureRecognizer:leftRecognizer];
  
    
    [super viewDidLoad];
    [self setUpInitial];
    
    NSMutableArray * labelsLight;
    keywordsArray = [[NSMutableArray alloc]init];
    
    NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
    NSData *savedArray = [currentDefaults objectForKey:@"labels"];
    if (savedArray != nil)
    {
        NSArray *oldArray = [NSKeyedUnarchiver unarchiveObjectWithData:savedArray];
        if (oldArray != nil) {
            labelsLight = [[NSMutableArray alloc] initWithArray:oldArray];
        } else {
            labelsLight = [[NSMutableArray alloc] init];
        }
    }
    
    for (int i = 0; i < [labelsLight count]; i++){
        [keywordsArray addObject:[labelsLight objectAtIndex:i]];
         if (i == 5){
             break;
         }
    }
    NSLog(@"%@",keywordsArray);
    
    NSString * landmarkName = [[NSUserDefaults standardUserDefaults]
                            stringForKey:@"landmarkName"];
    NSString * landmarkLong = [[NSUserDefaults standardUserDefaults]
                               stringForKey:@"landmarkLong"];
    NSString * landmarkLat = [[NSUserDefaults standardUserDefaults]
                              stringForKey:@"landmarkLat"];
    
    
    if (![landmarkName isEqualToString:@"nil"]){
        originalLandmark.text = landmarkName;
    }
    
    ///MAKE KEYWORDS STRING
    for (int i = 0; i < [keywordsArray count]; i ++){
        NSString * temp = [keywordsArray objectAtIndex:i];
        NSString* k = @"'";
     
        NSString* temp1 = [k stringByAppendingString:temp];
        NSString* temp2 = [temp1 stringByAppendingString:k]; // Prints "BA"
        
        [keywordsArray replaceObjectAtIndex:i withObject:temp2];
        
    }
    NSString * keywordsSquareFormat = [keywordsArray componentsJoinedByString:@","];
    NSString* a = @"[";
    NSString* b = @"]";
    NSString* keywordsSquareFormat1 = [a stringByAppendingString:keywordsSquareFormat];
    NSString* keywordsSquareFormat2 = [keywordsSquareFormat1 stringByAppendingString:b]; // Prints "BA"
    
    
    ///////////////////////////////////////////////////////////////////
    NSString *urlString = @"http://2835db01.ngrok.io/getFlights";
    NSString *requestString = [NSString stringWithFormat:@"%@", urlString];
    
    NSURL *url = [NSURL URLWithString: requestString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod: @"POST"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    // Build model JSON
    NSString *e1 = @"origLong";
    NSString *e2 = @"origLat";
    NSString *e3 = @"destLong";
    NSString *e4 = @"destLat";
    NSString *e5 = @"departureDate";
    NSString *e6 = @"keywords";
    
    NSDictionary *paramsDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    @"-73", e1, @"40", e2, landmarkLong, e3,landmarkLat, e4, @"12/3/2017", e5, keywordsSquareFormat2, e6, nil];
    
    if (![landmarkLat isEqualToString:@"-1"] && ![landmarkLong isEqualToString:@"-1"]){
        paramsDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            @"-73", e1, @"40", e2, landmarkLong, e3,landmarkLat, e4, @"12/3/2017", e5, @"[]", e6, nil];
    }
    
    NSLog(@"%@",paramsDictionary);
    
    NSError *error;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:paramsDictionary options:0 error:&error];
    
    //NSLog(@"%@",requestData);
    [request setHTTPBody: requestData];
    
    // Run the request on a background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self runRequestOnBackgroundThread: request];
    });
}
- (void)runRequestOnBackgroundThread: (NSMutableURLRequest*) request {
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^ (NSData *data, NSURLResponse *response, NSError *error) {
        [self analyzeResults:data];
    }];
    [task resume];
}
int count = 0;
NSMutableArray *dates;
NSMutableArray *destAirports;
NSMutableArray *destCities;
NSMutableArray *destCountries;
NSMutableArray *fares;
NSMutableArray *reasons;
- (void)analyzeResults: (NSData*)dataToParse {
    
    // Update UI on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        
        destAirports = [[NSMutableArray alloc] init];
        destCountries = [[NSMutableArray alloc] init];
        fares = [[NSMutableArray alloc] init];
        reasons = [[NSMutableArray alloc] init];
        destCities = [[NSMutableArray alloc]init];
        dates = [[NSMutableArray alloc]init];
        
        NSError *e = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:dataToParse options:kNilOptions error:&e];
        NSDictionary *data = [json objectForKey:@"data"];
        NSLog(@"Response is: %@",data);
        
        count = 0;
        NSDictionary *flights = [data objectForKey:@"flights"];
        for (NSDictionary *flight in flights) {
            count++;
            NSString *city = [flight objectForKey:@"destCity"];
            
            NSLog(@"LANDMARK FOUND");
            
            if (count == 1){
                [dest1 setTitle:city forState:UIControlStateNormal];
                dest1.enabled = YES;
            }
            if (count == 2){
                [dest2 setTitle:city forState:UIControlStateNormal];
                dest2.enabled = YES;
            }
            if (count == 3){
                [dest3 setTitle:city forState:UIControlStateNormal];
                dest3.enabled = YES;
            }
            if (count == 4){
                [dest4 setTitle:city forState:UIControlStateNormal];
                dest4.enabled = YES;
            }
            dest1.enabled = YES;
            dest2.enabled = YES;
            dest3.enabled = YES;
            dest4.enabled = YES;
            
            //Storing info for info view
            NSString *destAirport = [flight objectForKey:@"destAirport"];
            NSString *destCountry = [flight objectForKey:@"destCountry"];
            NSString *destCity = [flight objectForKey:@"destCity"];
            NSString *fare = [flight objectForKey:@"fare"];
            NSString *reason = [flight objectForKey:@"reasons"];
            NSString *date = [flight objectForKey:@"departureDate"];
            
            [destAirports addObject:destAirport];
            [destCountries addObject:destCountry];
            [destCities addObject:destCity];
            [fares addObject:fare];
            [reasons addObject:reason];
            [dates addObject:date];
            
            
            
        }
        dataLoaded = YES;
    
        
        
        
        
    });
    
}


CGFloat screenWidth0;
CGFloat screenHeight0;

bool dataLoaded;
int animateState = 0;
bool isOpen;
-(void)setUpInitial{
    dataLoaded = NO;
    isOpen = NO;
    count = 0;
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    screenWidth0 = screenSize.width;
    screenHeight0 = screenSize.height;
    
    
    NSData* imageData = [[NSUserDefaults standardUserDefaults] objectForKey:@"imager"];
    UIImage* image1 = [UIImage imageWithData:imageData];
    originalImage.image = image1;
    originalLandmark.text = @"Similar places to visit:";
    
    originalImage.frame = CGRectMake(0, 0, screenWidth0, screenWidth0);
    originalImage.center = CGPointMake(screenWidth0/2, screenHeight0/8);
    originalLandmark.center = CGPointMake(screenWidth0/2, originalImage.center.y+screenWidth0/2+50);
    
    dest1.frame = CGRectMake(0, 0, screenWidth0/2, screenWidth0/2);
    dest2.frame = CGRectMake(0, 0, screenWidth0/2, screenWidth0/2);
    dest3.frame = CGRectMake(0, 0, screenWidth0/2, screenWidth0/2);
    dest4.frame = CGRectMake(0, 0, screenWidth0/2, screenWidth0/2);
    
    dest1.center = CGPointMake(screenWidth0/4, screenHeight0-3*screenWidth0/4-64);
    dest2.center = CGPointMake(screenWidth0/4+screenWidth0/2, screenHeight0-3*screenWidth0/4-64);
    dest3.center = CGPointMake(screenWidth0/4, screenHeight0-screenWidth0/4-64);
    dest4.center = CGPointMake(screenWidth0/4+screenWidth0/2, screenHeight0-screenWidth0/4-64);
    
    dest1.enabled = NO;
    dest2.enabled = NO;
    dest3.enabled = NO;
    dest4.enabled = NO;
    
    blueSkyLoad.frame = CGRectMake(0, 0, screenWidth0, screenWidth0);
    blueSkyLoad.center = CGPointMake(screenWidth0/2, screenHeight0-screenWidth0/2-64);
    loadingMessage.center = CGPointMake(screenWidth0/2, screenHeight0-screenWidth0/2-64);
    
    coreGraphics0 = [NSTimer scheduledTimerWithTimeInterval:0.005
                                                    target:self
                                                  selector:@selector(corehelper)
                                                  userInfo:nil
                                                   repeats:YES];
    
    //self.imgView.image = image;
}
#pragma coreAnimation and Slider with Button Actions
-(void)corehelper{
    int speed = 8;
    globalcount++; 
    if (animateState == 0){
        
        dest1.enabled = YES;
        dest2.enabled = YES;
        dest3.enabled = YES;
        dest4.enabled = YES;
        
        
    }
    else if (animateState == 1){
        dest1.enabled = NO;
        dest2.enabled = NO;
        dest3.enabled = NO;
        dest4.enabled = NO;
        
        if (dest1.center.x > -screenWidth0/8){
            dest1.center = CGPointMake(dest1.center.x-speed, dest1.center.y);
            dest2.center = CGPointMake(dest2.center.x+speed, dest2.center.y);
            dest3.center = CGPointMake(dest3.center.x-speed, dest3.center.y);
            dest4.center = CGPointMake(dest4.center.x+speed, dest4.center.y);
        }
        else{
            animateState = 0;
            isOpen = YES;
        }
        
        
    }
    else if (animateState == -1){
        dest1.enabled = NO;
        dest2.enabled = NO;
        dest3.enabled = NO;
        dest4.enabled = NO;
        
        if (dest1.center.x < screenWidth0/4){
            dest1.center = CGPointMake(dest1.center.x+speed, dest1.center.y);
            dest2.center = CGPointMake(dest2.center.x-speed, dest2.center.y);
            dest3.center = CGPointMake(dest3.center.x+speed, dest3.center.y);
            dest4.center = CGPointMake(dest4.center.x-speed, dest4.center.y);
        }
        else{
            animateState = 0;
            isOpen = NO;
            dest1.center = CGPointMake(screenWidth0/4, screenHeight0-3*screenWidth0/4-64);
            dest2.center = CGPointMake(screenWidth0/4+screenWidth0/2, screenHeight0-3*screenWidth0/4-64);
            dest3.center = CGPointMake(screenWidth0/4, screenHeight0-screenWidth0/4-64);
            dest4.center = CGPointMake(screenWidth0/4+screenWidth0/2, screenHeight0-screenWidth0/4-64);
        }
    }
    if (dataLoaded != YES){
        blueSkyLoad.hidden = NO;
        loadingMessage.hidden = NO;
        if (globalcount%300 == 0){
         
            loadingMessage.text = @"finding best valued flights";
        }
        if (globalcount%300 == 100){
            loadingMessage.text = @"finding best valued flights.";
        }
        if (globalcount%300 == 200){
            loadingMessage.text = @"finding best valued flights..";
        }
    }
    else{
        blueSkyLoad.hidden = YES;
        loadingMessage.hidden = YES;
    }
}

- (IBAction)b1:(id)sender {
    if (count >= 1 && !isOpen){
    NSString * country = [destCountries objectAtIndex:0];
    NSString * city = [destCities objectAtIndex:0];
    NSString * format = [NSString stringWithFormat:@", "];
    
    NSString * title = [city stringByAppendingString:format];
    NSString * titleFinal = [title stringByAppendingString:country];
    
    destinationName.text = titleFinal;
    destinationAirport.text = [destAirports objectAtIndex:0];
        flightTime.text = [dates objectAtIndex:0];
    
    NSString * priceRaw = [fares objectAtIndex:0];
    NSString * dollar = [NSString stringWithFormat:@"$"];
    price.text = [dollar stringByAppendingString:priceRaw];
        
    description.text = [reasons objectAtIndex:0];
        NSLog(@"1");
    }
    [self animationHelper];
}
- (IBAction)b2:(id)sender {
    if (count >= 2 && !isOpen){
    NSString * country = [destCountries objectAtIndex:1];
    NSString * city = [destCities objectAtIndex:1];
    NSString * format = [NSString stringWithFormat:@", "];
    
    NSString * title = [city stringByAppendingString:format];
    NSString * titleFinal = [title stringByAppendingString:country];
    
    destinationName.text = titleFinal;
    destinationAirport.text = [destAirports objectAtIndex:1];
        flightTime.text = [dates objectAtIndex:1];
        
        NSString * priceRaw = [fares objectAtIndex:1];
        NSString * dollar = [NSString stringWithFormat:@"$"];
        price.text = [dollar stringByAppendingString:priceRaw];
    description.text = [reasons objectAtIndex:1];
        NSLog(@"2");
    }
    [self animationHelper];
}
- (IBAction)b3:(id)sender {
    if (count >= 3 && !isOpen){
    NSString * country = [destCountries objectAtIndex:2];
    NSString * city = [destCities objectAtIndex:2];
    NSString * format = [NSString stringWithFormat:@", "];
    
    NSString * title = [city stringByAppendingString:format];
    NSString * titleFinal = [title stringByAppendingString:country];
    
    destinationName.text = titleFinal;
    destinationAirport.text = [destAirports objectAtIndex:2];
        flightTime.text = [dates objectAtIndex:2];
    
        NSString * priceRaw = [fares objectAtIndex:2];
        NSString * dollar = [NSString stringWithFormat:@"$"];
        price.text = [dollar stringByAppendingString:priceRaw];
    description.text = [reasons objectAtIndex:2];
        NSLog(@"3");
    }
    [self animationHelper];
}
- (IBAction)b4:(id)sender {
    if (count >= 4 && !isOpen){
    NSString * country = [destCountries objectAtIndex:3];
    NSString * city = [destCities objectAtIndex:3];
    NSString * format = [NSString stringWithFormat:@", "];
    
    NSString * title = [city stringByAppendingString:format];
    NSString * titleFinal = [title stringByAppendingString:country];
    
    destinationName.text = titleFinal;
    destinationAirport.text = [destAirports objectAtIndex:3];
        flightTime.text = [dates objectAtIndex:3];
    
        NSString * priceRaw = [fares objectAtIndex:3];
        NSString * dollar = [NSString stringWithFormat:@"$"];
        price.text = [dollar stringByAppendingString:priceRaw];
    description.text = [reasons objectAtIndex:3];
        NSLog(@"4");
    }
    [self animationHelper];
}
-(void)animationHelper{
    
    if (isOpen == YES){
        animateState = -1;
    }
    if (isOpen == NO){
        animateState = 1;
    }
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)rightSwipeHandle:(UISwipeGestureRecognizer*)gestureRecognizer
{
    NSLog(@"rightSwipeHandle");
    if (isOpen == YES){
        animateState = -1;
    }
}

- (void)leftSwipeHandle:(UISwipeGestureRecognizer*)gestureRecognizer
{
    NSLog(@"leftSwipeHandle");
    if (isOpen && dataLoaded){
        animateState = -1;
    }
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
int globalcount;
- (IBAction)restart:(id)sender {
    [coreGraphics0 invalidate];
    coreGraphics0 = nil;
}
- (IBAction)booknow:(id)sender {
     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.jetblue.com/deals/"]];
}

@end
