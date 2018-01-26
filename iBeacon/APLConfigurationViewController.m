#import "APLConfigurationViewController.h"
#import "APLDefaults.h"
#import "APLUUIDViewController.h"

@import CoreLocation;
@import CoreBluetooth;


CBPeripheralManager *peripheralManager = nil;
CLBeaconRegion *region = nil;
NSNumber *power = nil;


@interface APLConfigurationViewController () <CBPeripheralManagerDelegate, UIAlertViewDelegate, UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UISwitch *enabledSwitch;
@property (nonatomic, weak) IBOutlet UITextField *uuidTextField;

@property (nonatomic, weak) IBOutlet UITextField *majorTextField;
@property (nonatomic, weak) IBOutlet UITextField *minorTextField;
@property (nonatomic, weak) IBOutlet UITextField *powerTextField;

@property BOOL enabled;
@property NSUUID *uuid;
@property NSNumber *major;
@property NSNumber *minor;

@property UIBarButtonItem *doneButton;

@property NSNumberFormatter *numberFormatter;

- (void)updateAdvertisedRegion;

@end




@implementation APLConfigurationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing:)];

    if(region)
    {
        self.uuid = region.proximityUUID;
        self.major = region.major;
        self.minor = region.minor;
    }
    else
    {
        self.uuid = [APLDefaults sharedDefaults].defaultProximityUUID;
        self.major = [NSNumber numberWithShort:0];
        self.minor = [NSNumber numberWithShort:0];
    }
    
    if(!power)
    {
        power = [APLDefaults sharedDefaults].defaultPower;
    }
    
    self.numberFormatter = [[NSNumberFormatter alloc] init];
    self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (!peripheralManager)
    {
        peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    }
    else
    {
        peripheralManager.delegate = self;
    }

    // Refresh the enabled switch.
    self.enabled = self.enabledSwitch.on = peripheralManager.isAdvertising;
    
    self.uuidTextField.text = [self.uuid UUIDString];
    
    self.majorTextField.text = [self.major stringValue];
    self.minorTextField.text = [self.minor stringValue];
    self.powerTextField.text = [power stringValue];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    peripheralManager.delegate = nil;
}


- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{

}


#pragma mark - Text editing

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if(textField == self.uuidTextField)
    {
        [self performSegueWithIdentifier:@"selectUUID" sender:self];
        return NO;
    }
    
    return YES;
}


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.navigationItem.rightBarButtonItem = self.doneButton;
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if(textField == self.majorTextField)
    {
        self.major = [self.numberFormatter numberFromString:textField.text];
    }
    else if(textField == self.minorTextField)
    {
        self.minor = [self.numberFormatter numberFromString:textField.text];
    }
    else if(textField == self.powerTextField)
    {
        power = [self.numberFormatter numberFromString:textField.text];
        
        // ensure the power is negative
        if([power intValue] > 0)
        {
            power = [NSNumber numberWithInt:-[power intValue]];
            textField.text = [power stringValue];
        }
    }
    
    self.navigationItem.rightBarButtonItem = nil;
    
    [self updateAdvertisedRegion];
}


- (IBAction)toggleEnabled:(UISwitch *)sender
{
    self.enabled = sender.on;
    [self updateAdvertisedRegion];
}


- (IBAction)doneEditing:(id)sender
{
    [self.majorTextField resignFirstResponder];
    [self.minorTextField resignFirstResponder];
    [self.powerTextField resignFirstResponder];
    
    [self.tableView reloadData];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"selectUUID"])
    {
        APLUUIDViewController *uuidSelector = [segue destinationViewController];
        
        uuidSelector.uuid = self.uuid;
    }
}


- (IBAction)unwindUUIDSelector:(UIStoryboardSegue*)sender
{
    APLUUIDViewController *uuidSelector = [sender sourceViewController];
    
    self.uuid = uuidSelector.uuid;
    [self updateAdvertisedRegion];
}


- (void)updateAdvertisedRegion
{
    if(peripheralManager.state < CBPeripheralManagerStatePoweredOn)
    {
        NSString *title = NSLocalizedString(@"Bluetooth must be enabled", @"");
        NSString *message = NSLocalizedString(@"To configure your device as a beacon", @"");
        NSString *cancelButtonTitle = NSLocalizedString(@"OK", @"Cancel button title in configuration Save Changes");
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
        [errorAlert show];
        
        return;
    }
    
	[peripheralManager stopAdvertising];
    
    if(self.enabled)
    {
        // We must construct a CLBeaconRegion that represents the payload we want the device to beacon.
        NSDictionary *peripheralData = nil;
        
        region = [[CLBeaconRegion alloc] initWithProximityUUID:self.uuid major:[self.major shortValue] minor:[self.minor shortValue] identifier:BeaconIdentifier];
        peripheralData = [region peripheralDataWithMeasuredPower:power];
        
        // The region's peripheral data contains the CoreBluetooth-specific data we need to advertise.
        if(peripheralData)
        {
            [peripheralManager startAdvertising:peripheralData];
        }
    }
}

@end
