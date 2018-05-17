//
//  FlightChooser.h
//  ExploreWithJetBlue
//
//  Created by Toby on 2017-12-02.
//  Copyright © 2017 YHACK17. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FlightChooser : UIViewController{
    float origLong;
    float destLong;
    float destLat; 
    
    NSString * departureDate;
    NSMutableArray * keywordsArray;
    
    IBOutlet UIImageView * originalImage;
    IBOutlet UILabel * originalLandmark;
    
    IBOutlet UIButton * dest1;
    IBOutlet UIButton * dest2;
    IBOutlet UIButton * dest3;
    IBOutlet UIButton * dest4;
    
    IBOutlet UIButton * restart;
    
    ///InformationView
    IBOutlet UILabel * destinationName;
    IBOutlet UILabel * destinationAirport;
    IBOutlet UILabel * price;
    IBOutlet UITextView * description;
    IBOutlet UILabel * flightTime; 
    IBOutlet UIButton * bookNow;
    IBOutlet UIButton * blueSkyLoad;
    IBOutlet UILabel * loadingMessage; 
    
    NSTimer * coreGraphics0; 
}




@end
