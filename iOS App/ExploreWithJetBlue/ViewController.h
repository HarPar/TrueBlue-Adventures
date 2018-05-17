//
//  ViewController.h
//  ExploreWithJetBlue
//
//  Created by Toby on 2017-12-01.
//  Copyright © 2017 YHACK17. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UIImagePickerControllerDelegate>{
    IBOutlet UIButton * chooseButton;
    IBOutlet UIButton * cameraButton;
    
    NSTimer * coreGraphics; 
    
    IBOutlet UIImageView * plane; 
}
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;



@end

