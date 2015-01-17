//
//  DrawingViewController.m
//  Pictaphone
//
//  Created by Kelly Hutchison on 11/22/14.
//  Copyright (c) 2014 Kelly Hutchison. All rights reserved.
//

#import "DrawingViewController.h"
#import "PenSettingsViewController.h"
#import "ConfirmationViewController.h"
#import "ViewLastTurnViewController.h"
#import "model.h"

#define THIN 5.0f
#define MEDIUM 13.0f
#define THICK 20.0f

@interface DrawingViewController ()
@property (nonatomic,strong) model *model;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControlOutlet;
- (IBAction)segmentControlPressed:(id)sender;

@property (strong, nonatomic) IBOutlet UIView *drawingView;
@property (nonatomic, assign) CGRect drawingViewFrame;

@property (weak, nonatomic) IBOutlet UIImageView *resetPressed;

// Game Settings Properties
@property (nonatomic, assign) NSInteger roundCount;
@property (nonatomic, assign) NSInteger playerCount;
@property (nonatomic, assign) BOOL firstRoundAutoGenerated;
@property (nonatomic, assign) NSString *firstRoundType;

@property (weak, nonatomic) IBOutlet UILabel *roundLabel;
@property (weak, nonatomic) IBOutlet UILabel *playerLabel;
@property (weak, nonatomic) IBOutlet UIButton *endOfGameDoneButton;
- (IBAction)endOfRoundPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *doneButton;
- (IBAction)doneButtonPressed:(id)sender;

@property (nonatomic, assign) NSString *lastRoundPhrase;
@property (weak, nonatomic) IBOutlet UIButton *viewLastTurnButton;
- (IBAction)viewLastTurnPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *clickHereLabel;
@property (weak, nonatomic) IBOutlet UIImageView *clickHereArrow;

@end

@implementation DrawingViewController
CGFloat drawOpacity;
CALayer* drawLayer;
UIImage* mainImage;
UIImage* drawImage;
CGPoint lastPoint;
CGPoint currentPoint;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        _model = [model sharedInstance];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.opaque = YES;
    self.view.backgroundColor = [UIColor colorWithWhite:5.0 alpha:0.95];
    
    if(!self.autoGenerate)
    {
        self.firstRoundAutoGenerated = NO;
    }
    else {
        self.firstRoundAutoGenerated = YES;
    }
    
   // self.drawingViewFrame = self.drawingView.frame;
    self.drawingViewFrame = self.drawingView.frame;
    self.drawingView.layer.borderWidth = 5.0f;
    self.drawingView.layer.borderColor = [[UIColor grayColor] CGColor];
    
    [self initializePen];
    [self initializeGameSettings];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)initializeGameSettings
{
    [self initializeLastRoundButton];
    
    // Check if this is the last turn
    NSInteger turnsRemaining = [self.model turnsRemaining];
    if(turnsRemaining == 1) {
        self.doneButton.hidden = YES;
        self.endOfGameDoneButton.hidden = NO;
    } else {
        self.doneButton.hidden = NO;
        self.endOfGameDoneButton.hidden = YES;
    }
    
    NSInteger currentRound = [self.model currentRound];
    [self.roundLabel setText:[NSString stringWithFormat:@"%@%ld", @"Round: ", (long)currentRound]];
    
    NSInteger currentPlayer = [self.model currentPlayer];
    [self.playerLabel setText:[NSString stringWithFormat:@"%@%ld", @"Player: ", (long)currentPlayer]];
    
    // Show/Hide the click here label during first round
    if(currentRound == 1) {
        if([self.model currentTurn]== 1 && !self.firstRoundAutoGenerated) {
            self.clickHereArrow.hidden = YES;
            self.clickHereLabel.hidden = YES;
        } else {
            self.clickHereArrow.hidden = NO;
            self.clickHereLabel.hidden = NO;
        }
    } else {
        self.clickHereArrow.hidden = YES;
        self.clickHereLabel.hidden = YES;
    }
}

-(void)initializeLastRoundButton
{
    // Check if first image is auto generated
    // Check if this is first round/auto generate
    if([self.model currentTurn]== 1) {
        if(self.firstRoundAutoGenerated) {
            self.viewLastTurnButton.hidden = NO;
            self.viewLastTurnButton.userInteractionEnabled = YES;
            
            // Set random icon image
            self.lastRoundPhrase = self.randomPhrase;
            UIImage *image = [UIImage imageNamed:@"sentences.png"];
            [self.viewLastTurnButton setImage:image forState:UIControlStateNormal];
        }
        else {
            self.viewLastTurnButton.hidden = YES;
            self.clickHereArrow.hidden = YES;
            self.clickHereLabel.hidden = YES;
        }
    }
    else {
        self.viewLastTurnButton.hidden = NO;
        self.viewLastTurnButton.userInteractionEnabled = YES;
        
        // Set random icon image
        NSInteger lastIndex = [self.model contentsArrayCount]-1;
        self.lastRoundPhrase = [self.model valueOfContentsArrayAtIndex:lastIndex];
        UIImage *image = [UIImage imageNamed:@"sentences.png"];
        [self.viewLastTurnButton setImage:image forState:UIControlStateNormal];
    }
    
    // Set button border
    self.self.viewLastTurnButton.layer.borderWidth = 5.0f;
    self.self.viewLastTurnButton.layer.borderColor = [[UIColor grayColor] CGColor];
    [self.viewLastTurnButton setContentMode:UIViewContentModeRedraw];
}

- (void)initializePen
{
    _toolType = Paint;
    _drawOpacity = 1.0f;
    _drawColor = [UIColor blackColor];
    _drawWidth = 5.0f;
    
    drawLayer = [[CALayer alloc] init];
    drawLayer.frame = CGRectMake(0.0f, 0.0f, self.drawingView.layer.frame.size.width, self.drawingView.layer.frame.size.height);
    mainImage = nil;
    drawImage = nil;
    
    [self.drawingView.layer addSublayer:drawLayer];
    [self clearToColor:self.drawingView.backgroundColor];
}


- (void) drawLineFrom:(CGPoint)from to:(CGPoint)to width:(CGFloat)width
{
    UIGraphicsBeginImageContext(self.drawingView.frame.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(ctx, 1.0f, -1.0f);
    CGContextTranslateCTM(ctx, 0.0f, -self.drawingView.frame.size.height);
    if (drawImage != nil) {
        CGRect rect = CGRectMake(0.0f, 0.0f, self.drawingView.frame.size.width, self.drawingView.frame.size.height);
        CGContextDrawImage(ctx, rect, drawImage.CGImage);
    }
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineWidth(ctx, width);
    CGContextSetStrokeColorWithColor(ctx, self.drawColor.CGColor);
    CGContextMoveToPoint(ctx, from.x, from.y);
    CGContextAddLineToPoint(ctx, to.x, to.y);
    CGContextStrokePath(ctx);
    CGContextFlush(ctx);
    drawImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    drawLayer.contents = (id)drawImage.CGImage;
}

- (void) eraseLineFrom:(CGPoint)from to:(CGPoint)to width:(CGFloat)width
{
    UIGraphicsBeginImageContext(self.drawingView.frame.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(ctx, 1.0f, -1.0f);
    CGContextTranslateCTM(ctx, 0.0f, -self.drawingView.frame.size.height);
    if (drawImage != nil) {
        CGRect rect = CGRectMake(0.0f, 0.0f, self.drawingView.frame.size.width, self.drawingView.frame.size.height);
        CGContextDrawImage(ctx, rect, drawImage.CGImage);
    }
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineWidth(ctx, width);
    CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextMoveToPoint(ctx, from.x, from.y);
    CGContextAddLineToPoint(ctx, to.x, to.y);
    CGContextStrokePath(ctx);
    CGContextFlush(ctx);
    drawImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    drawLayer.contents = (id)drawImage.CGImage;
}

- (void) commitDrawingWithOpacity:(CGFloat)opacity
{
    UIGraphicsBeginImageContextWithOptions(self.drawingView.bounds.size, NO, 1.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(ctx, 1.0f, -1.0f);
    CGContextTranslateCTM(ctx, 0.0f, -self.drawingView.frame.size.height);
    CGRect rect = CGRectMake(0.0f, 0.0f, self.drawingView.frame.size.width, self.drawingView.frame.size.height);
    if (mainImage != nil) {
        CGContextDrawImage(ctx, rect, mainImage.CGImage);
    }
    CGContextSetAlpha(ctx, opacity);
    CGContextDrawImage(ctx, rect, drawImage.CGImage);
    mainImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.drawingView.layer.contents = (id)mainImage.CGImage;
    drawLayer.contents = nil;
    drawImage = nil;
}

- (void)paintTouchesBegan
{
    [self drawLineFrom:lastPoint to:lastPoint width:self.drawWidth];
}

- (void)paintTouchesMoved
{
    [self drawLineFrom:lastPoint to:currentPoint width:self.drawWidth];
}

- (void) paintTouchesEnded
{
    [self commitDrawingWithOpacity:self.drawOpacity];
}

- (void)eraseTouchesBegan
{
    [self eraseLineFrom:lastPoint to:lastPoint width:self.drawWidth];
}

- (void)eraseTouchesMoved
{
    [self eraseLineFrom:lastPoint to:currentPoint width:self.drawWidth];
}

- (void) eraseTouchesEnded
{
    [self commitDrawingWithOpacity:self.drawOpacity];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.drawingView.userInteractionEnabled) {
        [super touchesBegan:touches withEvent:event];
        return;
    }
    
    UITouch *touch = [touches anyObject];
    lastPoint = [touch locationInView:self.drawingView];
    lastPoint.y = self.drawingView.frame.size.height - lastPoint.y;
    
    if (self.toolType == Paint) {
        [self paintTouchesBegan];
    }
    else if (self.toolType == Erase)
    {
        [self eraseTouchesBegan];
    }
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.drawingView.userInteractionEnabled) {
        [super touchesMoved:touches withEvent:event];
        return;
    }
    
    UITouch *touch = [touches anyObject];
    currentPoint = [touch locationInView:self.drawingView];
    currentPoint.y = self.drawingView.frame.size.height - currentPoint.y;
    
    if (self.toolType == Paint) {
        [self paintTouchesMoved];
    }
    else if (self.toolType == Erase)
    {
        [self eraseTouchesMoved];
    }
    
    lastPoint = currentPoint;
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.drawingView.userInteractionEnabled) {
        [super touchesEnded:touches withEvent:event];
        return;
    }
    
    if (self.toolType == Paint) {
        [self paintTouchesEnded];
    }
    else if (self.toolType == Erase)
    {
        [self eraseTouchesEnded];
    }
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.drawingView.userInteractionEnabled) {
        [super touchesCancelled:touches withEvent:event];
        return;
    }
    [self touchesEnded:touches withEvent:event];
}

- (void) clearToColor:(UIColor*)color
{
    UIGraphicsBeginImageContextWithOptions(self.drawingView.bounds.size, NO, 1.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(0.0f, 0.0f, self.drawingView.frame.size.width, self.drawingView.frame.size.height);
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CGContextFillRect(ctx, rect);
    CGContextFlush(ctx);
    mainImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.drawingView.layer.contents = (id)mainImage.CGImage;
}


- (UIImage*) getSketch;
{
    return mainImage;
}

- (void) setSketch:(UIImage*)sketch
{
    self.drawingView.backgroundColor = [UIColor clearColor];
    self.drawingView.layer.borderColor = [[UIColor clearColor] CGColor];
    
    UIImageView* imageView = [[UIImageView alloc] initWithFrame:self.drawingView.bounds];
    imageView.contentMode = self.drawingView.contentMode;
    imageView.image = sketch;
    imageView.backgroundColor = [UIColor clearColor];
    
    UIGraphicsBeginImageContextWithOptions(self.drawingView.bounds.size, NO, 1.0);
    [imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    mainImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self commitDrawingWithOpacity:1.0f];
}

- (void) updateDrawOpacityWith:(CGFloat)drawOpacity
{
    _drawOpacity = drawOpacity;
    drawLayer.opacity = _drawOpacity;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([segue.identifier isEqualToString:@"penSettingsSegue"])
    {
        PenSettingsViewController *colorViewController = segue.destinationViewController;
        UIColor *color = self.drawColor;
        colorViewController.pageColor = color;
        
        CGFloat penWidth = self.drawWidth;
        colorViewController.drawWidth = penWidth;
        
        colorViewController.drawWidthCompletionBlock = ^(CGFloat value){
            self.drawWidth = value;
        };
        
        colorViewController.completionBlock = ^(id value){
            [self dismissViewControllerAnimated:YES completion:NULL];
            NSDictionary *dictionary = value;
            UIColor *color = [dictionary objectForKey:@"color"];
            self.drawColor = color;
        };
        
    }
    
    else if([segue.identifier isEqualToString:@"confirmErase"])
    {
        ConfirmationViewController *confirmEraseViewController = segue.destinationViewController;
        confirmEraseViewController.completionBlock = ^{
            [self dismissViewControllerAnimated:YES completion:NULL];

            [self clearToColor:[UIColor clearColor]];
        };
    }
    
    else if ([segue.identifier isEqualToString:@"lastTurn"])
    {
        ViewLastTurnViewController *lastTurnVC = segue.destinationViewController;
        lastTurnVC.sentence = self.lastRoundPhrase;
        lastTurnVC.contentToDisplay = @"phrase";
    }
}


- (IBAction)segmentControlPressed:(id)sender {
    UISegmentedControl *segmentedControl = (UISegmentedControl*) sender;
    NSInteger segmentClicked = segmentedControl.selectedSegmentIndex;
    
    // Paint
    if (segmentClicked == 0) {
        self.toolType = Paint;
    }
    // Erase
    else {
        self.toolType = Erase;
    }
    
}
- (IBAction)endOfRoundPressed:(id)sender {
    UIImage *drawing = [self imageWithView:self.drawingView];
    
    [self.model trackFinishedTurn];
    [self.model populateContentsArrayWithImage:drawing];
}
- (IBAction)doneButtonPressed:(id)sender {
    
    UIImage *drawing = [self imageWithView:self.drawingView];
    
    [self.model trackFinishedTurn];
    [self.model populateContentsArrayWithImage:drawing];
}

- (UIImage *) imageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

- (IBAction)viewLastTurnPressed:(id)sender {
}

@end
