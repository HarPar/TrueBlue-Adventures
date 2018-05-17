//
//  ViewController.m
//  ExploreWithJetBlue
//
//  Created by Toby on 2017-12-01.
//  Copyright © 2017 YHACK17. All rights reserved.
//

#import "ViewController.h"
#import "FlightChooser.h"

@interface ViewController ()

@end

@implementation ViewController

chooseM = 1;
- (IBAction)loadImageButtonTapped:(UIButton *)sender {
    fullchoose = YES;
}
- (IBAction)takeImageButtonTapped:(UIButton *)sender {
    fullphoto = YES;
}

- (void)imagePickerController:(UIImagePickerController *)imagePicker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *pickedImage = info[UIImagePickerControllerOriginalImage];
    //self.imageView.contentMode = UIViewContentModeScaleAspectFit;

    //[self.spinner startAnimating];
    [chooseButton setTitle:@"processing image" forState:UIControlStateNormal];
    [cameraButton setTitle:@"processing image" forState:UIControlStateNormal];
    
    // Base64 encode the image and create the request
    NSString *binaryImageData = [self base64EncodeImage:pickedImage];
    [self createRequest:binaryImageData];
    [imagePicker dismissViewControllerAnimated:true completion:NULL];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)imagePicker {
    [imagePicker dismissViewControllerAnimated:true completion:NULL];
    [self animationsReset];
}


- (UIImage *) resizeImage: (UIImage*) image toSize: (CGSize)newSize {
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (NSString *) base64EncodeImage: (UIImage*)image {
    NSData *imagedata = UIImagePNGRepresentation(image);
    
    // Resize the image if it exceeds the 2MB API limit
    if ([imagedata length] > 2097152) {
        CGSize oldSize = [image size];
        CGSize newSize = CGSizeMake(800, oldSize.height / oldSize.width * 800);
        image = [self resizeImage: image toSize: newSize];
        imagedata = UIImagePNGRepresentation(image);
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:UIImagePNGRepresentation(image) forKey:@"imager"];
    NSString *base64String = [imagedata base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
   
    
    return base64String;
}

- (void) createRequest: (NSString*)imageData {
    // Create our request URL
    loading = YES;
    NSString *urlString = @"https://vision.googleapis.com/v1/images:annotate?key=";
    NSString *API_KEY = @"AIzaSyCXsC4aikaOA5a6J2YhQ2YtkFbTg1zh26I";
    
    NSString *requestString = [NSString stringWithFormat:@"%@%@", urlString, API_KEY];
    
    NSURL *url = [NSURL URLWithString: requestString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod: @"POST"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request
     addValue:[[NSBundle mainBundle] bundleIdentifier]
     forHTTPHeaderField:@"X-Ios-Bundle-Identifier"];
    
    // Build our API request
    NSDictionary *paramsDictionary =
    @{@"requests":@[
              @{@"image":
                    @{@"content":imageData},
                @"features":@[
                        
                        @{@"type":@"LANDMARK_DETECTION",
                          @"maxResults":@1},
                        
                        @{@"type":@"LABEL_DETECTION",
                          @"maxResults":@5}]}]};
    
    NSError *error;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:paramsDictionary options:0 error:&error];
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

NSMutableArray *labels;
NSMutableArray *landmarks;
NSMutableArray *landmarksLocationsLat;
NSMutableArray *landmarksLocationsLong;
- (void)analyzeResults: (NSData*)dataToParse {
    
    // Update UI on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSError *e = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:dataToParse options:kNilOptions error:&e];
        
        NSArray *responses = [json objectForKey:@"responses"];
        NSLog(@"%@", responses);
        NSDictionary *responseData = [responses objectAtIndex: 0];
        NSDictionary *errorObj = [json objectForKey:@"error"];
        
        [self.spinner stopAnimating];
        loading = NO;
        
      
        
        // Check for errors
        if (errorObj) {
            NSString *errorString1 = @"Error code ";
            NSString *errorCode = [errorObj[@"code"] stringValue];
            NSString *errorString2 = @": ";
            NSString *errorMsg = errorObj[@"message"];

        } else {
            
            // Get face annotations
            NSDictionary *faceAnnotations = [responseData objectForKey:@"faceAnnotations"];
            if (faceAnnotations != NULL) {
                // Get number of faces detected
                NSInteger numPeopleDetected = [faceAnnotations count];
                NSString *peopleStr = [NSString stringWithFormat:@"%lu", (unsigned long)numPeopleDetected];
                NSString *faceStr1 = @"People detected: ";
                NSString *faceStr2 = @"\n\nEmotions detected:\n";
       
                
                NSArray *emotions = @[@"joy", @"sorrow", @"surprise", @"anger"];
                NSMutableDictionary *emotionTotals = [NSMutableDictionary dictionaryWithObjects:@[@0.0,@0.0,@0.0,@0.0]forKeys:@[@"sorrow",@"joy",@"surprise",@"anger"]];
                NSDictionary *emotionLikelihoods = @{@"VERY_LIKELY": @0.9, @"LIKELY": @0.75, @"POSSIBLE": @0.5, @"UNLIKELY": @0.25, @"VERY_UNLIKELY": @0.0};
                
                // Sum all detected emotions
                for (NSDictionary *personData in faceAnnotations) {
                    for (NSString *emotion in emotions) {
                        NSString *lookup = [emotion stringByAppendingString:@"Likelihood"];
                        NSString *result = [personData objectForKey:lookup];
                        double newValue = [emotionLikelihoods[result] doubleValue] + [emotionTotals[emotion] doubleValue];
                        NSNumber *tempNumber = [[NSNumber alloc] initWithDouble:newValue];
                        [emotionTotals setValue:tempNumber forKey:emotion];
                    }
                }
                
                // Get emotion likelihood as a % and display it in the UI
                for (NSString *emotion in emotionTotals) {
                    double emotionSum = [emotionTotals[emotion] doubleValue];
                    double totalPeople = [faceAnnotations count];
                    double likelihoodPercent = emotionSum / totalPeople;
                    NSString *percentString = [[NSString alloc] initWithFormat:@"%2.0f%%",(likelihoodPercent*100)];
                    NSString *emotionPercentString = [NSString stringWithFormat:@"%@%@%@%@", emotion, @": ", percentString, @"\r\n"];
                    
                }
            } else {
        
            }
            //LANDMARK
            NSDictionary *landmarkAnnotations = [responseData objectForKey:@"landmarkAnnotations"];
            NSInteger numLandmarks = [landmarkAnnotations count];
            
            landmarks = [[NSMutableArray alloc] init];
            landmarksLocationsLat = [[NSMutableArray alloc] init];
            landmarksLocationsLong = [[NSMutableArray alloc] init];
            
            if (numLandmarks > 0) {
                NSString * labelResultsText = @"Landmarks found: ";
                
                NSArray * testLatArray = [responseData valueForKeyPath:@"landmarkAnnotations.locations.latLng.latitude"];
                NSArray * testLongArray = [responseData valueForKeyPath:@"landmarkAnnotations.locations.latLng.longitude"];
                
                
                
                ///////////////////
                NSString * latString = [testLatArray componentsJoinedByString: @""];
                NSString * longString = [testLongArray componentsJoinedByString: @""];
                
                NSString *latStringFinal = [latString substringWithRange:NSMakeRange(7, 8)];
                NSString *longStringFinal = [longString substringWithRange:NSMakeRange(7, 8)];
                
                
                //NSString * testLat = [NSString stringWithFormat:@"%f", realLat];
                //NSString * testLong = [NSString stringWithFormat:@"%f",realLong];
                ///////////////////
                
                for (NSDictionary *landmark in landmarkAnnotations) {
                    
                    NSString *landmarkString = [landmark objectForKey:@"description"];
                    NSLog(@"LANDMARK FOUND");
                    /*
                    
                    NSString *landmarkLocation = [landmark objectForKey:@"locations.latLng.latitude"];
                    NSLog(@"%@",landmarkLocation);
                    */
                    [landmarks addObject:landmarkString];
                    [landmarksLocationsLat addObject:latStringFinal];
                    [landmarksLocationsLong addObject:longStringFinal];
                }
                
                
            }
            
            
            // Get label annotations
            NSDictionary *labelAnnotations = [responseData objectForKey:@"labelAnnotations"];
            NSInteger numLabels = [labelAnnotations count];
            labels = [[NSMutableArray alloc] init];
            if (numLabels > 0) {
                NSString *labelResultsText = @"Labels found: ";
                for (NSDictionary *label in labelAnnotations) {
                    NSString *labelString = [label objectForKey:@"description"];
                    [labels addObject:labelString];
                }
                for (NSString *label in labels) {
                    // if it's not the last item add a comma
                    if (labels[labels.count - 1] != label) {
                        NSString *commaString = [label stringByAppendingString:@", "];
                        labelResultsText = [labelResultsText stringByAppendingString:commaString];
                    } else {
                        labelResultsText = [labelResultsText stringByAppendingString:label];
                    }
                }
               
            } else {
             
            }
            
            if (1 == 1){
                NSString * landmarkName = @"nil";
                NSString * landmarkLong = @"-1";
                NSString * landmarkLat = @"-1";
                if ([landmarks count] > 0){
                    landmarkName = [landmarks objectAtIndex:0];
                    ///GET Long and Lat
                    /*
                    NSString * landmarkLocation = [landmarksLocations objectAtIndex:0];
                    NSLog(@"%@",landmarkLocation);
                    for (int i = 0; i < [landmarkLocation length]; i ++){
                        unichar * single = [landmarkLocation characterAtIndex:i];
                        
                        if ([single isEqualToString:@"\"%@\""]){
                            
                        }
                        
                    }
                     */
                    
                    landmarkLong = [landmarksLocationsLong objectAtIndex:0];
                    landmarkLat = [landmarksLocationsLat objectAtIndex:0];
                }
                
                [[NSUserDefaults standardUserDefaults] setObject:landmarkName forKey:@"landmarkName"];
                [[NSUserDefaults standardUserDefaults] setObject:landmarkLong forKey:@"landmarkLong"];
                [[NSUserDefaults standardUserDefaults] setObject:landmarkLat forKey:@"landmarkLat"];
               
                
                [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:labels] forKey:@"labels"];
                [[NSUserDefaults standardUserDefaults] synchronize];

                [coreGraphics invalidate];
                coreGraphics = nil;
                
                NSString * storyboardName = @"Main";
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
                UIViewController * vc = [storyboard instantiateViewControllerWithIdentifier:@"flightC"];
                [self presentViewController:vc animated:YES completion:nil];
            }
        }
    });
    
}


#pragma animations on Load, animationsDidLoad, animationsReset
-(void)corehelper{
    [self fullChooseLoad];
    [self fullCoverPhoto];
    [self flyLoader];
}
-(void)flyLoader{
    if (loading){
        plane.hidden = NO;
        plane.center = CGPointMake(plane.center.x+planeX*1.25,plane.center.y+planeY*1.25);
        
        if (plane.center.x < -100 || plane.center.x > screenWidth+100 || plane.center.y < -100 || plane.center.y > screenHeight + 100){
            int direction = arc4random()%4;
            if (direction == 0){
                planeX = 0;
                planeY = 1;
                UIImage *image = [UIImage imageNamed: @"plane down.png"];
                [plane setImage:image];
                
                plane.center = CGPointMake(arc4random()%350, -100);
            }
            if (direction == 1){
                planeX = 0;
                planeY = -1;
                UIImage *image = [UIImage imageNamed: @"plane up.png"];
                [plane setImage:image];
                
                plane.center = CGPointMake(arc4random()%350, screenHeight+100);
            }
            if (direction == 2){
                planeX = 1;
                planeY = 0;
                UIImage *image = [UIImage imageNamed: @"plane right.png"];
                [plane setImage:image];
                
                plane.center = CGPointMake(-100, arc4random()%700);
            }
            if (direction == 3){
                planeX = -1;
                planeY = 0;
                UIImage *image = [UIImage imageNamed: @"plane left.png"];
                [plane setImage:image];
                
                plane.center = CGPointMake(screenWidth+100, arc4random()%700);
            }
        }
        
    }else{
        plane.hidden = YES;
    }
    
    
    
    
}
-(void)fullChooseLoad{
    if (fullchoose){
        if (chooseButton.frame.size.height < screenHeight*1.1){

            chooseButton.frame = CGRectMake(0, 0, chooseButton.frame.size.width, chooseButton.frame.size.height+16);
            
            chooseButton.center = CGPointMake(chooseButton.center.x, (screenHeight/2+screenHeight/4)-8*chooseM);
            
            chooseM++;
            
            
            cameraButton.center = CGPointMake(cameraButton.center.x, (screenHeight/2-screenHeight/4)-14*chooseM);
         
        }
        else{
            chooseButton.enabled = NO;
            cameraButton.enabled = NO;
            
            fullchoose = NO;
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            imagePicker.delegate = self;
            imagePicker.allowsEditing = false;
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:imagePicker animated:true completion:NULL];
        }
    }
    
       
    
}
-(void)fullCoverPhoto{
    if (fullphoto){
        if (cameraButton.frame.size.height < screenHeight){
            
            cameraButton.frame = CGRectMake(0, 0, cameraButton.frame.size.width, cameraButton.frame.size.height+16);
            
            cameraButton.center = CGPointMake(cameraButton.center.x, (screenHeight/2-screenHeight/4)+8*chooseM);
            
            chooseM++;
            
            
            chooseButton.center = CGPointMake(chooseButton.center.x, (screenHeight/2+screenHeight/4)+8*chooseM);
            
        }
        else{
            fullphoto = NO;
            chooseButton.enabled = NO;
            cameraButton.enabled = NO;
            
            
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
            picker.allowsEditing = YES;
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            
            [self presentViewController:picker animated:YES completion:NULL];
        }
    }
}
-(void)animationsReset{
    chooseM = 0;
    chooseButton.frame = CGRectMake(0, 0, screenWidth, screenHeight/2);
    cameraButton.frame = CGRectMake(0, 0, screenWidth, screenHeight/2);
    chooseButton.center = CGPointMake(screenWidth/2, screenHeight/2+screenHeight/4);
    cameraButton.center = CGPointMake(screenWidth/2, screenHeight/2-screenHeight/4);
    _spinner.center = CGPointMake(screenWidth/2, screenHeight/2);
    _spinner.hidden = YES;
    
    [chooseButton setTitle:@"Choose a Photo" forState:UIControlStateNormal];
    [cameraButton setTitle:@"Take a Photo" forState:UIControlStateNormal];
    
    chooseButton.enabled = YES;
    cameraButton.enabled = YES;
    
}
bool fullchoose;
bool fullphoto;

CGFloat screenWidth;
CGFloat screenHeight;
bool loading;
float planeX;
float planeY;
- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.spinner.hidesWhenStopped = true;
    
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    screenWidth = screenSize.width;
    screenHeight = screenSize.height;
    
    fullchoose = NO;
    fullphoto = NO;
    [self animationsReset];
    
    coreGraphics = [NSTimer scheduledTimerWithTimeInterval:0.005
                                     target:self
                                   selector:@selector(corehelper)
                                   userInfo:nil
                                    repeats:YES];
    
    loading = NO;
    plane.hidden = YES;
    int r = arc4random_uniform(screenWidth);
    plane.center = CGPointMake(r, screenHeight*2);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
