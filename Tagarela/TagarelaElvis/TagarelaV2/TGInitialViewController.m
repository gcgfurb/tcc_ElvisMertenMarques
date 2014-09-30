#import "TGInitialViewController.h"
#import "TGPrincipalGameViewController.h"
@interface TGInitialViewController ()

@end

@implementation TGInitialViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)loadUserPicture
{
    [[self userPictureImageView]setImage:[userController loadUserPicture]];
    [[self welcomeLabel]setText:[NSString stringWithFormat:NSLocalizedString(@"labelWelcomeToTagarela", nil), [[userController user]name]]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(showUserPickerScreen) name:@"userNotCreated" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(syncUserContent) name:@"userCreated" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didSelectPlan:) name:@"didSelectPlan" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didSelectTutorFromList:) name:@"didSelectTutorFromList" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didClosePatientChooserScreen)
                                                name:@"didClosePatientChooserScreen" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(reloadData)name:@"reloadData" object:nil];
    
    [self setManagedObjectContext:[(AppDelegate*)[UIApplication sharedApplication].delegate managedObjectContext]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL userRegistered = [defaults boolForKey:@"userRegistered"];
    
    userController = [[TGUserController alloc]init];
    syncUserContent = [[TGSyncUserContentController alloc]init];
        
    if (userRegistered) {
        [self configureInitialTable];
    }
    
    [self customizeViewStyle];
}

- (void)didClosePatientChooserScreen
{
    [self configureInitialTable];
    [[self initialTableView]performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (void)didSelectTutorFromList:(NSNotification*)notification
{
    UIImage *imageToShow;
    NSString *nameToShow;
    User *userSelectedFromList;
    PatientsRelationships *tutorPatientsselectedFromList;
    
    if ([[notification object]isKindOfClass:[User class]]) {
        userSelectedFromList = [notification object];
        imageToShow = [UIImage imageWithData:[userSelectedFromList picture]];
        nameToShow = [userSelectedFromList name];
    } else {
        tutorPatientsselectedFromList = [notification object];
        imageToShow = [UIImage imageWithData:[tutorPatientsselectedFromList patientPicture]];
        nameToShow = [tutorPatientsselectedFromList patientName];
    }
    
    [[self welcomeLabel]setText:[NSString stringWithFormat:NSLocalizedString(@"labelWelcomeToTagarela", nil), nameToShow]];
    [[self userPictureImageView]setImage:imageToShow];
}

- (void)configureInitialTable
{
    [[TGCurrentUserManager sharedCurrentUserManager]setCurrentUser:[userController user]];
    
    initialListViewController = [[TGInitialListViewController alloc]init];
    
    [[self initialTableView]setDelegate:initialListViewController];
    [[self initialTableView]setDataSource:initialListViewController];
    [initialListViewController setTableView:[self initialTableView]];
    
    [self loadUserPicture];
    
    [self customizeViewStyle];        
}

- (void)showPatientPickerScreen
{
    TGPatientPickerViewController *patientPickerViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil]instantiateViewControllerWithIdentifier:@"TGPatientPickerViewController"];        
    [patientPickerViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [[patientPickerViewController view]setFrame:CGRectMake(0, 0, 500, 500)];
    [[KGModal sharedInstance]setShowCloseButton:NO];
    [[KGModal sharedInstance]setTapOutsideToDismiss:NO];
    [[KGModal sharedInstance]showWithContentViewController:patientPickerViewController andAnimated:YES];
}

- (void)syncUnsyncedContent
{
    [syncUserContent syncUnsyncedSymbolsToBackend];
    [syncUserContent syncUnsyncedPlansToBackend];
    [syncUserContent syncUnsyncedSymbolHistoricsToBackend];
    [syncUserContent syncUnsyncedObservationsToBackend];
    
    [SVProgressHUD dismiss];
}

- (void)syncUserContent
{
    [self configureInitialTable];
    
    [self performSelectorOnMainThread:@selector(loadUserPicture) withObject:nil waitUntilDone:NO];
    
    [syncUserContent syncAllData];           
}

- (void)viewDidAppear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL userRegistered = [defaults boolForKey:@"userRegistered"];
    
    [[TGCurrentUserManager sharedCurrentUserManager]setSelectedTutorPatient:nil];
    
    if (!userRegistered) {
        if ([self connectionIsAvailable]) {
            [self askUser];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"alertCaption", nil) message:NSLocalizedString(@"errorMessageFirstConnection", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];            
            [alertView show];            
        }
    } else {
        if ([self connectionIsAvailable]) {
            //[SVProgressHUD showWithStatus:NSLocalizedString(@"waitSyncingUnsynced", nil)];
            [self performSelector:@selector(syncUnsyncedContent) withObject:nil afterDelay:0.5];
            [self configureInitialTable];
            [self syncUserContent];
        } else {
            [self configureInitialTable];
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"alertCaption", nil) message:NSLocalizedString(@"errorMessageConnection", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];            
            [alertView show];
        }
    }
}

- (BOOL)connectionIsAvailable
{
    Reachability *networkReachability = [Reachability reachabilityWithHostName:GOOGLE];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    return (networkStatus == NotReachable) ? NO : YES;
}

- (void)askUser
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"welcomeCaption", nil) message:NSLocalizedString(@"welcomeQuestion", nil) delegate:self cancelButtonTitle:@"Não" otherButtonTitles:@"Sim", nil];
    [alert setTag:999];
    [alert show];    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView tag] == 999) {
        if (buttonIndex == 0) {
            [self showUserPickerScreen];
        } else {
            TGUserAuthenticatorViewController *userAuthenticatiorViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil]instantiateViewControllerWithIdentifier:@"TGUserAuthenticatorViewController"];
            [[userAuthenticatiorViewController view]setFrame:CGRectMake(0, 0, 300, 150)];
            [[KGModal sharedInstance]setShowCloseButton:NO];
            [[KGModal sharedInstance]setTapOutsideToDismiss:NO];
            [[KGModal sharedInstance]showWithContentViewController:userAuthenticatiorViewController andAnimated:YES];
        }        
    }
}

- (void)showUserPickerScreen
{    
    TGUserPickerViewController *userPickerViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil]instantiateViewControllerWithIdentifier:@"TGUserPickerViewController"];
    [[userPickerViewController view]setFrame:CGRectMake(0, 0, 800, 270)];
    [[KGModal sharedInstance]setShowCloseButton:NO];
    [[KGModal sharedInstance]setTapOutsideToDismiss:NO];
    [[KGModal sharedInstance]showWithContentViewController:userPickerViewController andAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)customizeViewStyle
{
    UIColor *color = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ipad-BG-pattern.png"]];
    [[self view]setBackgroundColor:color];        
    [[self initialTableView]setBackgroundColor:[UIColor clearColor]];
    
    switch ([[[TGCurrentUserManager sharedCurrentUserManager]currentUser]type]) {
        case 0:
            [[self addRelationshipButton]setTitle:NSLocalizedString(@"labelTutorRelationship", nil)];
            break;
        case 1:
        case 2:
            [[self addRelationshipButton]setTitle:NSLocalizedString(@"labelPatientRelationship", nil)];
            break;
    }
    
    //[[self bottomToolbar]setBackgroundImage:[UIImage imageNamed:@"ipad-menubar-right@2x.png"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
}

- (void)showSymbolHistoric
{
    TGSymbolHistoricViewController *symbolHistoricViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil]instantiateViewControllerWithIdentifier:@"TGSymbolHistoricViewController"];
    [symbolHistoricViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [[symbolHistoricViewController view]setFrame:CGRectMake(0, 0, 500, 568)];
    [[KGModal sharedInstance]setShowCloseButton:NO];
    [[KGModal sharedInstance]setTapOutsideToDismiss:NO];
    [[KGModal sharedInstance]showWithContentViewController:symbolHistoricViewController andAnimated:YES];
}

- (void)criarSimbolo
{
    TGCategoriesListViewController *categoryListViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil]instantiateViewControllerWithIdentifier:@"TGCategoriesListViewController"];
    [categoryListViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [[categoryListViewController view]setFrame:CGRectMake(0, 0, 540, 270)];
    [[KGModal sharedInstance]setShowCloseButton:NO];
    [[KGModal sharedInstance]setTapOutsideToDismiss:NO];
    [[KGModal sharedInstance]showWithContentViewController:categoryListViewController andAnimated:YES];
}

- (void)showUserHistoric
{
    TGUserHistoricViewController *userHistoricViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil]instantiateViewControllerWithIdentifier:@"TGUserHistoricViewController"];
    [userHistoricViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [[userHistoricViewController view]setFrame:CGRectMake(0, 0, 500, 368)];
    [[KGModal sharedInstance]setShowCloseButton:NO];
    [[KGModal sharedInstance]setTapOutsideToDismiss:NO];
    [[KGModal sharedInstance]showWithContentViewController:userHistoricViewController andAnimated:YES];    
}

- (void)didSelectPlan:(NSNotification*)notification
{
    selectedPlan = [notification object];
    [self performSegueWithIdentifier:@"segueToBoardInteractorScreen" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier]isEqualToString:@"segueToBoardInteractorScreen"]) {
        TGBoardInteractorViewController *boardInteractor = [segue destinationViewController];
        [boardInteractor setSelectedPlan:selectedPlan];        
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch view] == [self view]) {
        return YES;
    }
	return NO;
}

- (IBAction)addPatient:(id)sender
{
    TGPatientChooserViewController *patientChooserViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil]instantiateViewControllerWithIdentifier:@"TGPatientChooserViewController"];
    [patientChooserViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [[patientChooserViewController view]setFrame:CGRectMake(0, 0, 304, 350)];
    [[KGModal sharedInstance]setShowCloseButton:NO];
    [[KGModal sharedInstance]setTapOutsideToDismiss:NO];
    [[KGModal sharedInstance]showWithContentViewController:patientChooserViewController andAnimated:YES];
}

- (IBAction)createSymbol:(id)sender
{
    if ([[[TGCurrentUserManager sharedCurrentUserManager]currentUser]type] == 1){
        if ([[TGCurrentUserManager sharedCurrentUserManager]selectedTutorPatient]) {
            [self criarSimbolo];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"alertCaption", nil) message:NSLocalizedString(@"errorMessageSelectPatientCreateSymbol", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];            
        }
    } else {
        [self criarSimbolo];
    }
}

- (IBAction)createPlan:(id)sender
{    
    if ([[[TGCurrentUserManager sharedCurrentUserManager]currentUser]type] == 1 || [[[TGCurrentUserManager sharedCurrentUserManager]currentUser]type] == 2) {
        if ([[TGCurrentUserManager sharedCurrentUserManager]selectedTutorPatient]) {
            [self performSegueWithIdentifier:@"segueToPlanCreatorBoardViewController" sender:self];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"alertCaption", nil) message:NSLocalizedString(@"errorMessageSelectPatientCreatePlan", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        }
    } else {
        [self performSegueWithIdentifier:@"segueToPlanCreatorBoardViewController" sender:self];
    }
}

- (IBAction)showSymbolHistoric:(id)sender
{
    [self showSymbolHistoric];
}

- (IBAction)showUserObservations:(id)sender
{
    [self showUserHistoric];
}

- (IBAction)showAllSymbols:(id)sender
{    
    [self performSegueWithIdentifier:@"segueToSymbolsListViewController" sender:self];
}


- (void)reloadData
{        
    [initialListViewController loadPatients];
    
    [[self initialTableView]performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];    
}

@end