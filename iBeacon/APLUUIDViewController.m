#import "APLUUIDViewController.h"
#import "APLDefaults.h"

@interface APLUUIDViewController ()

@end

@implementation APLUUIDViewController


#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [APLDefaults sharedDefaults].supportedProximityUUIDs.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if(indexPath.row < [APLDefaults sharedDefaults].supportedProximityUUIDs.count)
    {
        cell.textLabel.text = [[APLDefaults sharedDefaults].supportedProximityUUIDs[indexPath.row] UUIDString];
        if([self.uuid isEqual:[APLDefaults sharedDefaults].supportedProximityUUIDs[indexPath.row]])
        {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    
    return cell;
}


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath * selectionIndexPath = [self.tableView indexPathForSelectedRow];
    NSInteger selection;

    if(selectionIndexPath.row < [APLDefaults sharedDefaults].supportedProximityUUIDs.count)
    {
        selection = selectionIndexPath.row;
    }
    else
    {
        selection = 0;
    }

    self.uuid = [APLDefaults sharedDefaults].supportedProximityUUIDs[selection];
}

@end
