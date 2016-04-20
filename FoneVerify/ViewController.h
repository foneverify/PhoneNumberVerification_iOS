//
//  ViewController.h
//  FoneVerify
//
//  Created by Vaibhav Gautam on 06/04/16.
//  Copyright © 2016 DoubleYou Technology. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<NSURLSessionDelegate>{
    IBOutlet UITextField *numberTextField;
    IBOutlet UIButton *submitButton;
    
    IBOutlet UITextField *otpTextField;
    IBOutlet UIButton *submitOtpButton;
    IBOutlet UIActivityIndicatorView *activityIndicatorView;
    IBOutlet UILabel *timerLabel;
    
    int currMinuteVal;
    int currSecondsVal;
    NSTimer *timerObj;
    BOOL isTimerExpired;
    
    NSString *verificationID;
}

-(IBAction)submitButtonTapped:(id)sender;
-(IBAction)submitOtpCodeButtonTapped:(id)sender;






@end

