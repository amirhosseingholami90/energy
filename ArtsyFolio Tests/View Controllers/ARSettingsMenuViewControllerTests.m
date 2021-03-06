#import "ARSettingsMenuViewController.h"
#import "ARStoryboardIdentifiers.h"
#import "ARAppDelegate.h"
#import "ARSettingsSectionButton.h"
#import "ARSettingsMenuViewModel.h"
#import "ARDefaults.h"
#import <Forgeries/ForgeriesUserDefaults+Mocks.h>


@interface ARSettingsMenuViewController ()
- (IBAction)presentationModeButtonPressed:(id)sender;
@end

ARSettingsMenuViewModel *viewModelWithDefaultsAndContext(NSDictionary *defaults, NSManagedObjectContext *context);

SpecBegin(ARSettingsMenuViewController);

__block ARSettingsMenuViewController *subject;
__block UIStoryboard *storyboard;
__block NSManagedObjectContext *context;

beforeAll(^{
    storyboard = [UIStoryboard storyboardWithName:@"ARSettings" bundle:nil];
});

beforeEach(^{
    subject = [storyboard instantiateViewControllerWithIdentifier:SettingsMasterViewController];
    context = [CoreDataManager stubbedManagedObjectContext];
    [Partner createInContext:context];
});

describe(@"visuals", ^{
    itHasSnapshotsForDevices(@"looks right by default", ^{

        /// This should show an enabled presentation mode toggle
        subject.viewModel = viewModelWithDefaultsAndContext(@{ ARPresentationModeOn : @NO }, context);

        UINavigationController *nav = [storyboard instantiateViewControllerWithIdentifier:SettingsPrimaryNavigationController];
        [nav pushViewController:subject animated:NO];

        return nav;
    });

    it(@"looks right after presentation mode is initialized and on", ^{
        subject.viewModel = viewModelWithDefaultsAndContext(@{ ARHasInitializedPresentationMode : @YES,
                                                               ARPresentationModeOn : @YES,
                                                               ARHideWorksNotForSale : @YES },
                                                            context);
        expect(subject).to.haveValidSnapshot();
    });
});

describe(@"toggling presentation mode", ^{

    it(@"posts a grid view filtering notification when turning pres mode on", ^{
        subject.viewModel = viewModelWithDefaultsAndContext(@{ ARHasInitializedPresentationMode : @YES,
                                                               ARPresentationModeOn : @NO,
                                                               ARHideConfidentialNotes : @YES },
                                                            context);

        [subject beginAppearanceTransition:YES animated:NO];
        expect(^{
            [subject presentationModeButtonPressed:nil];
        }).to.notify(ARUserDidChangeGridFilteringSettingsNotification);
    });

    it(@"posts a grid view filtering notification when turning pres mode off", ^{
        subject.viewModel = viewModelWithDefaultsAndContext(@{ ARHasInitializedPresentationMode : @YES,
                                                               ARPresentationModeOn : @YES,
                                                               ARHideWorksNotForSale : @YES },
                                                            context);

        [subject beginAppearanceTransition:YES animated:NO];
        expect(^{
            [subject presentationModeButtonPressed:nil];
        }).to.notify(ARUserDidChangeGridFilteringSettingsNotification);
    });

    it(@"disables toggle when all pres mode settings are off", ^{
        subject.viewModel = viewModelWithDefaultsAndContext(@{ ARHasInitializedPresentationMode : @YES,
                                                               ARPresentationModeOn : @YES },
                                                            context);

        /// Should disable toggle because no presentation mode settings are on
        expect(subject).to.haveValidSnapshot();
    });

    it(@"enables the toggle when any pres mode settings are on", ^{
        subject.viewModel = viewModelWithDefaultsAndContext(@{ ARHasInitializedPresentationMode : @YES,
                                                               ARPresentationModeOn : @NO,
                                                               ARHideArtworkEditButton : @YES },
                                                            context);

        expect(subject).to.haveValidSnapshot();
    });
});

describe(@"showing and hiding the sync recommendation badge", ^{
    it(@"shows the badge when it should recommend a sync", ^{
        subject.viewModel = viewModelWithDefaultsAndContext(@{ ARRecommendSync : @YES }, context);

        expect(subject).to.haveValidSnapshot();
    });

    it(@"hides the badge when sync is up to date", ^{
        subject.viewModel = viewModelWithDefaultsAndContext(@{ ARRecommendSync : @NO }, context);

        expect(subject).to.haveValidSnapshot();
    });
});

SpecEnd

    ARSettingsMenuViewModel *
    viewModelWithDefaultsAndContext(NSDictionary *defaults, NSManagedObjectContext *context)
{
    return [[ARSettingsMenuViewModel alloc] initWithDefaults:(id)[ForgeriesUserDefaults defaults:defaults] context:context appDelegate:[[ARAppDelegate alloc] init]];
}
