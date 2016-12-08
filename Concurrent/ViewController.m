//
//  ViewController.m
//  GCDTest
//
//  Created by david on 12/7/16.
//  Copyright © 2016 David Dang. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

// Property that get will get change by a
// background threads (GCD/Operation/NSThread/Timer)
@property (nonatomic) NSInteger bgNumber;

// This property will be change by a user click a button
@property (nonatomic) NSInteger userNumber;

// Property to control the start and stop of GCD Queue
@property (nonatomic) BOOL runFlag;

// Property for Timer and Thread as we need to stop them
@property (strong, nonatomic) NSTimer *myTimer;
@property (strong, nonatomic) NSThread *myThread;

// UI properties
@property (weak, nonatomic) IBOutlet UILabel *backgroundLabel;
@property (weak, nonatomic) IBOutlet UILabel *interactiveLabel;

// UI Buttons for each type of Concurrency
@property (weak, nonatomic) IBOutlet UIButton *startGCD;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *startOperation;
@property (weak, nonatomic) IBOutlet UIButton *startThread;
@property (weak, nonatomic) IBOutlet UIButton *startTimer;
@property (nonatomic) NSInteger buttonClicked;


// Button to start each type of concurrency
- (IBAction)startGCD:(id)sender;
- (IBAction)startOperation:(id)sender;
- (IBAction)startThread:(id)sender;
- (IBAction)startTimer:(id)sender;


// Button to stop the GCD process
- (IBAction)stopButtonClick:(id)sender;

// Button to allow user to manually increase
- (IBAction)userButtonClick:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize the data and button state
    [self stopToggle];
    self.backgroundLabel.text = @"Initialized";
    
    // Initialize the interface for user increase
    self.userNumber = 0;
    self.buttonClicked = 0;
    
    self.interactiveLabel.text = [NSString stringWithFormat:@"User num %ld", self.userNumber];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Helper function to just help to toggle the buttons on the UI not that important
// Use when a stop Button is click
-(void) stopToggle {
    self.stopButton.enabled = NO;
    self.startGCD.enabled = YES;
    self.startOperation.enabled = YES;
    self.startThread.enabled = YES;
    self.startTimer.enabled = YES;
    
}

// Helper function to just help to toggle the buttons on the UI not that important
// Use when any of the start button click
-(void) startToggle {
    self.stopButton.enabled = YES;
    self.startGCD.enabled = NO;
    self.startOperation.enabled = NO;
    self.startThread.enabled = NO;
    self.startTimer.enabled = NO;
}


// Function to update the BackGround Label
// This is a UI update so must run on main thread
-(void) updateBackgroundLabel {
    self.backgroundLabel.text = [NSString stringWithFormat:@"Num %ld", self.bgNumber];
}


// Function to that will be run by NSThread to update the background number
// and tell the main thread to update the UI
-(void) threadOperation {
    @autoreleasepool {
        NSLog(@"NSThread dispatched !");
        // We will get into an infinite loop
        while (YES) {
            // We modify the background number by 1
            self.bgNumber += 1;
            
            // Then we tell the main thread to update the label
            [self performSelectorOnMainThread:@selector(updateBackgroundLabel)
                                   withObject:nil waitUntilDone:NO];
            
            // Then we sleep for 1 second (change 1 to 5 to sleep for 5 second
            [NSThread sleepForTimeInterval:1];
            
            // Then we see if we should continue or if user clicked the stop button
            if (!self.runFlag) {
                break;
            }
        }
        NSLog(@"NSThread terminated !");
        // Then we tell the thread to exit/terminate
        [NSThread exit];
    }
}

// Function to start Timer operation
-(void) timerOperation {
    // Increase the number by 1
    self.bgNumber += 1;
    
    // Then tell the main thread to update the UI
    [self performSelectorOnMainThread:@selector(updateBackgroundLabel)
                           withObject:nil waitUntilDone:NO];
}

// Button to start the GCD
- (IBAction)startGCD:(id)sender {
    // Change the state of the buttons
    [self startToggle];
    
    // Set the runFlag to YES, mark startGCD clicked, Initialize number to 0
    self.buttonClicked = 1;
    self.runFlag = YES;
    self.bgNumber = -1;
    
	// Create a concurrent queue
    dispatch_queue_t GCDQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // Dispatch GCDQueue and pass a block call back to run when the queue is submitted
    dispatch_async(GCDQueue, ^{
        NSLog(@"GCDQueue dispatched !");
        // We will get into an infinite loop
        while (YES) {
            // We modify the background number by 1
            self.bgNumber += 1;

            // Then we tell the main thread to update the label
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateBackgroundLabel];
            });
            
            // Then we sleep for 1 second (change 1 to 5 to sleep for 5 second
            [NSThread sleepForTimeInterval:1];
            
            // Then we see if we should continue or if user clicked the stop button
            if (!self.runFlag) {
                break;
            }
        }
        NSLog(@"GCDQueue terminated !");
    });
    
}

// Button to start concurrency test for Operation Queue
- (IBAction)startOperation:(id)sender {
    // Change the state of the buttons
    [self startToggle];
    
    // initialize the number to -1 and mark that startOperation was clicked
    self.buttonClicked = 2;
    self.runFlag = YES;
    self.bgNumber = -1;
    
    // Create Operation queue
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    
    /* This one is if you want to have the operation run a method on this class
    NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                        initWithTarget:self
                                        selector:@selector(METHOD_NAME) object:nil];
    [operationQueue addOperation: operation];
    */
    
    // Create a block operation similar to GCD
    NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"Operation Queue dispatched !");
        // We will get into an infinite loop
        while (YES) {
            // We modify the background number by 1
            self.bgNumber += 1;
            
            // Then we tell the main thread to update its UI
            [self performSelectorOnMainThread:@selector(updateBackgroundLabel) withObject:nil waitUntilDone:NO];
            
            // Then we sleep for 1 second (change 1 to 5 to sleep for 5 second
            [NSThread sleepForTimeInterval:1];
            
            // Then we see if we should continue or if user clicked the stop button
            if (!self.runFlag) {
                break;
            }
        }
    }];
    
    // We can use completionBlock to do whatever it is after the operation completed
    operation.completionBlock = ^{
        NSLog(@"Operation Queue terminated !");
    };
    
    // Add the operation to the operationQueue
    [operationQueue addOperation: operation];
    
}

- (IBAction)startThread:(id)sender {
    // Change the state of the buttons
    [self startToggle];
    
    // initialize the number to -1 and mark that startThread was clicked
    self.buttonClicked = 3;
    self.runFlag = YES;
    self.bgNumber = -1;
    
    // Initialize myThread and tell it to run threadOperation on this object
	self.myThread = [[NSThread alloc] initWithTarget:self
                                               selector:@selector(threadOperation)
                                                 object:nil];
    
    // We then start the thread
    [self.myThread start];
    
}

- (IBAction)startTimer:(id)sender {
    // Change the state of the buttons
    [self startToggle];
    
    // initialize the number to -1 and mark that startTimer was clicked
    self.buttonClicked = 4;
    self.runFlag = YES;
    self.bgNumber = -1;
    
    // Initialize myTimer to schedule the task repeatedly for every 1 second
    // and tell it to run timerOperation on this object
	self.myTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(timerOperation)
                                   userInfo:nil
                                    repeats:YES];
    NSLog(@"NSTimer started !");
}


// Button to stop the current concurrency test
- (IBAction)stopButtonClick:(id)sender {
    // We change the runFlag to NO to quit the while loop of operation
    self.runFlag = NO;
    [self stopToggle];
    
    switch (self.buttonClicked) {
        case 1: // Start GCD Button was click
            // Do not have to do anything
            break;
        case 2: // Start Operation Queue button was click
			// Do not thing as runFlag control the stop of the block
            break;
        case 3: // Start Thread button was click
            // Cancel the thread
            [self.myThread cancel];
            break;
        case 4: // Start Timer button was click
            // Stop the timer.  Since the timer is run on a scheduler, we cannot stop
            // it from within the same data block
            [self.myTimer invalidate];
            NSLog(@"NSTimer stopped !");
            break;
        default:
            break;
    }
    
}

// This button is click if user want to manually increase
- (IBAction)userButtonClick:(id)sender {
    self.userNumber += 1;
    self.interactiveLabel.text = [NSString stringWithFormat:@"User num %ld", self.userNumber];
}

@end
