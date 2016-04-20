//
//  ViewController.m
//  FoneVerify
//
//  Created by Vaibhav Gautam on 06/04/16.
//  Copyright © 2016 DoubleYou Technology. All rights reserved.
//



//--------------------------------------------------------------------------------------------------------------------------//
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//           P.S. >> Please enter you foneverify customer id and app secret key.                                            //
//                                                                                                                          //
//           Please include << App Transport Security Settings >> key in info.plist                                         //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//                                                                                                                          //
//--------------------------------------------------------------------------------------------------------------------------//

#import "ViewController.h"

#define kAllowedFixedPhoneNumberLenght                  10

// Foneverify customer Id
#define kFoneVerifyCustomerId                           @"YOUR_FONEVERIFY__CUSTOMER_ID"

// foneverify Application Id
#define kFoneVerifyAppSecretKey                         @"YOUR_FONEVERIFY__APP_SECRET_KEY"  //(sms/sms Woo)

// foneverify API base Url
#define kFoneVerifyBaseURLV1_New                        @"http://apifv.foneverify.com/U2opia_Verify/v1.0/flow/"


// foneverify API endpoit (SMS)
#define kFoneVerificationSendSmsToPhoneAPI_New          @"sms"

// foneverify API endpoint (Voice / DID)
#define kFoneVerificationVoiceAPI_New                   @"voice"

// foneverify API endpoint (verification update)
#define kFoneVerificationUpdateAPI_New                  @"update"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self stopActivityIndicator];
}

-(IBAction)submitButtonTapped:(id)sender{
    
    
    NSScanner *scanner = [NSScanner scannerWithString:numberTextField.text];
    BOOL isNumeric = [scanner scanInteger:NULL] && [scanner isAtEnd];
    [numberTextField resignFirstResponder];
    if (!isNumeric || [numberTextField.text length]<kAllowedFixedPhoneNumberLenght) {
        
//        UIAlertView *a/
        
    }
    else{
        [self getOTPFromFoneVerifyForMobileNumber:numberTextField.text];
    }
}

-(void)getOTPFromFoneVerifyForMobileNumber:(NSString *)mobileNumber{
    
    [self startActivityIndicator];
    NSError *error;
    
    NSString *paramString = [NSString stringWithFormat:@"customerId=%@&isoCountryCode=%@&msisdn=%@&appKey=%@",kFoneVerifyCustomerId,@"IN",mobileNumber,kFoneVerifyAppSecretKey];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    
    NSURL *urlObj = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kFoneVerifyBaseURLV1_New,kFoneVerificationSendSmsToPhoneAPI_New]];
    NSMutableURLRequest *requestObj = [NSMutableURLRequest requestWithURL:urlObj];

    [requestObj setHTTPMethod:@"POST"];
    
//    NSDictionary *params = @{@"customerId":kFoneVerifyCustomerId, @"isoCountryCode": @"IN", @"msisdn":mobileNumber, @"appKey": kFoneVerifyAppSecretKey};
    NSData *postData = [paramString dataUsingEncoding:NSUTF8StringEncoding];
    [requestObj setHTTPBody:postData];
    NSURLSessionTask *postDataTask = [session dataTaskWithRequest:requestObj completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError *jsonError;
        
        
        NSString *charlieSendString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"charlieSendString :%@",charlieSendString);
        NSDictionary *reponseVal = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
        NSLog(@"reponseVal :%@",reponseVal);
        NSLog(@"response :%@", response);
        NSLog(@"error :%@",error);
        
        if ([[reponseVal objectForKey:@"responseCode"] intValue] == 200) {
            verificationID = [reponseVal objectForKey:@"verificationId"];
            NSNumber *timeNumer = [NSNumber numberWithInt:([[reponseVal objectForKey:@"timeout"] intValue]>0?90:90)];
            [self performSelectorOnMainThread:@selector(startTimer:) withObject:timeNumer waitUntilDone:NO];
//            [self startTimer:[[reponseVal objectForKey:@"timeout"] intValue]>0?90:90];
        }
        else{
            verificationID = [reponseVal objectForKey:@"verificationId"];
            [self handleResponseFromfoneverifyServer:[[reponseVal objectForKey:@"responseCode"] intValue] andVerififcationStatus:[reponseVal objectForKey:@"verificationStatus"] withResponse:reponseVal];
        }
        
        
    }];
    [postDataTask resume];
}

-(void)startTimer:(NSNumber *)timeOut{
    
    int timeOutTime = [timeOut intValue];
    currMinuteVal = timeOutTime/60;
    currSecondsVal = timeOutTime%60;
    
    [self stopActivityIndicator];
    
    timerLabel.hidden = FALSE;
    
    [timerLabel setText:[NSString stringWithFormat:@"%d%@%02d",currMinuteVal,@":",currSecondsVal]];
    
    if (!timerObj) {
        timerObj=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countdownFired) userInfo:nil repeats:YES];
    }
    isTimerExpired = FALSE;
    
}

-(void)countdownFired
{
    NSLog(@"countDownLabelObj : %@",timerLabel.text);
    if((currMinuteVal>0 || currSecondsVal>=0) && currMinuteVal>=0)
    {
        if(currSecondsVal==0)
        {
            currMinuteVal-=1;
            currSecondsVal=59;
        }
        else if(currSecondsVal>0)
        {
            currSecondsVal-=1;
        }
        if(currMinuteVal>-1)
            [timerLabel setText:[NSString stringWithFormat:@"%d%@%02d",currMinuteVal,@":",currSecondsVal]];
        
    }
    else
    {
        
        
        [timerObj invalidate];
        timerObj = nil;
        isTimerExpired = TRUE;
        [self startActivityIndicator];
        //Timer over call sms failed to send
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkUpdateStatusFromFoneverifyAutomatically) object:nil];
        [self checkUpdateStatusFromFoneverifyAutomatically];
        
    }
}

-(void)stopTimer{
    [timerObj invalidate];
    timerObj = nil;
    [timerLabel setText:[NSString stringWithFormat:@"%d%@%02d",0,@":",0]];
}


-(void)handleResponseFromfoneverifyServer:(int)statusCode andVerififcationStatus:(NSString *)verificatoinStatus withResponse:(NSDictionary *)response{
    
    [self stopActivityIndicator];
    
    switch (statusCode) {
            
        case 200:{
            //            VERIFICATION_COMPLETED
            //Enter your code
            [self stopTimer];
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([numberTextField isFirstResponder]) {
                    [numberTextField resignFirstResponder];
                }
                
                if ([otpTextField isFirstResponder] && [otpTextField canResignFirstResponder]) {
                    [otpTextField resignFirstResponder];
                }
            });
            UIAlertController *alertObj = [UIAlertController alertControllerWithTitle:nil message:@"Number Verified!!" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//
            }];
            [alertObj addAction:defaultAction];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alertObj animated:YES completion:nil];
            });
        }
            break;
        case 700:{
            //VERIFICATION_FAILED
            // VErification failed
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([numberTextField isFirstResponder]) {
                    [numberTextField resignFirstResponder];
                }
                
                if ([otpTextField isFirstResponder] && [otpTextField canResignFirstResponder]) {
                    [otpTextField resignFirstResponder];
                }
            });
            UIAlertController *alertObj = [UIAlertController alertControllerWithTitle:nil message:@"Verfication failed." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                numberTextField.text = @"";
                otpTextField.text = @"";
            }];
            [alertObj addAction:defaultAction];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alertObj animated:YES completion:nil];
            });
            
            break;
        }
        case 701:
        case 705:
        case 707:
        case 706:{
            //Trying fallback
            verificationID = [response objectForKey:@"verificationId"];
            
            NSNumber *timeNumer = [NSNumber numberWithInt:([[response objectForKey:@"timeout"] intValue]>0?90:90)];
            [self performSelectorOnMainThread:@selector(startTimer:) withObject:timeNumer waitUntilDone:NO];
//            [self startTimer:[[response objectForKey:@"timeout"] intValue]>0?90:90];
            
        }
            break;
        case 703:{
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([numberTextField isFirstResponder]) {
                    [numberTextField resignFirstResponder];
                }
                
                if ([otpTextField isFirstResponder] && [otpTextField canResignFirstResponder]) {
                    [otpTextField resignFirstResponder];
                }
            });
            UIAlertController *alertObj = [UIAlertController alertControllerWithTitle:nil message:@"You have entered a mobile number that already exists." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                [otpTextField resignFirstResponder];
            }];
            [alertObj addAction:defaultAction];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alertObj animated:YES completion:nil];
            });
        }
        case 702:{
            //            WRONG_OTP_PROVIDED
            //Show error message
            
//            [self stopActivityIndicator];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([numberTextField isFirstResponder]) {
                    [numberTextField resignFirstResponder];
                }
                
                if ([otpTextField isFirstResponder] && [otpTextField canResignFirstResponder]) {
                    [otpTextField resignFirstResponder];
                }
            });
            
            
            
            UIAlertController *alertObj = [UIAlertController alertControllerWithTitle:@"Wrong OTP!!" message:@"Please re-check the code" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                [otpTextField resignFirstResponder];
            }];
            [alertObj addAction:defaultAction];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alertObj animated:YES completion:nil];
            });
            break;
        }
        case 506:
        case 708:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([numberTextField isFirstResponder]) {
                    [numberTextField resignFirstResponder];
                }
                
                if ([otpTextField isFirstResponder] && [otpTextField canResignFirstResponder]) {
                    [otpTextField resignFirstResponder];
                }
            });
            UIAlertController *alertObj = [UIAlertController alertControllerWithTitle:nil message:@"Request already exists. Please check your sms inbox." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                [otpTextField resignFirstResponder];
            }];
            [alertObj addAction:defaultAction];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alertObj animated:YES completion:nil];
            });
            
            
//            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkUpdateStatusFromFoneverifyAutomatically) object:nil];
//            [self performSelector:@selector(checkUpdateStatusFromFoneverifyAutomatically) withObject:nil afterDelay:5.0];
            [self checkUpdateStatusFromFoneverifyAutomatically];
        }
            break;
    }
    
}

-(void)checkUpdateStatusFromFoneverifyAutomatically{
    [self sendEnteredCodeToFoneverifyServer:@"" andRetry:TRUE];
}
-(void)sendEnteredCodeToFoneverifyServer:(NSString *)codeText andRetry:(BOOL)retryUpdate{
    
    
    [self startActivityIndicator];
//    NSError *error;
    
    NSString *paramString = [NSString stringWithFormat:@"%@%@?verificationId=%@&appKey=%@&customerId=%@",kFoneVerifyBaseURLV1_New,kFoneVerificationUpdateAPI_New,verificationID,kFoneVerifyAppSecretKey,kFoneVerifyCustomerId];
    
    if ([codeText length]>0) {
        paramString = [NSString stringWithFormat:@"%@&code=%@",paramString,codeText];
    }
    
//    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURL *urlObj = [NSURL URLWithString:paramString];
//    NSMutableURLRequest *requestObj = [NSMutableURLRequest requestWithURL:paramString];
    
//    [requestObj setHTTPMethod:@"GET"];
    
    //    NSDictionary *params = @{@"customerId":kFoneVerifyCustomerId, @"isoCountryCode": @"IN", @"msisdn":mobileNumber, @"appKey": kFoneVerifyAppSecretKey};
//    NSData *postData = [paramString dataUsingEncoding:NSUTF8StringEncoding];
//    [requestObj setHTTPBody:postData];
    
    NSURLSessionTask *getDataTask = [session dataTaskWithURL:urlObj completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSLog(@"%@", json);
        [self stopActivityIndicator];
        NSError *jsonError;
        NSString *charlieSendString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"charlieSendString :%@",charlieSendString);
        NSDictionary *reponseVal = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
        NSLog(@"reponseVal :%@",reponseVal);
        NSLog(@"response :%@", response);
        NSLog(@"error :%@",error);
        [self handleResponseFromfoneverifyServer:[[reponseVal objectForKey:@"responseCode"] intValue] andVerififcationStatus:[reponseVal objectForKey:@"verificationStatus"] withResponse:reponseVal];
        
        
    }];
    [getDataTask resume];
 
    
}

-(IBAction)submitOtpCodeButtonTapped:(id)sender{
    if ([otpTextField.text length]>0) {
        [self sendEnteredCodeToFoneverifyServer:otpTextField.text andRetry:FALSE];
    }
}

-(void)startActivityIndicator{
    dispatch_async(dispatch_get_main_queue(), ^{
        activityIndicatorView.hidden = FALSE;
        [activityIndicatorView startAnimating];
    });
    
}

-(void)stopActivityIndicator{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([activityIndicatorView isAnimating]) {
            [activityIndicatorView stopAnimating];
        }
        activityIndicatorView.hidden = TRUE;
    });
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
